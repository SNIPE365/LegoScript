#cmdline "-g"
#define __Main "LegoScript"

#include once "windows.bi"
#include once "win\commctrl.bi"
#include once "win\commdlg.bi"
#include once "win\ole2.bi"
#include once "win\Richedit.bi"
#include once "win\uxtheme.bi"
#include once "crt.bi"
#include once "fbthread.bi"

#undef File_Open
#define Errorf(p...)
#define Debugf(p...)

' !!! some pieces have unmatched studs vs clutch (and i suspect that's their design problem) !!!
' !!! because when using ldraw it does not matter the order, so they never enforced that     !!!

'TODO (20/03/25): process keys to toggle filters and to change the text/add type (plate/brick/etc...)
'TODO (05/03/25): fix LS2LDR parsing bugs
'TODO (06/03/25): check bug regarding wheel positioning and the line numbers
'TODO (25/03/25): re-organize the LS2LDR code, so that it looks better and explain better
'TODO (01/04/25): make enable auto-completion menu to work / add shortcut to open graphics window

'the model is no longer updating, say if I remove a part, or all parts, or change something.

'*************** Enumerating our control id's ***********
enum StatusParts
   spStatus
   spCursor
end enum
enum WindowControls
  wcMain
  wcButton
  wcLines
  wcEdit
  wcOutput
  wcStatus
  wcLast
end enum
enum WindowFonts
   wfDefault
   wfEdit
   wfStatus
   wfLast
end enum
enum Accelerators
   acFirst = 9100-1
   acToggleMenu
   'combobox shortcuts
   acFilterClear      , acFilterInvert     , acFilterHidden
   acFilterDonor      , acFilterPath       , acFilterPrinted    , acFilterShortcut 
   acFilterStickered  , acFilterMultiColor , acFilterPreColored , acFilterTemplate 
   acFilterAlias      , acFilterMoulded    , acFilterHelper     , acFilterSticker    
   acFilterDump
end enum

#define CTL(_I) g_tMainCtx.hCtl(_I).hwnd

#include "LSModules\Layout.bas"

type FormContext
  as FormStruct        tForm        'Form structure
  as ControlStruct     hCTL(wcLast) 'controls
  as FontStruct        hFnt(wfLast) 'fonts  
end type

const g_sMainFont  = "verdana" , g_sFixedFont = "consolas"

dim shared as FormContext g_tMainCtx
dim shared as hinstance g_AppInstance  'instance
dim shared as string sAppName        'AppName (window title 'prefix')
dim shared as HMENU g_WndMenu        'Main Menu handle
dim shared as long g_WndWid=640 , g_WndHei=480
dim shared g_hCurMenu as any ptr , g_CurItemID as long , g_CurItemState as long

dim shared as HANDLE g_hResizeEvent
dim shared as hwnd g_GfxHwnd
dim shared as byte g_DoQuit , g_Show3D
dim shared as string g_CurrentFilePath

#define GiveUp(_N) return false

#include "Loader\LoadLDR.bas"
#include "Loader\Include\Colours.bas"
#include "Loader\Modules\Clipboard.bas"
#include "Loader\Modules\InitGL.bas"
#include "Loader\Modules\Math3D.bas"
#include "Loader\Modules\Normals.bas"
#include "Loader\Modules\Matrix.bas"
#include "Loader\Modules\Model.bas"
#include "LS2LDR.bas"
#include "ComboBox.bas"

'******************** Menu Handling Helper Functions **************
namespace Menu 
   function AddSubMenu( hMenu as any ptr , sText as string , iID as long = 0 ) as any ptr
      if IsMenu(hMenu)=0 then return NULL
      var hResult = CreatePopupMenu()
      'AppendMenu( hMenu , MF_POPUP or MF_STRING , cast(UINT_PTR,hResult) , sText )
      dim as MENUITEMINFOA tItem = type( sizeof(MENUITEMINFO) )
      with tItem
         .fMask = MIIM_SUBMENU or MIIM_ID or MIIM_STRING
         .hSubMenu = hResult : .wId = iID
         .dwTypeData = strptr(stext)
      end with
      InsertMenuItemA( hMenu , -1 , true , @tItem )      
      if hMenu=g_WndMenu andalso CTL(wcMain) then DrawMenuBar( CTL(wcMain) )
      return hResult
   end function
   function MenuAddEntry( hMenu as any ptr , iID as long = 0 , sText as string = "" , pEvent as any ptr = 0 , bState as long = 0 ) as long    
      if IsMenu(hMenu)=0 then return -1
      dim as MENUITEMINFOA tItem = type( sizeof(MENUITEMINFO) )    
      tItem.fMask      = MIIM_DATA or MIIM_ID or MIIM_STATE or MIIM_TYPE
      tItem.fType      = iif( len(sText) , iif( bState and MFT_RADIOCHECK , MFT_RADIOCHECK , MFT_STRING ) , MFT_SEPARATOR )
      tItem.fState     = bState and (not MFT_RADIOCHECK)
      tItem.wID        = iID
      tItem.dwItemData = cast(long_ptr,pEvent)
      if len(sText) then tItem.dwTypeData = strptr(sText)
      InsertMenuItemA( hMenu , &hFFFFFFFF , true , @tItem )
      'DrawMenuBar( g_GfxWnd )
      return iID
   end function   
   'MFS_CHECKED , MFS_DEFAULT , MFS_DISABLED , MFS_ENABLED , MFS_GRAYED , MFS_HILITE , MFS_UNCHECKED , MFS_UNHILITE
   function MenuState( hMenu as any ptr , iID as long , bState as long = 0 ) as long
      if IsMenu(hMenu)=0 then return -1
      dim as MENUITEMINFO tItem = type( sizeof(MENUITEMINFO) , MIIM_STATE )      
      tItem.fState = bState
      SetMenuItemInfo( hMenu , iID , false , @tItem )
      return bState
   end function
   function MenuText( hMenu as any ptr , iID as long , sText as string ) as long
      if IsMenu(hMenu)=0 then return -1    
      dim as MENUITEMINFO tItem = type( sizeof(MENUITEMINFO) , MIIM_TYPE )          
      GetMenuItemInfo( hMenu , iID , false , @tItem )    
      tItem.dwTypeData = strptr(sText)
      SetMenuItemInfo( hMenu , iID , false , @tItem )
      return len(sText)
   end function
   sub Trigger( iID as ushort )
      SendMessage(CTL(wcMain),WM_MENUSELECT,iID,cast(LPARAM,g_WndMenu))      
      SendMessage( CTL(wcMain) , WM_COMMAND , iID , 0 )
   end sub
end namespace
'******************************************************************
namespace Viewer
   dim shared as byte g_LoadFile = 0
   dim shared as string g_sGfxFile , g_sFileName
   dim shared as any ptr g_Mutex
   
   function LoadMemory( sContents as string , sName as string = "Unnamed.ls" ) as boolean
      MutexLock( g_Mutex )
         g_sGfxFile = sContents : g_sFileName = sName
         g_LoadFile = 1
      Mutexunlock( g_Mutex )
      return true
   end function      
   function LoadFile( sFile as string ) as boolean
      dim as boolean bLoadResult = FALSE
      MutexLock( g_Mutex )
      do
         g_LoadFile = 0  
         if .LoadFile( sFile , g_sGfxFile )=0 then exit do
         bLoadResult = TRUE : g_sFileName = sFile
         g_LoadFile = 1 : exit do                 
      loop
      Mutexunlock( g_Mutex )
      return bLoadResult
   end function
         
   sub MainThread( hReadyEvent as any ptr )
      
      g_Mutex = MutexCreate()
      dim as long ScrWid,ScrHei : screeninfo ScrWid,ScrHei
      g_GfxHwnd = InitOpenGL(ScrWid,ScrHei)   
      SetWindowPos( g_GfxHwnd , NULL , 0,0 , 400,300 , SWP_NOMOVE or SWP_NOZORDER or SWP_NOACTIVATE )
      ShowWIndow( g_GfxHwnd , SW_HIDE )
      if hReadyEvent then SetEvent( hReadyEvent )
      SetEvent( g_hResizeEvent )
                  
      dim as long iModel=-1,iBorders=-1
      dim as DATFile ptr  pModel
      dim as single xMid,yMid,zMid , g_zFar
      dim as PartSize tSz
      dim as long g_PartCount , g_CurPart = -1
               
      dim as boolean bBoundingBox
      dim as boolean bLeftPressed,bRightPressed,bWheelPressed
      dim as byte bShiftPressed
      dim as long iFps
      dim as single fRotationX = 120 , fRotationY = 20
      dim as single fPositionX , fPositionY , fPositionZ , fZoom = -3
      dim as long iWheel , iPrevWheel
      dim as long g_DrawCount , g_CurDraw = -1
      
      redim as PartCollisionBox atCollision()
                  
      do until g_DoQuit 
                           
         Dim e as fb.EVENT = any
         while (ScreenEvent(@e))
            Select Case e.type
            Case fb.EVENT_MOUSE_MOVE
               if bLeftPressed  then fRotationX += e.dx : fRotationY += e.dy
               if bRightPressed then fPositionX += e.dx*g_zFar/100 : fPositionY += e.dy*g_zFar/100
            case fb.EVENT_MOUSE_WHEEL
               iWheel = e.z-iPrevWheel
               fZoom = -3+(iWheel/12)
            case fb.EVENT_MOUSE_BUTTON_PRESS
               if e.button = fb.BUTTON_MIDDLE then 
                  iPrevWheel = iWheel
                  fZoom = -3
               end if
               if e.button = fb.BUTTON_LEFT   then bLeftPressed  = true
               if e.button = fb.BUTTON_RIGHT  then bRightPressed = true
            case fb.EVENT_MOUSE_BUTTON_RELEASE
               if e.button = fb.BUTTON_LEFT   then bLeftPressed  = false
               if e.button = fb.BUTTON_RIGHT  then bRightPressed = false      
            case fb.EVENT_KEY_PRESS
               select case e.ascii
               case 8
                  if bShiftPressed then
                     g_CurPart = -1
                     printf(!"g_CurPart = %i    \r",g_CurPart)
                     dim as PartSize tSzTemp
                     SizeModel( pModel , tSzTemp , g_CurPart )
                     tSz = tSzTemp
                  else
                     g_CurDraw = -1
                     printf(!"g_CurDraw = %i    \r",g_CurDraw)
                  end if               
               case asc("="),asc("+")
                  if bShiftPressed then
                     g_CurPart = ((g_CurPart+2) mod (g_PartCount+1))-1
                     printf(!"g_CurPart = %i    \r",g_CurPart)
                     dim as PartSize tSzTemp
                     SizeModel( pModel , tSzTemp , g_CurPart )
                     tSz = tSzTemp
                  else
                     g_CurDraw = ((g_CurDraw+2) mod (g_DrawCount+1))-1
                     printf(!"g_CurDraw = %i    \r",g_CurDraw)
                  end if
               case asc("-"),asc("_")
                  if bShiftPressed then
                     g_CurPart = ((g_CurPart+g_PartCount+1) mod (g_PartCount+1))-1
                     printf(!"g_CurPart = %i    \r",g_CurPart)
                     dim as PartSize tSzTemp
                     SizeModel( pModel , tSzTemp , g_CurPart )
                     tSz = tSzTemp
                  else
                     g_CurDraw = ((g_CurDraw+g_DrawCount+1) mod (g_DrawCount+1))-1
                     printf(!"g_CurDraw = %i    \r",g_CurDraw)
                  end if               
               end select
               select case e.scancode
               case fb.SC_LSHIFT : bShiftPressed or= 1
               case fb.SC_RSHIFT : bShiftPressed or= 2
               case fb.SC_TAB   : bBoundingBox = not bBoundingBox
               end select
            case fb.EVENT_KEY_RELEASE
               select case e.scancode
               case fb.SC_LSHIFT : bShiftPressed and= (not 1)
               case fb.SC_RSHIFT : bShiftPressed and= (not 2)
               end select
            case fb.EVENT_WINDOW_CLOSE
               menu.Trigger( 30001 ) 'hide GFX window
            end select
         wend
                     
         while IsWindowVisible( g_GfxHwnd ) = 0
            flip : sleep 10,1
         wend
         flip
         
         static as double dLimitFps
         if abs(timer-dLimitFps) > 1 then dLimitFps = timer
         while (timer-dLimitFps) < 1/30
            sleep 1,1
         wend
         dLimitFps += 1/30
         
         static as double dFps : iFps += 1   
         if abs(timer-dFps)>1 then
            dFps = timer
            WindowTitle("Fps: " & iFps): iFps = 0         
         else
            sleep 1
         end if    
         
         if g_LoadFile then
            MutexLock( g_Mutex )
            do            
               g_LoadFile = 0
               if pModel then 'cleanup previous loaded model/lists (leaking shadow?)
                  FreeModel( pModel )
                  if iModel >=0 then glDeleteLists( iModel , 1 ) : iModel = -1
                  if iBorders >=0 then glDeleteLists( iBorders , 2 ) : iBorders = -1
               end if 
               g_TotalLines = 0 : g_TotalOptis = 0 : g_TotalTrigs = 0 : g_TotalQuads = 0
               static as string sPrevFilename
               pModel = LoadModel( strptr(g_sGfxFile) , g_sFileName )
               g_sGfxFile = "" : if pModel = NULL then exit do 'failed to load
               iModel   = glGenLists( 1 )
               glNewList( iModel ,  GL_COMPILE ) 'GL_COMPILE_AND_EXECUTE
               RenderModel( pModel , false )
               glEndList()
               iBorders = glGenLists( 2 )
               glNewList( iBorders ,  GL_COMPILE )
               RenderModel( pModel , true )
               glEndList()
               glNewList( iBorders+1 ,  GL_COMPILE )
               RenderModel( pModel , true , , -2 )
               glEndList()
               
               var bResetAttributes = sPrevFilename <> g_sFileName
               if bResetAttributes then
                  fZoom = -3 : fRotationX = 120 : fRotationY = 20
                  iWheel = 0 : iPrevWheel = 0 
                  sPrevFilename = g_sFileName
               end if
               
               g_PartCount = 0 : g_DrawCount = pModel->iPartCount
               g_CurPart = -1 : g_CurDraw = -1
               SizeModel( pModel , tSz , , g_PartCount )
               with tSz
                  xMid = (.xMin+.xMax)/2
                  yMid = (.yMin+.yMax)/2
                  zMid = (.zMin+.zMax)/2
                  if abs(xMid-.xMin) > g_zFar then g_zFar = abs(xMid-.xMin)  
                  if abs(yMid-.yMin) > g_zFar then g_zFar = abs(yMid-.yMin)  
                  if abs(zMid-.zMin) > g_zFar then g_zFar = abs(zMid-.zMin)  
                  if abs(xMid-.xMax) > g_zFar then g_zFar = abs(xMid-.xMax)  
                  if abs(yMid-.yMax) > g_zFar then g_zFar = abs(yMid-.yMax)  
                  if abs(zMid-.zMax) > g_zFar then g_zFar = abs(zMid-.zMax)
                  printf(!"X %f > %f (%g ldu)\n",.xMin,.xMax,(.xMax-.xMin))
                  printf(!"Y %f > %f (%g ldu)\n",.yMin,.yMax,(.yMax-.yMin))
                  printf(!"Z %f > %f (%g ldu)\n",.zMin,.zMax,(.zMax-.zMin))
                  printf(!"Lines: %i - Optis: %i - Trigs: %i - Quads: %i - Verts: %i\n", _
                     g_TotalLines , g_TotalOptis , g_TotalTrigs , g_TotalQuads , _
                     g_TotalLines*2+g_TotalOptis*2+g_TotalTrigs*3+g_TotalQuads*4 _
                  )
                  if bResetAttributes then
                     fPositionX = 0 '((.xMin + .xMax)\-2)-.xMin
                     fPositionY = (.yMin + .yMax)\-2
                     fPositionZ = (.zMax-.zMin) 'abs(.zMax)-abs(.zMin)
                     fPositionZ = sqr(fPositionZ)*-40
                  end if
               end with
                              
               CheckCollisionModel( pModel , atCollision() )
               printf(!"Parts: %i , Collisions: %i \n",g_PartCount,ubound(atCollision)\2)
               
               exit do 'loaded fine
               
            loop
            MutexUnlock( g_Mutex )
         end if
         
         're-create base view in case the window got resized
         if WaitForSingleObject( g_hResizeEvent , 0 )=0 then
            dim as RECT tRc : GetClientRect(g_GfxHwnd,@tRc)
            var g_iCliWid = tRc.right , g_iCliHei = tRc.bottom        
            glViewport 0, 0, gfx.g_iCliWid, gfx.g_iCliHei                  '' Reset The Current Viewport
            glMatrixMode GL_PROJECTION                       '' Select The Projection Matrix
            glLoadIdentity                                   '' Reset The Projection Matrix
            gluPerspective 45.0, gfx.g_iCliWid/gfx.g_iCliHei, 1, 100.0*cScale   '' Calculate The Aspect Ratio Of The Window
            glMatrixMode GL_MODELVIEW                        '' Select The Modelview Matrix
         end if
         
         glClear GL_COLOR_BUFFER_BIT OR GL_DEPTH_BUFFER_BIT      
         glLoadIdentity()
         
         if pModel=0 then continue do
         
         glScalef(1/-20, 1.0/-20, 1/20 )
            
         '// Set light position (0, 0, 0)
         dim as GLfloat lightPos(...) = {0,0,0, 1.0f}'; // (x, y, z, w), w=1 for positional light
         glLightfv(GL_LIGHT0, GL_POSITION, @lightPos(0))            
         glTranslatef( -fPositionX , fPositionY , fPositionZ*(fZoom+4) )      
         glRotatef fRotationY , -1.0 , 0.0 , 0
         glRotatef fRotationX , 0   , -1.0 , 0      
         'glPushMatrix()
         glDisable( GL_LIGHTING )
                  
         if g_CurDraw < 0 then
            glCallList(	iModel )   
         else
            RenderModel( pModel , false , , g_CurDraw )      
         end if
         glCallList(	iBorders-(g_CurDraw>=0) )
      
         glEnable( GL_LIGHTING )
         
         #ifdef DebugShadow
            dim as PartSnap tSnap = any
            static as byte bOnce         
            SnapModel( pModel , tSnap , true )      
         #endif
      
         #if 0
            glEnable( GL_POLYGON_STIPPLE )
            
            'SnapModel( pModel , tSnap )
            
            #if 0 
               glPushMatrix()
               glTranslatef( 10 , -2f , 0 ) '/-5)
               glRotatef( 90 , 1,0,0 )
               glScalef( 2 , 2 , (4.0/6.0) ) 'square
               'glScalef( 8f/7f , 8f/7f , (4.0/6.0)*(5f/7f) ) 'cylinder
               glPolygonStipple(	cptr(glbyte ptr,@MaleStipple(0)) )   
               glColor3f( 0 , 1 , 0 )
               'glutSolidSphere( 6 , 18 , 7 ) 'male round (.5,.5,N\2)
               glutSolidCube(6) 'male square (1,1,N)
               glPopMatrix()
            #endif
            #if 0
               glPushMatrix()
               glTranslatef( 10 , -2f , 0 )
               
               glRotatef( 90 , 1,0,0 )
               glRotatef( 45 , 0,0,1 ) 'square
               glScalef( 1 , 1 , 4 )      
               
               glPolygonStipple(	cptr(glbyte ptr,@FeMaleStipple(0)) )
               glColor3f( 1 , 0 , 0 )   
               glutSolidTorus( 0.5 , 6 , 18 , 4  ) 'female "square" (.5,.5,N*8)
               'glutSolidTorus( 0.5 , 6 , 18 , 18 ) 'female round? (.5,.5,N*8)
               glPopMatrix()
            #endif
            
            glDisable( GL_POLYGON_STIPPLE )
         #endif
         
         glDepthMask (GL_FALSE)
         if bBoundingBox then
            glColor4f(0,1,0,.25)
            with tSz
               DrawLimitsCube( .xMin-1,.xMax+1 , .yMin-1,.yMax+1 , .zMin-1,.zMax+1 )      
            end with
         end if
         
         var iCollisions = ubound(atCollision)
         if iCollisions andalso instr(g_sFileName,".dat")=0 then
            glEnable( GL_POLYGON_STIPPLE )      
            static as ulong aStipple(32-1)
            dim as long iMove = (timer*8) and 7
            for iY as long = 0 to 31         
               var iN = iif(iY and 1,&h1414141414141414ll,&h4141414141414141ll)         
               aStipple(iY) = iN shr ((iY+iMove) and 7)
            next iY
            glPolygonStipple(	cptr(glbyte ptr,@aStipple(0)) )
            if (iMove and 2) then glColor4f(1,0,0,1) else glColor4f(0,0,0,1)
            for I as long = 0 to iCollisions-1   
               with atCollision(I)
                  DrawLimitsCube( .xMin-1,.xMax+1 , .yMin-1,.yMax+1 , .zMin-1,.zMax+1 )
               end with
            next I
            glDisable( GL_POLYGON_STIPPLE )      
         end if
         glDepthMask (GL_TRUE)
         
         'glPopMatrix()
         
      loop
      
      mutexdestroy( g_Mutex )
      
   end sub
end namespace

sub NotifySelChange( iID as long )
   var hCTL = CTL( iID ), hParent = GetParent(hCTL)
   dim as SELCHANGE tSelChange           
   SendMessage( hCTL , EM_EXGETSEL , 0 , cast(LPARAM,@tSelChange.chrg) )
   tSelChange.seltyp = SendMessage( hCTL , EM_SELECTIONTYPE   , 0 , 0 )   
   with tSelChange.nmhdr
      .hwndFrom = hCTL : .idFrom = iID : .code = EN_SELCHANGE
   end with
   SendMessage( hParent , WM_NOTIFY , iID , cast(LPARAM,@tSelChange) )   
end sub
function LoadFileIntoEditor( sFile as string ) as boolean
   var f = freefile()
   if open(sFile for input as #f) then
      MessageBox( CTL(wcMain) , !"Failed to open:\n\n'"+sFile+"'" , NULL , MB_ICONERROR )
      return false
   end if
   dim as string sLine,sScript
   while not eof(f)
      line input #f, sLine : sScript += sLine+!"\r\n"
   wend
   close #f
   SetWindowText( CTL(wcEdit) , sScript ) 
   sLine="":sScript=""
   g_CurrentFilePath = sFile
   SetWindowText( CTL(wcMain) , sAppName + " - " + sFile )
   NotifySelChange( wcEdit )
   SetFocus( CTL(wcButton) )
   return true
end function

declare sub File_SaveAs()
'**************** Main Menu Layout **************
sub File_New()
   if GetWindowTextLength( CTL(wcEdit) ) then
      #define sMsg !"All unsaved data will be lost, continue?"
      if MessageBox( CTL(wcMain) , sMsg , "File->New" , MB_ICONQUESTION or MB_YESNO ) <> IDYES then exit sub
   end if
   SetWindowText( CTL(wcEdit) , "" )
   SetWindowText( CTL(wcMain) , sAppName + " - Unnamed")
   NotifySelChange( wcEdit )
   SetFocus( CTL(wcEdit) )
end sub
sub File_Open()
   
   if GetWindowTextLength( CTL(wcEdit) ) then
      #define sMsg !"All unsaved data will be lost, continue?"
      if MessageBox( CTL(wcMain) , sMsg , "File->Open" , MB_ICONQUESTION or MB_YESNO ) <> IDYES then exit sub
   end if
   
   dim as OPENFILENAME tOpen
   dim as zstring*32768 zFile = any : zFile[0]=0
   with tOpen
      .lStructSize = sizeof(tOpen)
      .hwndOwner = CTL(wcMain)
      .lpstrFilter = @!"LegoScript Files\0*.ls\0All Files\0*.*\0\0"
      .nFilterIndex = 0 '.ls
      .lpstrFile = @zFile
      .nMaxFile = 32767
      .lpstrInitialDir = NULL
      .lpstrTitle = NULL
      .lpstrDefExt = @"ls"
      .Flags = OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_NOCHANGEDIR
      if GetOpenFileName( @tOpen ) = 0 then exit sub      
      print "["+*.lpstrFile+"]"
      LoadFileIntoEditor( *.lpstrFile )
   end with
end sub
sub File_Save()
   if GetFileAttributes(g_CurrentFilePath)=&hFFFFFFFF then
      File_SaveAs() : exit sub
   end if
   var iMaxLen = GetWindowTextLength( CTL(wcEdit) )
   var sScript = space(iMaxLen)
   if GetWindowText( CTL(wcEdit) , strptr(sScript) , iMaxLen+1 )<>iMaxLen then 
      puts("Failed to retrieve text content...")
      exit sub  
   end if
   'print iMaxLen
   'print sScript
   var f = freefile()
   if open(g_CurrentFilePath for output as #f) then
      MessageBox( CTL(wcMain) , !"Failed to save:\n\n'"+g_CurrentFilePath+"'" , NULL , MB_ICONERROR )
      exit sub
   end if
   print #f, sScript;
   close #f
end sub
sub File_SaveAs()
   dim as OPENFILENAME tOpen
   dim as zstring*32768 zFile = any : zFile[0]=0
   with tOpen
      .lStructSize = sizeof(tOpen)
      .hwndOwner = CTL(wcMain)
      .lpstrFilter = @!"LegoScript Files\0*.ls\0All Files\0*.*\0\0"
      .nFilterIndex = 0 '.ls
      .lpstrFile = @zFile
      .nMaxFile = 32767
      .lpstrInitialDir = NULL
      .lpstrTitle = NULL
      .Flags = OFN_PATHMUSTEXIST 'or OFN_NOCHANGEDIR
      .lpstrDefExt = @"ls"
      if GetSaveFileName( @tOpen ) = 0 then exit sub      
      print "["+*.lpstrFile+"]"
      var f = freefile()
      if open(*.lpstrFile for output as #f) then
         MessageBox( CTL(wcMain) , !"Failed to save:\n\n'"+*.lpstrFile+"'" , NULL , MB_ICONERROR )
         exit sub
      end if
      close #f
      g_CurrentFilePath = *.lpstrFile
      File_Save()      
   end with
end sub
sub File_Exit()
   SendMessage( CTL(wcMain) , WM_CLOSE , 0,0 )
end sub
sub Edit_Undo()
   puts(__FUNCTION__)
end sub
sub Edit_Copy()
   puts(__FUNCTION__)
end sub
sub Completion_Enable()
   puts(__FUNCTION__)
   var iToggledState = g_CurItemState xor MFS_CHECKED
   Menu.MenuState( g_hCurMenu,g_CurItemID,iToggledState )   
   EnableMenuItem( g_hCurMenu , 32000 , iif( iToggledState and MFS_CHECKED , MF_ENABLED , MF_GRAYED ) )
end sub
sub Completion_ClearFilters()
   puts(__FUNCTION__)
   g_FilterFlags = 0
   for N as long = acFilterHidden to acFilterSticker
      Menu.MenuState( g_hCurMenu , N-acFilterHidden+32003 , g_CurItemState )
   next N
end sub
'#define Completion_InvertFilters Completion_Toggle
sub Completion_InvertFilters()
   puts(__FUNCTION__)
   for N as long = acFilterHidden to acFilterSticker
      Menu.Trigger( N-acFilterHidden+32003 )
   next N
end sub
sub Completion_Toggle()
   var iAccelID = acFilterClear+(g_CurItemID-32001)
   var iToggledState = g_CurItemState xor MFS_CHECKED
   Menu.MenuState( g_hCurMenu,g_CurItemID,iToggledState )   
   #define ChgFilter( _Name ) g_FilterFlags = iif( iToggledState and MFS_CHECKED , g_FilterFlags or _Name , g_FilterFlags and (not (_Name)) )
   select case iAccelID '32001 = Completion.Filters.Clear
   case acFilterHidden      : ChgFilter( wIsHidden )   
   case acFilterDonor       : ChgFilter( wIsDonor )
   case acFilterPath        : ChgFilter( wIsPath )
   case acFilterPrinted     : ChgFilter( wIsPrinted )
   case acFilterShortcut    : ChgFilter( wIsShortcut )
   case acFilterStickered   : ChgFilter( wIsStickered )
   case acFilterMultiColor  : ChgFilter( wIsMultiColor )
   case acFilterPreColored  : ChgFilter( wIsPreColored )
   case acFilterTemplate    : ChgFilter( wIsTemplate )
   case acFilterAlias       : ChgFilter( wIsAlias )    
   case acFilterMoulded     : ChgFilter( wIsMoulded )
   case acFilterHelper      : ChgFilter( wIsHelper )
   case acFilterSticker     : ChgFilter( wIsSticker )
   end select
end sub
sub View_ToggleGW()
   var iToggledState = g_CurItemState xor MFS_CHECKED
   g_Show3D = (iToggledState and MFS_CHECKED)<>0
   if g_GfxHwnd then ShowWindow( g_GfxHwnd , iif( g_Show3D , SW_SHOWNA , SW_HIDE ) )
   Menu.MenuState( g_hCurMenu,g_CurItemID, iToggledState )
   for N as long = 40002 to 40008 'View.xxxx
      EnableMenuItem( g_hCurMenu , N , iif( iToggledState and MFS_CHECKED , MF_ENABLED , MF_GRAYED ) )
   next N
end sub
sub View_Key()
   if IsWindow(g_GfxHwnd)=0 then exit sub
   dim vk as long , sft as byte
   select case g_CurItemID
   case 40002 : vk = VK_BACK     'Backspace
   case 40003 : vk = VK_ADD      '+
   case 40004 : vk = VK_SUBTRACT '-
   case 40006 : vk = VK_BACK     : sft = 1 'Shift BACKSPACE
   case 40007 : vk = VK_ADD      : sft = 1 'Shift +
   case 40008 : vk = VK_SUBTRACT : sft = 1 'Shift -
   case else  : puts("bad View_key"): exit sub
   end select
   'var scShift =  (MapVirtualKey( VK_SHIFT , 0 ) shl 16)+1
   if sft then SendMessage( g_GfxHwnd , WM_KEYDOWN , VK_SHIFT , 0 ) 'scShift )
   SendMessage( g_GfxHwnd , WM_KEYDOWN , vk , 0 )   
   SendMessage( g_GfxHwnd , WM_KEYUP  , vk , 0 )
   if sft then SendMessage( g_GfxHwnd , WM_KEYUP   , VK_SHIFT , 0 ) 'scShift )
end sub
sub View_Toggle()
   if IsWindow(g_GfxHwnd)=0 then exit sub
   ' 40005
   var iToggledState = g_CurItemState xor MFS_CHECKED
   Menu.MenuState( g_hCurMenu,g_CurItemID,iToggledState )   
   SendMessage( g_GfxHwnd , WM_KEYDOWN , VK_TAB , 0 )   
   SendMessage( g_GfxHwnd , WM_KEYUP   , VK_TAB , 0 )
end sub
sub Help_About()
   puts(__FUNCTION__)
end sub
function CreateMainMenu() as HMENU
   
   #macro _SubMenu( _sText... ) 
   scope
      var hMenu = Menu.AddSubMenu( hMenu , _sText )
   #endmacro
   #define _EndSubMenu() end scope
   #define _Entry( _Parms... ) Menu.MenuAddEntry( hMenu , _Parms )
         
   var hMenu = CreateMenu() : g_WndMenu = hMenu
   _SubMenu( "&File" )
     _Entry( 10001 , "New"                              , @File_New    )
     _Entry( 10002 , "Open"                             , @File_Open   )     
     _Entry( 10003 , "Save"                             , @File_Save   )
     _Entry( 10004 , "Save As"                          , @File_SaveAs )
     _Entry()
     _Entry( 10005 , "Quit"                !"\tAlt+F4"  , @File_Exit   )
   _EndSubMenu()   
   _SubMenu( "&Edit" )      
      _Entry( 20001 , "&Undo"              !"\tCtrl+Z" , @Edit_Undo ) ' , MFT_RADIOCHECK or MFS_CHECKED )
      _Entry( 20002 , "&Copy"              !"\tCtrl+C" , @Edit_Copy ) ', MFT_RADIOCHECK )
   _EndSubMenu()
   _SubMenu( "&Completion" )
      _Entry( 30001 , "&Enable" , @Completion_Enable )         
      _SubMenu( "&Filters" , 32000 )
         _Entry( 32001 , "C&lear"          !"\tCtrl+Shift+C", @Completion_ClearFilters )
         _Entry( 32002 , "&Invert"         !"\tCtrl+I"      , @Completion_InvertFilters )
         _Entry()
         _Entry( 32003 , "&Variations"     !"\tAlt+Shift+F" , @Completion_Toggle )
         _Entry( 32004 , "&Donor"          !"\tAlt+D"       , @Completion_Toggle )
         _Entry( 32005 , "&Path"           !"\tAlt+P"       , @Completion_Toggle )
         _Entry( 32006 , "P&rinted"        !"\tShift+Alt+P" , @Completion_Toggle )
         _Entry( 32007 , "Shortcut"        !"\tAlt+S"       , @Completion_Toggle )
         _Entry( 32008 , "Stic&kered"      !"\tAlt+K"       , @Completion_Toggle )
         _Entry( 32009 , "Multi&color"     !"\tAlt+M"       , @Completion_Toggle )
         _Entry( 32010 , "Pre-c&olored"    !"\tShift+Alt+C" , @Completion_Toggle )
         _Entry( 32011 , "&Template"       !"\tAlt+T"       , @Completion_Toggle )
         _Entry( 32012 , "&Alias"          !"\tAlt+A"       , @Completion_Toggle )
         _Entry( 32013 , "&Moulded"        !"\tAlt+Shift+M" , @Completion_Toggle )
         _Entry( 32014 , "&Helper"         !"\tAlt+Shift+H" , @Completion_Toggle )
         _Entry( 32015 , "&Stickers"       !"\tAlt+S"       , @Completion_Toggle )
      _EndSubMenu()            
   _EndSubMenu()
   _SubMenu( "&View" )
      _Entry( 40001 , "&Graphics Window"    !"\tCtrl+G"   , @View_ToggleGW ) ' , MFT_RADIOCHECK or MFS_CHECKED )      
      _Entry()
      _Entry( 40002 , "Reset View parts"    !"\tBACKSPACE", @View_Key      , MFS_GRAYED )
      _Entry( 40003 , "View &Next part"     !"\t+"        , @View_Key      , MFS_GRAYED )
      _Entry( 40004 , "View &Previous part" !"\t-"        , @View_Key      , MFS_GRAYED )
      _Entry()      
      _Entry( 40005 , "&Show bounding box"  !"\tTAB"      , @View_Toggle   , MFS_GRAYED )
      _Entry( 40006 , "Reset bounding box"  !"\tShift BACKSPACE", @View_Key, MFS_GRAYED )
      _Entry( 40007 , "Ne&xt part"          !"\tShift +"  , @View_Key      , MFS_GRAYED )
      _Entry( 40008 , "&Pre&vious part"     !"\tShift -"  , @View_Key      , MFS_GRAYED )
   _EndSubMenu()
   _SubMenu( "&Help" )          
      _Entry( 50001 , "About" , @Help_About )
   _EndSubMenu()
   return hMenu
end function

sub Button_Compile()
   SetWindowText( CTL(wcStatus) , "Building..." )   
   var iMaxLen = GetWindowTextLength( CTL(wcEdit) )
   var sScript = space(iMaxLen)
   if GetWindowText( CTL(wcEdit) , strptr(sScript) , iMaxLen+1 )<>iMaxLen then 
      puts("Failed to retrieve text content...")
      SetWindowText( CTL(wcStatus) , "Build failed." )
      exit sub  
   end if
   dim as string sOutput, sError
   sOutput = LegoScriptToLDraw( sScript , sError )   
   SetWindowText( CTL(wcOutput) , iif(len(sError)=0,sOutput,sError) )
   
   if len(sOutput) then
      if lcase(right(g_CurrentFilePath,3)) = ".ls" then
         Viewer.LoadMemory( sOutput , left(g_CurrentFilePath,len(g_CurrentFilePath)-3)+".ldr" )
      else
         Viewer.LoadMemory( sOutput , g_CurrentFilePath+".ldr" )
      end if
   end if
   SetWindowText( CTL(wcStatus) , iif(len(sOutput),"Ready.","Script error.") )
   
end sub

static shared as long g_iPrevTopRow = 0 , g_iPrevRowCount = 0 , g_RowDigits = 2
static shared as zstring*128 g_zRows
static shared as SearchQueryContext g_SQCtx
sub Lines_Draw( hEdit as HWND , tDraw as DRAWITEMSTRUCT )   
   with tDraw      
      dim PT as POINT = any
      var iCharIdx = Sendmessage( hEdit , EM_LINEINDEX  , g_iPrevTopRow , 0 )
      var iResu = SendMessage( hEdit , EM_POSFROMCHAR , cast(WPARAM,@PT) , iCharIdx )
      'printf(!"%i/%i[%i]\n",iResu,iCharIdx,PT.Y)
      SetTextColor( .hdc , GetSysColor(COLOR_GRAYTEXT) )
      FillRect( .hdc , @.rcItem , cast(HBRUSH,GetSysColorBrush(COLOR_BTNFACE)) )
      .rcItem.top += PT.Y+2 : .rcItem.right -= 4 : .rcItem.bottom -= (4+GetSystemMetrics(SM_CYHSCROLL))
      DrawText( .hDC , g_zRows , -1 , @.rcItem , DT_RIGHT or DT_NOPREFIX )
      'SetTextAlign( .hdc , TA_RIGHT )
      'ExtTextOut( .hDC , .rcItem.right , .rcItem.top , ETO_CLIPPED or ETO_OPAQUE , @.rcItem , g_zRows , len(g_zRows) , NULL )
   end with
end sub
sub RichEdit_TopRowChange( hCtl as HWND )
   var iTopRow = SendMessage( hCTL , EM_GETFIRSTVISIBLELINE , 0,0 )
   var iRows = SendMessage( hCTL , EM_GETLINECOUNT , 0,0 )
   if g_iPrevRowCount <> iRows then
      var iRowDigits = 2
      if iRows > 99 then iRowDigits += 1
      if iRows > 999 then iRowDigits += 1
      if iRows > 9999 then iRowDigits += 1
      if iRows > 99999 then iRowDigits += 1
      if iRowDigits <> g_RowDigits then
         g_RowDigits = iRowDigits
         PostMessage( CTL(wcMain) , WM_USER+3 , 0 , 0 )
      end if
   end if
   if g_iPrevTopRow <> iTopRow orelse g_iPrevRowCount <> iRows then
      g_iPrevTopRow = iTopRow : g_iPrevRowCount = iRows
      var pzRows = @g_zRows      
      for N as long = 1 to iif(iRows<15,iRows,15)
         pzRows += sprintf(pzRows,!"%i\r\n",iTopRow+N)
      next N      
      InvalidateRect( CTL(wcLines) , NULL , FALSE )
      'SetWindowText( CTL(wcLines) , zRows )      
   end if
end sub
sub RichEdit_SelChange( hCtl as HWND , iRow as long , iCol as long )   
   #define zRow t.zRow_      
   type tBuffer
      union
         wSize as ushort
         zRow_ as zstring*1024
      end union
   end type
   dim t as tBuffer = any : t.wSize = 1023
   var iSz = SendMessage( hCtl , EM_GETLINE , iRow , cast(LRESULT,@t) )
   if iSz < 0 orelse iSz > 1023 then exit sub   
   var iWid = 80 : zRow[iSz-2]=0   
   'printf( !"%i:%s\r",iSz,left(zRow+space(iWid-6),iWid-5) )   
   with g_SQCtx
      if ubound(.sTokenTxt) < 0 then redim .sTokenTxt(.iMaxTok-1)      
      .bChanged = 1 : .iCur = iCol 'instr( iCol+1 , zRow , " " )-1
      'if .iCur < 0 then .iCur = iSz-2
   end with
   dim as string sRow = zRow
   HandleTokens( sRow , g_SQCtx )
end sub
sub ProcessAccelerator( iID as long )
   select case iID
   case acToggleMenu
      SetMenu( CTL(wcMain) , iif( GetMenu(CTL(wcMain)) , NULL , g_WndMenu ) )
   case acFilterClear to acFilterSticker                 '--- combobox accelerators ---
      Menu.Trigger( 32001+iID-acFilterClear )
   case acFilterDump        : puts("Dump filter parts")  '--- debug accelerators ---
   end select
end sub
function CreateMainAccelerators() as HACCEL
   static as ACCEL AccelList(...) = { _
      ( FSHIFT or FVIRTKEY , VK_SPACE , acToggleMenu ), _
      _ 'accelerators for combobox
      ( FCONTROL or FSHIFT or FVIRTKEY , VK_C , acFilterClear ), _
      ( FCONTROL or FVIRTKEY           , VK_I , acFilterInvert ), _
      ( FALT or FSHIFT or FVIRTKEY     , VK_F , acFilterHidden ), _
      ( FALT or FVIRTKEY               , VK_D , acFilterDonor ), _
      ( FALT or FVIRTKEY               , VK_P , acFilterPath ), _
      ( FALT or FSHIFT or FVIRTKEY     , VK_P , acFilterPrinted ), _
      ( FALT or FVIRTKEY               , VK_S , acFilterShortcut ), _
      ( FALT or FVIRTKEY               , VK_K , acFilterStickered ), _      
      ( FALT or FVIRTKEY               , VK_M , acFilterMultiColor ), _
      ( FALT or FSHIFT or FVIRTKEY     , VK_C , acFilterPreColored ), _      
      ( FALT or FVIRTKEY               , VK_T , acFilterTemplate ), _
      ( FALT or FVIRTKEY               , VK_A , acFilterAlias ), _
      ( FALT or FSHIFT or FVIRTKEY     , VK_M , acFilterMoulded ), _
      ( FALT or FSHIFT or FVIRTKEY     , VK_H , acFilterHelper ), _      
      ( FCONTROL or FSHIFT or FVIRTKEY , VK_S , acFilterSticker ), _      
      ( FCONTROL or FVIRTKEY           , VK_D , acFilterDump )  _
   }
   return CreateAcceleratorTable( @AccelList(0) , ubound(AccelList)+1 )
end function

sub DockGfxWindow()   
   dim as RECT RcWnd=any,RcGfx=any,RcCli=any,RcDesk
   GetWindowRect( GetDesktopWindow() , @RcDesk )
   GetWindowRect( g_GfxHwnd , @RcGfx )
   GetWindowRect( CTL(wcMain) ,@RcWnd )   
   var iYPos = RcWnd.top+((RcWnd.bottom-RcWnd.Top)-(RcGfx.bottom-RcGfx.top))\2   
   GetClientRect( CTL(wcMain) ,@RcCli )
   dim as POINT tPtRight = type(RcCli.Right-3,0)
   ClientToScreen( CTL(wcMain) , @tPtRight )   
   var hPlace = HWND_TOP
   if tPtRight.x >= (RcDesk.right-8) then 
      hPlace = HWND_TOPMOST : tPtRight.x -= (RcGfx.right - RcGfx.left)
   end if
   'gfx.tOldPt.x = -65537
   SetWindowPos( g_GfxHwnd , hPlace , tPtRight.x-4 ,iYPos , 0,0 , SWP_NOSIZE or SWP_NOACTIVATE )
   NotifySelChange( wcEdit )
end sub   
sub ResizeMainWindow( bCenter as boolean = false )         
   'Calculate Client Area Size
   dim as RECT RcWnd=any,RcCli=any,RcDesk=any
   var hWnd = CTL(wcMain)
   GetClientRect(hWnd,@RcCli)      
   if bCenter then 'initial position
      GetWindowRect(hWnd,@RcWnd)
      'Window Rect is in SCREEN coordinate.... make right/bottom become WID/HEI
      with RcWnd
         .right  -= .left : .bottom -= .top              'get window size
         .right -= RcCli.right : .bottom -= RcCli.bottom 'make it be difference from wnd/client
         .right += g_WndWid : .bottom += g_WndHei        'add back desired client area size
         GetClientRect(GetDesktopWindow(),@RcDesk)
         
         dim as RECT RcGfx=any : GetWindowRect( g_GfxHwnd , @RcGfx )         
         var iAllWid = .right , iGfxHei = RcGfx.bottom-RcGfx.top
         if iGfxHei > .bottom then .bottom = iGfxHei
         iAllWid = .right + RcGfx.right-RcGfx.left         
         var iCenterX = (RcDesk.right-iAllWid)\2 , iCenterY = (RcDesk.bottom-.bottom)\2        
         SetWindowPos(hwnd,null,iCenterX,iCenterY,.right,.bottom,SWP_NOZORDER)
         RcCli.right = g_WndWid : RcCli.bottom = g_WndHei
      end with 
   end if
      
   'recalculate control sizes based on window size
   ResizeLayout( hWnd , g_tMainCtx.tForm , RcCli.right , RcCli.bottom )
   MoveWindow( CTL(wcStatus) ,0,0 , 0,0 , TRUE )
   dim as long aWidths(2-1) = {RcCli.right*.85,-1}
   SendMessage( CTL(wcStatus) , SB_SETPARTS , 2 , cast(LPARAM,@aWidths(0)) )
   DockGfxWindow()   
   
   
end sub

static shared as any ptr OrgEditProc
function WndProcEdit ( hWnd as HWND, message as UINT, wParam as WPARAM, lParam as LPARAM ) as LRESULT
   select case message
   case WM_CHAR
      select case wParam
      case 3,24 'Ctrl-C / Ctrl-X
         var lResu = CallWindowProc( OrgEditProc , hWnd , message , wParam, lParam )      
         GetClipboard() : return lResu
      end select      
   case WM_VSCROLL
      var iResu = CallWindowProc( OrgEditProc , hWnd , message , wParam, lParam )
      g_iPrevRowCount = 0
      RichEdit_TopRowChange( hWnd )
      return iResu   
   end select
   return CallWindowProc( OrgEditProc , hWnd , message , wParam, lParam )   
end function

' *************** Procedure Function ****************
function WndProc ( hWnd as HWND, message as UINT, wParam as WPARAM, lParam as LPARAM ) as LRESULT
   
   var pCtx = (@g_tMainCtx)      
   #include "LSModules\Controls.bas"
   #include "LSModules\ControlsMacros.bas"
   
   select case( message )       
   case WM_DRAWITEM
      var wID = clng(wParam) , ptDrw = cast(LPDRAWITEMSTRUCT,lparam)
      select case wId
      case wcLines : Lines_Draw( CTL(wcEdit) , *ptDrw )
      end select
   case WM_CREATE 'Window was created
                  
      if CTL(wcMain) then return 0
      _InitForm()
      
      var hEventGfxReady = CreateEvent( NULL , FALSE , FALSE , NULL )    
      g_hResizeEvent = CreateEvent( NULL , FALSE , FALSE , NULL )
      ThreadDetach( ThreadCreate( @Viewer.MainThread , hEventGfxReady ) )
      
      InitFont( wfDefault , g_sMainFont   , 12 ) 'default application font
      InitFont( wfStatus  , g_sMainFont  , 10 )  'status bar font
      InitFont( wfEdit    , g_sFixedFont  , 16 ) 'edit controls font
                  
      AddButtonA( wcButton , cMarginL , cMarginT , _pct(15) , cRow(1.25)  , "Build" )
      AddTextA  ( wcLines  , cMarginL , _NextRow , _pct(1.66*2) , _pct(53) ,  "" , SS_OWNERDRAW )
      AddRichA  ( wcEdit   , _NextCol0, _SameRow , cMarginR , _pct(53) , "" , WS_HSCROLL or WS_VSCROLL or ES_AUTOHSCROLL or ES_DISABLENOSCROLL  )
      AddRichA  ( wcOutput , cMarginL , _NextRow , cMarginR , _BottomP(-5) , "" , WS_HSCROLL or WS_VSCROLL or ES_AUTOHSCROLL or ES_READONLY )
      AddStatusA( wcStatus , "Ready." )
                  
      SetControlsFont( wfEdit   , wcLines , wcEdit , wcOutput )
      SetControlsFont( wfStatus , wcStatus )
      
      SetWindowTheme( CTL(wcEdit) , "" , "" )
      SendMessage( CTL(wcEdit) , EM_EXLIMITTEXT , 0 , 16*1024*1024 ) '16mb text limit
      SendMessage( CTL(wcEdit) , EM_SETEVENTMASK , 0 , ENM_SELCHANGE or ENM_KEYEVENTS or ENM_SCROLL )
      OrgEditProc = cast(any ptr,SetWindowLongPtr( CTL(wcEdit) , GWLP_WNDPROC , cast(LONG_PTR,@WndProcEdit) ))
                          
      WaitForSingleObject( hEventGfxReady , INFINITE )    
      CloseHandle( hEventGfxReady )
      if g_GfxHwnd = 0 then return -1 'failed
      
      InitSearchWindow()
      Menu.Trigger( 30001 ) 'Completion.Enable
      'Menu.Trigger( 32003 ) 'Completion.Enable.Variations
      
      'SetWindowPos( g_hContainer , 0 , 0,0,100,100 , SWP_NOZORDER or SWP_SHOWWINDOW or SWP_NOMOVE )
      'ShowWindow( g_hContainer , SW_SHOW )
      ResizeMainWindow( true )    
      File_New()    
      'LoadFileIntoEditor( exePath+"\sample.ls" )
      SetForegroundWindow( ctl(wcMain) )
      SetFocus( ctl(wcEdit) )
      return 0
          
   case WM_MENUSELECT 'track newest menu handle/item/state
      var iID = cuint(LOWORD(wParam)) , fuFlags = cuint(HIWORD(wParam)) , hMenu = cast(HMENU,lParam) 
      if hMenu then g_CurItemID = iID : g_hCurMenu = hMenu            
      return 0
   case WM_NOTIFY
      var wID = cast(long,wParam) , pnmh = cptr(LPNMHDR,lParam)
      select case wID
      case wcEdit
         select case pnmh->code
         case EN_SELCHANGE
            with *cptr(SELCHANGE ptr,lParam)
               'static as CHARRANGE tPrev = type(-1,-1)
               var iRow = SendMessage( CTL(wID) , EM_EXLINEFROMCHAR , 0 , .chrg.cpMax )
               var iCol = .chrg.cpMax - SendMessage( CTL(wID) , EM_LINEINDEX  , iRow , 0 )               
               dim as zstring*64 zPart = any : sprintf(zPart,"%i : %i",iRow+1,iCol+1)
               'printf(!"(%s) > %i to %i    \r",,,.chrg.cpMin,.chrg.cpMax)
               SendMessage( CTL(wcStatus) , SB_SETTEXT , spCursor , cast(LPARAM,@zPart) ) 
               RichEdit_TopRowChange( CTL(wID) )
               RichEdit_SelChange( CTL(wID) , iRow , iCol )
            end with
         end select
      end select
      return 0
   case WM_COMMAND 'Event happened to a control (child window)
      var wNotifyCode = cint(HIWORD(wParam)), wID = LOWORD(wParam) , hwndCtl = cast(.HWND,lParam)      
      if hwndCtl=0 andalso wNotifyCode=0 then wNotifyCode = -1      
      select case wNotifyCode
      case -1         'Command from Menu
         if wID <> g_CurItemID then return 0 'not valid menu event
         dim as MENUITEMINFO tItem = type( sizeof(MENUITEMINFO) , MIIM_DATA or MIIM_STATE )  
         GetMenuItemInfo( g_hCurMenu , wID , false , @tItem )
         g_CurItemState = tItem.fState
         if tItem.dwItemData then
           dim MenuItemCallback as sub () = cast(any ptr,tItem.dwItemData)
           MenuItemCallback()        
         end if
         g_CurItemID = 0 : g_hCurMenu = 0
      case  1         'Accelerator
         ProcessAccelerator( wID )
      case else
         select case wID                  
         case wcEdit
            select case wNotifyCode
            case EN_SETFOCUS               
               ShowWindow( g_hContainer , g_SearchVis   )               
            case EN_KILLFOCUS
               if GetForegroundWindow() <> g_hContainer then 
                  ShowWindow( g_hContainer , SW_HIDE )
               end if
            case EN_VSCROLL
               RichEdit_TopRowChange( hwndCtl )
            end select
         case wcButton
            select case wNotifyCode
            case BN_CLICKED
               Button_Compile()            
            end select
         end select
      end select      
      
      return 0
    
   case WM_SIZE      
      ResizeMainWindow()
      return 0
   case WM_MOVE
      DockGfxWindow()
   case WM_USER+1 'gfx resized
      SetEvent(g_hResizeEvent)
      DockGfxWindow()
   case WM_USER+2 'gfx moved
      DockGfxWindow()
   case WM_USER+3 'Resize Number border
      SetControl( wcLines , cMarginL , _BtP(wcButton,0.5) , _pct((.18+1.52*g_RowDigits)) , _pct(53) , CTL(wcLines) )
      ResizeMainWindow()      
   case WM_ACTIVATE  'Activated/Deactivated
      if g_GfxHwnd andalso g_Show3D then
         var fActive = LOWORD(wParam) , fMinimized = HIWORD(wParam) , hwndPrevious = cast(HWND,lParam)
         if fActive then
            ShowWindow( g_GfxHwnd , SW_SHOWNA )            
            DockGfxWindow()
         else
            if fMinimized then                              
               ShowWindow( g_GfxHwnd , SW_HIDE )
            else
               SetWindowPos( g_GfxHwnd , HWND_NOTOPMOST , 0,0 , 0,0 , SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE )
            end if
         end if
      end if
   #if 0
   case WM_ACTIVATEAPP
      var fActive = wParam
      'if GetForegroundWindow() <> g_hContainer then fActive = (GetFocus = CTL(wcEdit))
      if fActive then
         ShowWindow( g_hContainer , g_SearchVis   )
      else
         ShowWindow( g_hContainer , SW_HIDE )
      end if
   #endif
   case WM_CLOSE
      if GetWindowTextLength( CTL(wcEdit) ) then
         #define sMsg !"All unsaved data will be lost, quit anyway?"
         if MessageBox( CTL(wcMain) , sMsg , "File->Quit" , MB_ICONQUESTION or MB_YESNO ) <> IDYES then return 0
      end if
      PostQuitMessage(0) ' to quit
   case WM_DESTROY 'Windows was closed/destroyed
    PostQuitMessage(0) ' to quit
    return 0 
   end select
   
   ' *** if program reach here default predefined action will happen ***
   return DefWindowProc( hWnd, message, wParam, lParam )
    
end function

' *********************************************************************
' *********************** SETUP MAIN WINDOW ***************************
' *********************************************************************
sub WinMain ()
   
   dim tMsg as MSG
   dim tcls as WNDCLASS
   dim as HWND hWnd  
    
   '' Setup window class  
    
   with tcls
    .style         = CS_HREDRAW or CS_VREDRAW
    .lpfnWndProc   = @WndProc
    .cbClsExtra    = 0
    .cbWndExtra    = 0
    .hInstance     = g_AppInstance
    .hIcon         = LoadIcon( g_AppInstance, "FB_PROGRAM_ICON" )
    .hCursor       = LoadCursor( NULL, IDC_ARROW )
    .hbrBackground = GetSysColorBrush( COLOR_BTNFACE )
    .lpszMenuName  = NULL
    .lpszClassName = strptr( sAppName )
   end with
    
   '' Register the window class     
   if( RegisterClass( @tcls ) = FALSE ) then
    MessageBox( null, "Failed to register wcls!", sAppName, MB_ICONINFORMATION )
    exit sub
   end if
    
   '' Create the window and show it
   'WS_EX_COMPOSITED or WS_EX_LAYERED
   
   var hMenu = CreateMainMenu()
   var hAcceleratos = CreateMainAccelerators()
   
   hWnd = CreateWindowEx(0,sAppName,sAppName, WS_TILEDWINDOW or WS_CLIPCHILDREN, _
   200,200,g_WndWid,g_WndHei,null,hMenu,g_AppInstance,0)
   
   'SetClassLong( hwnd , GCL_HBRBACKGROUND , CLNG(GetSysColorBrush(COLOR_INFOBK)) )
   'SetLayeredWindowAttributes( hwnd , GetSysColor(COLOR_INFOBK) , 192 , LWA_COLORKEY )
    
   '' Process windows messages
   ' *** all messages(events) will be read converted/dispatched here ***
   ShowWindow( hWnd , SW_SHOW )
   UpdateWindow( hWnd )
  
   while( GetMessage( @tMsg, NULL, 0, 0 ) <> FALSE )    
      if TranslateAccelerator( hWnd , hAcceleratos , @tMsg ) then continue while
      if IsDialogMessage( hWnd , @tMsg ) then continue while
      TranslateMessage( @tMsg )
      DispatchMessage( @tMsg )    
      ProcessMessage( tMsg )
   wend    

end sub

sAppName = "LegoScript"
InitCommonControls()
if LoadLibrary("Riched32.dll")=0 then
  MessageBox(null,"Failed To Load richedit component",null,MB_ICONERROR)
  end
end if

function BeforeExit( dwCtrlType as DWORD ) as WINBOOL   
   GetClipboard() : system() : return 0 'never? :P
end function
SetConsoleCtrlHandler( @BeforeExit , TRUE )

g_AppInstance = GetModuleHandle(null)
WinMain() '<- main function
g_DoQuit = 1

#if 0
   3865 BP10 #7 s69 = 3001p11 B1 y90 c1;
   B1 s1 = 3001p11 B2 #2 c5;
   B2 s1 = 3001p11 B3 #3 c6;
   B3 c5 = 3001p11 B4 #4 s1;
   B4 c1 = 4070 B5 #5 s2;
   003238a P1 #2 c1 = 003238b P2 #4 s1;
#endif
