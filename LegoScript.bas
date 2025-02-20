#define __Main

#include once "windows.bi"
#include once "win\commctrl.bi"
#include once "win\commdlg.bi"
#include once "crt.bi"
#include once "fbthread.bi"

#undef File_Open

'TODO (18/02/25): merge ViewModel into LegoSCript.bas

'*************** Enumerating our control id's ***********
enum WindowControls
  wcMain
  wcButton
  wcEdit
  wcOutput
  wcStatus
  wcLast
end enum
enum WindowFonts
   wfDefault
   wfEdit
   wfLast
end enum
enum Accelerators
   acFirst = 9100-1
   acToggleMenu
end enum

#include "Loader\LoadLDR.bas"
#include "Loader\Include\Colours.bas"
#include "Loader\Modules\Clipboard.bas"
#include "Loader\Modules\InitGL.bas"
#include "Loader\Modules\Math3D.bas"
#include "Loader\Modules\Normals.bas"
#include "Loader\Modules\Matrix.bas"
#include "Loader\Modules\Model.bas"

dim shared as hwnd CTL(wcLast-1)     'controls
dim shared as hinstance APPINSTANCE  'instance
dim shared as hfont MyFont(wfLast-1) 'fonts
dim shared as string sAppName        'AppName (window title 'prefix')
dim shared as HMENU g_WndMenu        'Main Menu handle
dim shared as long g_WndWid=640 , g_WndHei=480
dim shared g_hCurMenu as any ptr , g_CurItemID as long , g_CurItemState as long

dim shared as hwnd g_GfxHwnd
dim shared as byte g_DoQuit
dim shared as string g_CurrentFilePath

'******************************************************************

namespace Viewer
   dim shared as byte g_LoadFile = 0
   dim shared as string g_sGfxFile , g_sFileName
   dim shared as any ptr g_Mutex
   
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
      g_GfxHwnd = InitOpenGL(400,300)   
      ShowWIndow( g_GfxHwnd , SW_HIDE )
      if hReadyEvent then SetEvent( hReadyEvent )
                  
      dim as long iModel=-1,iBorders=-1
      dim as DATFile ptr  pModel
      dim as single xMid,yMid,zMid , g_zFar
      dim as PartSize tSz
      dim as long g_PartCount , g_CurPart = -1
               
      dim as boolean bBoundingBox
      dim as boolean bLeftPressed,bRightPressed,bWheelPressed
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
               fZoom = -3+(iWheel/8)
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
                  if bBoundingBox then
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
                  if bBoundingBox then
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
                  if bBoundingBox then
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
               case fb.SC_TAB
                  bBoundingBox = not bBoundingBox
               end select
            case fb.EVENT_WINDOW_CLOSE
               exit do
            end select
         wend
                     
         while IsWindowVisible( g_GfxHwnd ) = 0
            flip : sleep 10,1
         wend
         flip
         
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
                               
               fZoom = -3 : fRotationX = 120 : fRotationY = 20
               iWheel = 0 : iPrevWheel = 0
               
               g_DrawCount = pModel->iPartCount
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
                  fPositionX = 0 '((.xMin + .xMax)\-2)-.xMin
                  fPositionY = (.yMin + .yMax)\-2
                  fPositionZ = (.zMax-.zMin) 'abs(.zMax)-abs(.zMin)
                  fPositionZ = sqr(fPositionZ)*-40
               end with
                              
               CheckCollisionModel( pModel , atCollision() )
               printf(!"Parts: %i , Collisions: %i \n",g_PartCount,ubound(atCollision)\2)
               
               exit do 'loaded fine
               
            loop
            MutexUnlock( g_Mutex )
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

'******************** Menu Handling Helper Functions **************
namespace Menu
   function AddSubMenu( hMenu as any ptr , sText as string ) as any ptr
      if IsMenu(hMenu)=0 then return NULL
      var hResult = CreatePopupMenu()
      AppendMenu( hMenu , MF_POPUP or MF_STRING , cast(UINT_PTR,hResult) , sText )    
      if hMenu=g_WndMenu andalso CTL(wcMain) then DrawMenuBar( CTL(wcMain) )
      return hResult
   end function
   function MenuAddEntry( hMenu as any ptr , iID as long = 0 , sText as string = "" , pEvent as any ptr = 0 , bState as long = 0 ) as long    
      if IsMenu(hMenu)=0 then return -1
      dim as MENUITEMINFO tItem = type( sizeof(MENUITEMINFO) )    
      tItem.fMask      = MIIM_DATA or MIIM_ID or MIIM_STATE or MIIM_TYPE
      tItem.fType      = iif( len(sText) , iif( bState and MFT_RADIOCHECK , MFT_RADIOCHECK , MFT_STRING ) , MFT_SEPARATOR )
      tItem.fState     = bState and (not MFT_RADIOCHECK)
      tItem.wID        = iID
      tItem.dwItemData = cast(long_ptr,pEvent)
      if len(sText) then tItem.dwTypeData = strptr(sText)
      InsertMenuItem( hMenu , &hFFFFFFFF , true , @tItem )
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
end namespace

declare sub File_SaveAs()
'**************** Main Menu Layout **************
sub File_New()
   if GetWindowTextLength( CTL(wcEdit) ) then
      #define sMsg !"All unsaved data will be lost, continue?"
      if MessageBox( CTL(wcMain) , sMsg , "File->New" , MB_ICONQUESTION or MB_YESNO ) <> IDYES then exit sub
   end if
   SetWindowText( CTL(wcEdit) , "" )
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
      .lpstrFilter = @!"Lego Script Files\0*.ls\0All Files\0*.*\0\0"
      .nFilterIndex = 0 '.ls
      .lpstrFile = @zFile
      .nMaxFile = 32767
      .lpstrInitialDir = NULL
      .lpstrTitle = NULL
      .Flags = OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_NOCHANGEDIR
      if GetOpenFileName( @tOpen ) = 0 then exit sub      
      print "["+*.lpstrFile+"]"
      var f = freefile()
      if open(*.lpstrFile for input as #f) then
         MessageBox( CTL(wcMain) , !"Failed to open:\n\n'"+*.lpstrFile+"'" , NULL , MB_ICONERROR )
         exit sub
      end if
      dim as string sLine,sScript
      while not eof(f)
         line input #f, sLine : sScript += sLine+!"\r\n"
      wend
      close #f
      SetWindowText( CTL(wcEdit) , sScript ) 
      sLine="":sScript=""
      g_CurrentFilePath = *.lpstrFile
      
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
   print iMaxLen
   print sScript
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
      .lpstrFilter = @!"Lego Script Files\0*.ls\0All Files\0*.*\0\0"
      .nFilterIndex = 0 '.ls
      .lpstrFile = @zFile
      .nMaxFile = 32767
      .lpstrInitialDir = NULL
      .lpstrTitle = NULL
      .Flags = OFN_PATHMUSTEXIST 'or OFN_NOCHANGEDIR
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
   print __FUNCTION__
end sub
sub Edit_Copy()
   print __FUNCTION__
end sub
sub View_ToggleGW()   
   if g_GfxHwnd then ShowWindow( g_GfxHwnd , iif( g_CurItemState and MFS_CHECKED , SW_HIDE , SW_SHOW ) )
   Menu.MenuState( g_hCurMenu,g_CurItemID,g_CurItemState xor MFS_CHECKED )
end sub
sub Help_About()
   print __FUNCTION__
end sub
function CreateMainMenu() as HMENU
   
   #macro _SubMenu( _sText ) 
   scope
      var hMenu = Menu.AddSubMenu( hMenu , _sText )
   #endmacro
   #define _EndSubMenu() end scope
   #define _Entry( _Parms... ) Menu.MenuAddEntry( hMenu , _Parms )
   
   var hMenu = CreateMenu() : g_WndMenu = hMenu
   _SubMenu( "File" )
     _Entry( 10001 , "New"     , @File_New    )
     _Entry( 10002 , "Open"    , @File_Open   )     
     _Entry( 10003 , "Save"    , @File_Save   )
     _Entry( 10004 , "Save As" , @File_SaveAs )
     _Entry()
     _Entry( 10005 , "Quit"    , @File_Exit   )
   _EndSubMenu()
   _SubMenu( "&Edit" )
      _Entry( 20001 , "&Undo" , @Edit_Undo ) ' , MFT_RADIOCHECK or MFS_CHECKED )
      _Entry( 20002 , "&Copy" , @Edit_Copy ) ', MFT_RADIOCHECK )
   _EndSubMenu()
   _SubMenu( "&View" )
      _Entry( 30001 , "&Graphics Window" , @View_ToggleGW ) ' , MFT_RADIOCHECK or MFS_CHECKED )      
   _EndSubMenu()
   _SubMenu( "&Help" )          
      _Entry( 40001 , "About" , @Help_About )
   _EndSubMenu()
   return hMenu
end function

sub ProcessAccelerator( iID as long )
   select case iID
   case acToggleMenu
      SetMenu( CTL(wcMain) , iif( GetMenu(CTL(wcMain)) , NULL , g_WndMenu ) )
   end select
end sub

function CreateMainAccelerators() as HACCEL
   static as ACCEL AccelList(...) = { _
      ( FSHIFT or FVIRTKEY , VK_SPACE , acToggleMenu ) _
   }
   return CreateAcceleratorTable( @AccelList(0) , ubound(AccelList)+1 )
end function

sub DockGfxWindow()
   dim as RECT RcWnd=any,RcGfx=any,RcCli=any
   GetWindowRect( g_GfxHwnd , @RcGfx )
   GetWindowRect( CTL(wcMain) ,@RcWnd )
   var iYPos = RcWnd.top+((RcWnd.bottom-RcWnd.Top)-(RcGfx.bottom-RcGfx.top))\2
   GetClientRect( CTL(wcMain) ,@RcCli )
   dim as POINT tPtRight = type(RcCli.Right-3,0)
   ClientToScreen( CTL(wcMain) , @tPtRight )   
   SetWindowPos( g_GfxHwnd , NULL , tPtRight.x ,iYPos , 0,0 , SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE )
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
   MoveWindow( CTL(wcStatus) ,0,0 , 0,0 , TRUE )
   DockGfxWindow()
   
end sub

' *************** Procedure Function ****************
function WndProc ( hWnd as HWND, message as UINT, wParam as WPARAM, lParam as LPARAM ) as LRESULT
         
   select case( message )   
    
   case WM_CREATE 'Window was created
        
    if CTL(wcMain) then return 0
    CTL(wcMain) = hwnd        
    var hEventGfxReady = CreateEvent( NULL , FALSE , FALSE , NULL )    
    ThreadDetach( ThreadCreate( @Viewer.MainThread , hEventGfxReady ) )
               
    'just a macro to help creating controls
    #define CreateControl( mID , mExStyle , mClass , mCaption , mStyle , mX , mY , mWid , mHei ) CTL(mID) = CreateWindowEx(mExStyle,mClass,mCaption,mStyle,mX,mY,mWid,mHei,hwnd,cast(hmenu,mID),APPINSTANCE,null)
    #define UpDn UPDOWN_CLASS
    
    const cStyle = WS_CHILD or WS_VISIBLE 'Standard style for buttons class controls :)    
    const cUpDnStyle = cStyle or UDS_AUTOBUDDY' or UDS_SETBUDDYINT  
    const cButtonStyle = cStyle  
    const cLabelStyle = cStyle
    const cStatStyle = cStyle or SBARS_SIZEGRIP
    
    const cTxtStyle =  cStyle or WS_VSCROLL or ES_MULTILINE
    const cErrStyle =  cStyle or WS_VSCROLL or ES_MULTILINE or ES_READONLY
    const RichStyle = cStyle or ES_READONLY or ES_AUTOVSCROLL or WS_VSCROLL or ES_MULTILINE
    
    const cBrd = WS_EX_CLIENTEDGE
    
    ' **** Creating a Control ****
    CreateControl( wcButton , null , "button"        , "Execute"      , cStyle      , 10 ,   8 ,  80 ,  24 )        
    CreateControl( wcEdit   , cBrd , "edit"          , ""             , cTxtStyle   , 10 ,  40 , 620 , 240 )
    CreateControl( wcOutput , cBrd , "edit"          , ""             , cErrStyle   , 10 , 280 , 620 , 200 )
    CreateControl( wcStatus , null , STATUSCLASSNAME , "Status"       , cStatStyle  ,  0 ,   0 ,   0 ,   0 )
    
    ' **** Creating a font ****
    var hDC = GetDC(hWnd) 'can be used for other stuff that requires a temporary DC
    var nHeight = -MulDiv(12, GetDeviceCaps(hDC, LOGPIXELSY), 72) 'calculate size matching DPI
    
    MyFont(wfDefault) = CreateFont(nHeight,0,0,0,FW_NORMAL,0,0,0,DEFAULT_CHARSET,0,0,0,0,"verdana")
    MyFont(wfEdit)    = CreateFont(nHeight,0,0,0,FW_NORMAL,0,0,0,DEFAULT_CHARSET,0,0,0,0,"Consolas")
    ' **** Setting this font for all controls ****
    for CNT as integer = wcMain+1 to wcLast-1
      dim as long iFont = wfDefault
      select case CNT
      case wcEdit : iFont = wfEdit
      end select
      SendMessage(CTL(CNT),WM_SETFONT,cast(wparam,MyFont(iFont)),true)
      'SetWindowTheme(CTL(CNT),"","")
    next CNT 
    
    'SetTimer( CTL(wcMain) , 1 , 1000 , 0 )
    ReleaseDC(hWnd,hDC)    
        
    WaitForSingleObject( hEventGfxReady , INFINITE )    
    CloseHandle( hEventGfxReady )
    if g_GfxHwnd = 0 then return -1 'failed
    
    ResizeMainWindow( true )    
          
   case WM_MENUSELECT 'track newest menu handle/item/state
      var iID = cuint(LOWORD(wParam)) , fuFlags = cuint(HIWORD(wParam)) , hMenu = cast(HMENU,lParam) 
      if hMenu then g_CurItemID = iID : g_hCurMenu = hMenu            
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
      case BN_CLICKED 'button click
         select case wID
         case wcButton
            Viewer.LoadFile( exepath()+"\Collision.ldr" )
            'puts("Button click!")
         end select
      end select      
      
      return 0
    
   case WM_SIZE      
      ResizeMainWindow()
      return 0
   case WM_MOVE
      DockGfxWindow()
   case WM_CLOSE
      if GetWindowTextLength( CTL(wcEdit) ) then
         #define sMsg !"All unsaved data will be lost, continue?"
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
   
   dim wMsg as MSG
   dim wcls as WNDCLASS
   dim as HWND hWnd  
    
   '' Setup window class  
    
   with wcls
    .style         = CS_HREDRAW or CS_VREDRAW
    .lpfnWndProc   = @WndProc
    .cbClsExtra    = 0
    .cbWndExtra    = 0
    .hInstance     = APPINSTANCE
    .hIcon         = LoadIcon( APPINSTANCE, "FB_PROGRAM_ICON" )
    .hCursor       = LoadCursor( NULL, IDC_ARROW )
    .hbrBackground = GetSysColorBrush( COLOR_BTNFACE )
    .lpszMenuName  = NULL
    .lpszClassName = strptr( sAppName )
   end with
    
   '' Register the window class     
   if( RegisterClass( @wcls ) = FALSE ) then
    MessageBox( null, "Failed to register wcls!", sAppName, MB_ICONINFORMATION )
    exit sub
   end if
    
   '' Create the window and show it
   'WS_EX_COMPOSITED or WS_EX_LAYERED
   
   var hMenu = CreateMainMenu()
   var hAcceleratos = CreateMainAccelerators()
   
   hWnd = CreateWindowEx(0,sAppName,sAppName, WS_TILEDWINDOW or WS_CLIPCHILDREN, _
   200,200,g_WndWid,g_WndHei,null,hMenu,APPINSTANCE,0)
   
   'SetClassLong( hwnd , GCL_HBRBACKGROUND , CLNG(GetSysColorBrush(COLOR_INFOBK)) )
   'SetLayeredWindowAttributes( hwnd , GetSysColor(COLOR_INFOBK) , 192 , LWA_COLORKEY )
    
   '' Process windows messages
   ' *** all messages(events) will be read converted/dispatched here ***
   ShowWindow( hWnd , SW_SHOW )
   UpdateWindow( hWnd )
  
   while( GetMessage( @wMsg, NULL, 0, 0 ) <> FALSE )    
      if TranslateAccelerator( hWnd , hAcceleratos , @wMsg ) then continue while
      if IsDialogMessage( hWnd , @wMsg ) then continue while
      TranslateMessage( @wMsg )
      DispatchMessage( @wMsg )    
   wend    

end sub

sAppName = "Lego Script"
InitCommonControls()
APPINSTANCE = GetModuleHandle(null)
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
