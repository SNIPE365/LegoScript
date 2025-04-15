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
'TODO (08/04/25): verify child shadow library

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
   acFilterDump
end enum

#define CTL(_I) g_tMainCtx.hCtl(_I).hwnd

#include once "LSModules\TryCatch.bas"
#include once "LSModules\Layout.bas"

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
dim shared as byte g_DoQuit , g_Show3D , g_Dock3D
dim shared as string g_CurrentFilePath

declare sub DockGfxWindow()
declare sub File_SaveAs()
declare sub RichEdit_Replace( hCtl as HWND , iStart as long , iEnd as long , sText as string , bKeepSel as long = true )

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
#macro ForEachMenuEntry( __Entry , __SubMenu , __EndSubMenu , __Separator )
   __SubMenu( "&File" )
     __Entry( meFile_New    , "&New"              , _Ctrl        , VK_N , @File_New    )
     __Entry( meFile_open   , "&Open"             , _Ctrl        , VK_O , @File_Open   )     
     __Entry( meFile_Save   , "&Save"             , _Ctrl        , VK_S , @File_Save   )     
     __Entry( meFile_SaveAs , "Save &As"          , _Ctrl+_Shift , VK_S , @File_SaveAs )     
     __Separator()
     __Entry( meFile_Exit   , "&Quit" !"\tAlt+F4" , _Ctrl        , VK_Q , @File_Exit   )
   __EndSubMenu()   
   __SubMenu( "&Edit" )            
      __Entry( meEdit_Undo  , "&Undo"  !"\tCtrl+Z" ,       ,      , @Edit_Undo ) ' , MFT_RADIOCHECK or MFS_CHECKED )
      __Entry( meEdit_Copy  , "&Copy"  !"\tCtrl+C" ,       ,      , @Edit_Copy ) ', MFT_RADIOCHECK )
      __Entry( meEdit_Build , "&Build"             , _Ctrl , VK_B , @Button_Compile )
   __EndSubMenu()
   __SubMenu( "&Completion" )
      __Entry( meCompletion_Enable , "&Enable"   , _Ctrl , VK_E , @Completion_Enable )         
      __SubMenu( "&Filters" , sbeCompletion_Filters )
         __Entry( meCompletion_ClearFilters  , "C&lear"      , _Ctrl+_Shift , VK_C , @Completion_ClearFilters )
         __Entry( meCompletion_InvertFilters , "&Invert"     , _Ctrl        , VK_I ,  @Completion_InvertFilters )
         __Separator()
         __Entry( meFilter_Variations    , "&Variations" , _Alt+_Shift  , VK_F , @Completion_Toggle )
         __Entry( meFilter_Donor         , "&Donor"      , _Alt         , VK_D , @Completion_Toggle )
         __Entry( meFilter_Path          , "&Path"       , _Alt         , VK_P , @Completion_Toggle )
         __Entry( meFilter_Printed       , "P&rinted"    , _Alt+_Shift  , VK_P , @Completion_Toggle )
         __Entry( meFilter_Shortcut      , "Shortcut"    , _Alt         , VK_S , @Completion_Toggle )
         __Entry( meFilter_Stickered     , "Stic&kered"  , _Alt         , VK_K , @Completion_Toggle )
         __Entry( meFilter_MultiColor    , "Multi&color" , _Alt         , VK_M , @Completion_Toggle )
         __Entry( meFilter_PreColored    , "Pre-c&olored", _Alt+_Shift  , VK_C , @Completion_Toggle )
         __Entry( meFilter_Template      , "&Template"   , _Alt         , VK_T , @Completion_Toggle )
         __Entry( meFilter_Alias         , "&Alias"      , _Alt         , VK_A , @Completion_Toggle )
         __Entry( meFilter_Moulded       , "&Moulded"    , _Alt+_Shift  , VK_M , @Completion_Toggle )
         __Entry( meFilter_Helper        , "&Helper"     , _Alt+_Shift  , VK_H , @Completion_Toggle )
         __Entry( meFilter_Stickers      , "&Stickers"   , _Alt         , VK_S , @Completion_Toggle )
      __EndSubMenu()            
   __EndSubMenu()
   __SubMenu( "&View" )
      __Entry( meView_ToggleGW    , "&Graphics Window"    , _Ctrl        , VK_G   , @View_ToggleGW ) ' , MFT_RADIOCHECK or MFS_CHECKED )      
      __Entry( meView_ToggleGWDock, "&Dock GW in Main"    , _Ctrl+_Shift , VK_L   , @View_ToggleGWDock )
      __Separator()
      __Entry( meView_ResetView   , "Reset View parts"    !"\tBACKSPACE" , , , @View_Key      , MFS_GRAYED )
      __Entry( meView_NextPart    , "View &Next part"     !"\t+"         , , , @View_Key      , MFS_GRAYED )
      __Entry( meView_PrevPart    , "View &Previous part" !"\t-"         , , , @View_Key      , MFS_GRAYED )
      __Separator()   
      __Entry( meView_ShowBox     , "&Show bounding box"  !"\tTAB"       , , , @View_Toggle   , MFS_GRAYED )
      __Entry( meView_ResetBox    , "Reset bounding box"  !"\tShift BACKSPACE", , , @View_Key , MFS_GRAYED )
      __Entry( meView_NextBoxPart , "Ne&xt part"          !"\tShift +"   , , , @View_Key      , MFS_GRAYED )
      __Entry( meView_PrevBoxPart , "&Pre&vious part"     !"\tShift -"   , , , @View_Key      , MFS_GRAYED )
   __EndSubMenu()   
   __SubMenu( "&Help" )          
      __Entry( meHelp_About , "About" , , , @Help_About )
   __EndSubMenu()
#endmacro
#define _Shift FSHIFT
#define _Ctrl  FCONTROL
#define _Alt   FALT
#define Dummy()
#define EnumEntry( _Name , _p... ) _Name
#macro MayEnumEntry( _p... )
   #if len(#_p)
      EnumEntry(_p)
   #endif
#endmacro
#define MayEnumSubMenu( _s , _name... ) _name
   enum MenuEntries
      meFirst = 1000
      ForEachMenuEntry( MayEnumEntry , MayEnumSubMenu , Dummy , Dummy )
      meLast 
   end enum
#undef EnumEntry
#undef MayEnumEntry
#undef MayEnumSubMenu

'#define ViewerShowInfo
'#define DebugShadow

sub LogError( sError as string )   
   var f = freefile()
   open exepath+"\FatalErrors.log" for append as #f
   print #f, date() + " " + time() + sError
   close #f   
   puts(sError)
   SetWindowText( CTL(wcStatus) , sError )   
   MessageBox( CTL(wcMain) , sError , NULL , MB_ICONERROR )
end sub

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
   function IsChecked( iID as long ) as boolean
      return (GetMenuState( g_WndMenu , iID , MF_BYCOMMAND ) and MF_CHECKED )<>0
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
               case asc("S")-asc("@") 'shadow
                  if g_CurDraw >=0 then
                     'FindFile(
                     'FindShadowFile(
                     with pModel->tParts(g_CurDraw)
                        if .bType=1 then                              
                           var sFile = GetPartNameByIndex(._1.lModelIndex)
                           if FindShadowFile(sFile) then 
                              shell "start notepad "+sFile
                           else
                              MessageBox( g_GfxHwnd , sFile , "Shadow file not found" , MB_ICONWARNING )
                           end if
                        end if
                     end with
                  end if
               case asc("M")-asc("@") 'Model
                  if g_CurDraw >=0 then                     
                     with pModel->tParts(g_CurDraw)
                        if .bType=1 then                              
                           var sFile = GetPartNameByIndex(._1.lModelIndex)
                           if FindFile(sFile) then 
                              shell "start notepad "+sFile
                           else
                              MessageBox( g_GfxHwnd , sFile , "Model file not found" , MB_ICONWARNING )
                           end if
                        end if
                     end with
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
            Try()
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
                     #ifdef ViewerShowInfo
                        printf(!"X %f > %f (%g ldu)\n",.xMin,.xMax,(.xMax-.xMin))
                        printf(!"Y %f > %f (%g ldu)\n",.yMin,.yMax,(.yMax-.yMin))
                        printf(!"Z %f > %f (%g ldu)\n",.zMin,.zMax,(.zMax-.zMin))
                        printf(!"Lines: %i - Optis: %i - Trigs: %i - Quads: %i - Verts: %i\n", _
                           g_TotalLines , g_TotalOptis , g_TotalTrigs , g_TotalQuads , _
                           g_TotalLines*2+g_TotalOptis*2+g_TotalTrigs*3+g_TotalQuads*4 _
                        )
                     #endif
                     if bResetAttributes then
                        fPositionX = 0 '((.xMin + .xMax)\-2)-.xMin
                        fPositionY = (.yMin + .yMax)\-2
                        fPositionZ = (.zMax-.zMin) 'abs(.zMax)-abs(.zMin)
                        fPositionZ = sqr(fPositionZ)*-40
                     end if
                  end with
                                 
                  CheckCollisionModel( pModel , atCollision() )
                  #ifdef ViewerShowInfo
                     printf(!"Parts: %i , Collisions: %i \n",g_PartCount,ubound(atCollision)\2)
                  #endif
                  
                  exit do 'loaded fine
                  
               loop
            Catch()
               LogError("Viewer.LoadFile crashed!!!")               
            EndCatch()
            EndTry()
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
         
         Try()
            if g_CurDraw < 0 then
               glCallList(	iModel )   
            else
               RenderModel( pModel , false , , g_CurDraw )      
            end if
            glCallList(	iBorders-(g_CurDraw>=0) )
            Catch()
               LogError("Crashed at rendering!!!")
            EndCatch()
         EndTry()
      
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

sub Do_Compile()   
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
sub Button_Compile()
   Try()
      Do_Compile()
      Catch()
         LogError( "Compilation Crashed!!!" )
      EndCatch()
   EndTry()
end sub
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
   EnableMenuItem( g_hCurMenu , sbeCompletion_Filters , iif( iToggledState and MFS_CHECKED , MF_ENABLED , MF_GRAYED ) )
   if (iToggledState and MFS_CHECKED)=0 then ShowWindow( g_hContainer , SW_HIDE )
end sub
sub Completion_ClearFilters()
   puts(__FUNCTION__)
   g_FilterFlags = 0
   for N as long = meFilter_Variations to meFilter_Stickers
      Menu.MenuState( g_hCurMenu , N , g_CurItemState )
   next N
end sub
sub Completion_InvertFilters()
   puts(__FUNCTION__)
   for N as long = meFilter_Variations to meFilter_Stickers
      Menu.Trigger( N )
   next N
end sub
sub Completion_Toggle()   
   var iToggledState = g_CurItemState xor MFS_CHECKED
   Menu.MenuState( g_hCurMenu,g_CurItemID,iToggledState )   
   #define ChgFilter( _Name ) g_FilterFlags = iif( iToggledState and MFS_CHECKED , g_FilterFlags or _Name , g_FilterFlags and (not (_Name)) )
   select case g_CurItemID
   case meFilter_Variations  : ChgFilter( wIsHidden )   
   case meFilter_Donor       : ChgFilter( wIsDonor )
   case meFilter_Path        : ChgFilter( wIsPath )
   case meFilter_Printed     : ChgFilter( wIsPrinted )
   case meFilter_Shortcut    : ChgFilter( wIsShortcut )
   case meFilter_Stickered   : ChgFilter( wIsStickered )
   case meFilter_MultiColor  : ChgFilter( wIsMultiColor )
   case meFilter_PreColored  : ChgFilter( wIsPreColored )
   case meFilter_Template    : ChgFilter( wIsTemplate )
   case meFilter_Alias       : ChgFilter( wIsAlias )    
   case meFilter_Moulded     : ChgFilter( wIsMoulded )
   case meFilter_Helper      : ChgFilter( wIsHelper )
   case meFilter_Stickers    : ChgFilter( wIsSticker )
   end select
end sub
sub View_ToggleGW()
   var iToggledState = g_CurItemState xor MFS_CHECKED
   g_Show3D = (iToggledState and MFS_CHECKED)<>0
   if g_GfxHwnd then      
      ShowWindow( g_GfxHwnd , iif( g_Show3D , SW_SHOWNA , SW_HIDE ) )
      if g_Show3D then
         SetWindowPos( g_GfxHwnd , HWND_TOPMOST , 0,0,0,0 , SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE)
         SetWindowPos( g_GfxHwnd , HWND_NOTOPMOST , 0,0,0,0 , SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE)
      end if
   end if   
   Menu.MenuState( g_hCurMenu,g_CurItemID, iToggledState )
   for N as long = meView_ResetView to meView_PrevBoxPart 'View.*
      EnableMenuItem( g_hCurMenu , N , iif( iToggledState and MFS_CHECKED , MF_ENABLED , MF_GRAYED ) )
   next N
end sub
sub View_ToggleGWDock()
   var iToggledState = g_CurItemState xor MFS_CHECKED
   g_Dock3D = (iToggledState and MFS_CHECKED)<>0
   if g_Dock3D andalso g_GfxHwnd then DockGfxWindow()
   Menu.MenuState( g_hCurMenu,g_CurItemID, iToggledState )   
end sub
sub View_Key()
   if IsWindow(g_GfxHwnd)=0 then exit sub
   dim vk as long , sft as byte
   select case g_CurItemID
   case meView_ResetView   : vk = VK_BACK     'Backspace
   case meView_NextPart    : vk = VK_ADD      '+
   case meView_PrevPart    : vk = VK_SUBTRACT '-
   case meView_ResetBox    : vk = VK_BACK     : sft = 1 'Shift BACKSPACE
   case meView_NextBoxPart : vk = VK_ADD      : sft = 1 'Shift +
   case meView_PrevBoxPart : vk = VK_SUBTRACT : sft = 1 'Shift -
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
   #define _Separator() Menu.MenuAddEntry( hMenu )
   #macro _Entry( _idName , _Text , _Modifiers , _Accelerator , _Callback... )      
      #if len(#_Accelerator)         
         #if (_Modifiers and _Shift)
            #define _sShift "Shift+"
         #else
            #define _sShift
         #endif
         #if (_Modifiers and _Ctrl)
            #define _sCtrl "Ctrl+"
         #else
            #define _sCtrl
         #endif
         #if (_Modifiers and _Alt)
            #define _sAlt "Alt+"
         #else
            #define _sAlt
         #endif
         #if _Accelerator >= asc("A") and _Accelerator <= asc("Z")
           #define _sKey +chr(_Accelerator)
         #else
            #define _sKey s##_Accelerator
         #endif
         const _sText2 = _Text !"\t" _sCtrl _sAlt _sShift _sKey
         #undef _sCtrl
         #undef _sAlt
         #undef _sShift
         #undef _sKey
      #else
         const _sText2 = _Text
      #endif      
      Menu.MenuAddEntry( hMenu , _idName , _sText2 , _Callback )
      #undef _sText2      
   #endmacro     
     
   var hMenu = CreateMenu() : g_WndMenu = hMenu      
      
   ForEachMenuEntry( _Entry ,  _SubMenu , _EndSubMenu , _Separator )
   
   return hMenu
end function

static shared as long g_iPrevTopRow = 0 , g_iPrevRowCount = 0 , g_RowDigits = 2
static shared as zstring*128 g_zRows
static shared as SearchQueryContext g_SQCtx
static shared as string sLastSearch

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
sub RichEdit_Replace( hCtl as HWND , iStart as long , iEnd as long , sText as string , bKeepSel as long = true )
   var iMask = SendMessage( hCtl , EM_GETEVENTMASK   , 0 , 0 )                     
   dim as CHARRANGE tRange = any
   if bKeepSel then SendMessage( hCtl , EM_EXGETSEL , 0 , cast(LPARAM,@tRange) )
   SendMessage( hCtl , EM_SETEVENTMASK , 0 , iMask and (not ENM_SELCHANGE))
   SendMessage( hCtl , EM_SETSEL , iStart , iEnd ) 
   SendMessage( hCtl , EM_REPLACESEL , false , cast(LPARAM,strptr(sText)) )
   if bKeepSel then SendMessage( hCtl , EM_EXSETSEL , 0 , cast(LPARAM,@tRange) )
   SendMessage( hCtl , EM_SETEVENTMASK , 0 , iMask)
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
   'changed to edit (for now?) only matter if Auto Completion is enabled
   g_SQCtx.iRow = iRow : g_SQCtx.iCol = iCol
   if Menu.IsChecked(meCompletion_Enable)=0 then exit sub
   
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
   'printf( !"%i:%s\t%f\r",iSz,left(zRow+space(iWid-6),iWid-5),timer )   
   with g_SQCtx
      if ubound(.sTokenTxt) < 0 then redim .sTokenTxt(.iMaxTok-1)      
      .bChanged = 1 : .iCur = iCol 'instr( iCol+1 , zRow , " " )-1
      'if .iCur < 0 then .iCur = iSz-2
   end with
   sLastSearch = zRow
   
   Try()
      HandleTokens( sLastSearch , g_SQCtx )
      Catch()
         LogError( "Auto completion Crashed!!!" )
      EndCatch()
   EndTry()
   
end sub
function RichEdit_KeyPress( hCtl as HWND , iKey as long , iMod as long ) as long
         
   select case iKey     
   case VK_TAB
      if iMod=_Shift orelse iMod=0 then 'andalso len(.sToken)>1 then
         var iCount = SendMessage( g_hSearch , LB_GETCOUNT , 0 , 0 )
         var iSel   = SendMessage( g_hSearch , LB_GETCURSEL , 0 , 0 )
         var iSelOrg = iSel
         if iSel = LB_ERR then iSel=0 else iSel = (iSel+iCount+iif(iMod=0,1,-1)) mod iCount
         SendMessage( g_hSearch , LB_SETCURSEL , iSel , 0 )
         g_SearchChanged = true         
      end if      
   end select
   
   if g_SearchChanged then      
      Try()
         HandleTokens( sLastSearch , g_SQCtx )
         Catch()
            LogError( "Auto completion Crashed!!!" )
         EndCatch()
      EndTry()
   end if
   
   return 0
end function

sub ProcessAccelerator( iID as long )
   select case iID
   case acToggleMenu
      SetMenu( CTL(wcMain) , iif( GetMenu(CTL(wcMain)) , NULL , g_WndMenu ) )
   case meFirst+1 to MeLast-1 '--- accelerators for menu's as well ---
      Menu.Trigger( iID )
   case acFilterDump        : puts("Dump filter parts")  '--- debug accelerators ---
   end select
end sub
function CreateMainAccelerators() as HACCEL
   '#macro ForEachMenuEntry( __Entry , __SubMenu , __EndSubMenu , __Separator )
   #define __Dummy( _Dummy... ) __FB_UNQUOTE__("_")
   #macro _Entry( _idName , _Unused0 , _Modifiers , _Accelerator , _Unused... )            
      __FB_UNQUOTE__( __FB_EVAL__( __FB_IIF__( __FB_ARG_COUNT__(_Accelerator) , "( " __FB_QUOTE__( __FB_EVAL__(_Modifiers)) " or FVIRTKEY , " #_Accelerator ", " #_idName " ), _ " , "_ " ) ) )      
   #endmacro
   static as ACCEL AccelList(...) = { _
      ForEachMenuEntry( _Entry , __Dummy , __Dummy , __Dummy )
      ( FSHIFT or FVIRTKEY , VK_SPACE , acToggleMenu ) _
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
   'if tPtRight.x >= (RcDesk.right-8) then 
   '   hPlace = HWND_TOPMOST : tPtRight.x -= (RcGfx.right - RcGfx.left)
   'end if
   RcDesk.right += 10 'This can be acquired with GetSystemMetrics?
   var GfxWid = (RcGfx.right - RcGfx.left)
   if (tPtRight.x+GfxWid) >= RcDesk.right then 
      hPlace = HWND_TOPMOST : tPtRight.x = RcDesk.right-GfxWid
   end if
   'gfx.tOldPt.x = -65537
   SetWindowPos( g_GfxHwnd , hPlace , tPtRight.x-4 ,iYPos , 0,0 , SWP_NOSIZE or SWP_NOACTIVATE or ((g_Dock3D=0) and SWP_NOMOVE) )
   'NotifySelChange( wcEdit ) ??Why this was here??
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
   ShowWindow( g_hContainer , SW_HIDE )
   ResizeLayout( hWnd , g_tMainCtx.tForm , RcCli.right , RcCli.bottom )
   if g_hSearch then UpdateSearchWindowFont( g_tMainCtx.hFnt(wfStatus).HFONT )      
   MoveWindow( CTL(wcStatus) ,0,0 , 0,0 , TRUE )
   dim as long aWidths(2-1) = {RcCli.right*.85,-1}
   SendMessage( CTL(wcStatus) , SB_SETPARTS , 2 , cast(LPARAM,@aWidths(0)) )
   DockGfxWindow()   
   
   
end sub

static shared as any ptr OrgEditProc
function WndProcEdit ( hWnd as HWND, message as UINT, wParam as WPARAM, lParam as LPARAM ) as LRESULT   
   static as long iMod   

   select case message
   case WM_KEYDOWN      
      select case wParam
      case VK_SHIFT   : iMod or= FSHIFT
      case VK_MENU    : iMod or= FALT
      case VK_CONTROL : iMod or= FCONTROL
      case else
         var iResu = RichEdit_KeyPress( hWnd , wParam , iMod ) 
         if iResu then return iResu
      end select      
      if wParam=VK_ESCAPE then return CallWindowProc( OrgEditProc , hWnd , EM_SETSEL , -1 , 0 )
   case WM_KEYUP
      select case wParam
      case VK_SHIFT   : iMod and= (not FSHIFT)
      case VK_MENU    : iMod and= (not FALT)
      case VK_CONTROL : iMod and= (not FCONTROL)
      end select
   case WM_ACTIVATE
      iMod = 0
   case WM_CHAR
      select case wParam      
      case asc(" ")
         var sFix = "" : SearchAddPartSuffix( sFix , g_SQCtx )
         if len(sFix) then
            for N as long = 0 to len(sFix)
               PostMessage( hWnd , WM_CHAR , sFix[N] , 0 )
            next N         
         end if
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
   case WM_DRAWITEM   'item in a control is being drawn (owner draw)
      var wID = clng(wParam) , ptDrw = cast(LPDRAWITEMSTRUCT,lparam)
      select case wId
      case wcLines : Lines_Draw( CTL(wcEdit) , *ptDrw )
      end select
   
   case WM_TIMER
      dim as Matrix4x4 tMat
      tMat = g_tIdentityMatrix
      static as double dBeg : if dBeg = 0 then dBeg = timer
      MatrixRotateX( tMat , tMat , timer-dBeg )
      dim as zstring*256 zOutput = any
      with tMat
         sprintf(zOutput,!"1 %i %f %f %f %g %g %g %g %g %g %g %g %g %s\r\n",16,.fPosX,.fPosY,.fPosZ, _
            .m(0),.m(1),.m(2),.m(4),.m(5),.m(6),.m(8),.m(9),.m(10) , "3011.dat" )
      end with
      Viewer.LoadMemory( zOutput , "memory.ldr" )
   case WM_MENUSELECT 'track newest menu handle/item/state
      var iID = cuint(LOWORD(wParam)) , fuFlags = cuint(HIWORD(wParam)) , hMenu = cast(HMENU,lParam) 
      if hMenu then g_CurItemID = iID : g_hCurMenu = hMenu            
      return 0
   case WM_NOTIFY     'notification from window/control
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
   case WM_COMMAND    'Event happened to a control (child window)
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
               'printf(!"%p (%p) (%p)\n",GetFocus(),g_hContainer,CTL(wcEdit))
               'if GetForegroundWindow() <> g_hContainer then 
               var hFocus = GetFocus()
               if hFocus=0 orelse (hFocus <> g_hSearch andalso hFocus<>g_hContainer andalso hFocus <> CTL(wcEdit)) then
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
    
   case WM_SIZE       'window is sizing/was sized
      ResizeMainWindow()
      return 0
   case WM_MOVE       'window is moving/was moved
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
            DockGfxWindow()            
            SetWindowPos( g_GfxHwnd , HWND_TOPMOST , 0,0,0,0 , SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE)
            SetWindowPos( g_GfxHwnd , HWND_NOTOPMOST , 0,0,0,0 , SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE)
            'SetFocus( CTL(wcMain) )
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
   case WM_ENTERMENULOOP , WM_ENTERSIZEMOVE  
     ShowWindow( g_hContainer , SW_HIDE )
   case WM_CREATE  'Window was created
                  
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
      Menu.Trigger( meCompletion_Enable )
      Menu.Trigger( meView_ToggleGWDock )
      'Menu.Trigger( meCompletion_Variations )
      
      'SetWindowPos( g_hContainer , 0 , 0,0,100,100 , SWP_NOZORDER or SWP_SHOWWINDOW or SWP_NOMOVE )
      'ShowWindow( g_hContainer , SW_SHOW )
      ResizeMainWindow( true )    
      File_New()    
      'LoadFileIntoEditor( exePath+"\sample.ls" )
      SetForegroundWindow( ctl(wcMain) )
      SetFocus( ctl(wcEdit) )
      
      'SetTimer( hwnd , 1 , 100 , NULL )      
      
      return 0
          
   case WM_CLOSE   'close button was clicked
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
     
   dim as HWND hOldFocus = cast(HWND,-1)
   while( GetMessage( @tMsg, NULL, 0, 0 ) <> FALSE )    
      if TranslateAccelerator( hWnd , hAcceleratos , @tMsg ) then continue while      
      if IsDialogMessage( hWnd , @tMsg ) then continue while
      TranslateMessage( @tMsg )
      DispatchMessage( @tMsg )    
      ProcessMessage( tMsg )
      var hFocus = GetFocus()
      if hFocus <> hOldFocus then
         hOldFocus = hFocus
         if g_hContainer andalso g_hSearch then
            if hFocus=NULL orelse (hFocus <> g_hSearch andalso hFocus <> g_hContainer andalso hFocus <> CTL(wcEdit)) then
               ShowWindow( g_hContainer , SW_HIDE )
            end if
         end if
      end if
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
