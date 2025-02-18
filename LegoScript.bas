#include once "windows.bi"
#include once "win\commctrl.bi"
#include once "crt.bi"

#undef File_Open

'TODO (18/02/25): merge ViewModel into LegoSCript.bas

'*************** Enumerating our control id's ***********
enum WindowControls
  wcMain
  wcButton
  wcEdit
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

dim shared as hwnd CTL(wcLast-1)     'controls
dim shared as hinstance APPINSTANCE  'instance
dim shared as hfont MyFont(wfLast-1) 'fonts
dim shared as string sAppName        'AppName (window title 'prefix')
dim shared as HMENU g_WndMenu        'Main Menu handle
dim shared as long g_WndWid=640 , g_WndHei=480
dim shared g_hCurMenu as any ptr , g_CurItemID as long , g_CurItemState as long

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
'**************** Main Menu Layout **************
sub File_Open()
   print __FUNCTION__
end sub
sub File_Save()
   print __FUNCTION__
end sub
sub Edit_Undo()
   print __FUNCTION__
end sub
sub Edit_Copy()
   print __FUNCTION__
end sub
sub View_ToggleGW()
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
     _Entry( 10001 , "Open" , @File_Open )     
     _Entry() 'divisor
     _Entry( 10002 , "Save" , @File_Save )
     _Entry()
     _Entry( 10003 , "Quit" , @ExitProcess )
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

sub ResizeMainWindow( bCenter as boolean = false )
   'Calculate Client Area Size
   dim as rect RcWnd=any,RcCli=any,RcDesk=any
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
         var iCenterX = (RcDesk.right-.right)\2
         var iCenterY = (RcDesk.bottom-.bottom)\2        
         SetWindowPos(hwnd,null,iCenterX,iCenterY,.right,.bottom,SWP_NOZORDER)
         RcCli.right = g_WndWid : RcCli.bottom = g_WndHei
      end with 
   end if
   
   'recalculate control sizes based on window size
   MoveWindow( CTL(wcStatus) ,0,0 , 0,0 , TRUE )   
end sub

' *************** Procedure Function ****************
function WndProc ( hWnd as HWND, message as UINT, wParam as WPARAM, lParam as LPARAM ) as LRESULT
         
   select case( message )   
    
   case WM_CREATE 'Window was created
        
    if CTL(wcMain) then return 0
    CTL(wcMain) = hwnd
           
    'just a macro to help creating controls
    #define CreateControl( mID , mExStyle , mClass , mCaption , mStyle , mX , mY , mWid , mHei ) CTL(mID) = CreateWindowEx(mExStyle,mClass,mCaption,mStyle,mX,mY,mWid,mHei,hwnd,cast(hmenu,mID),APPINSTANCE,null)
    #define UpDn UPDOWN_CLASS
    
    const cStyle = WS_CHILD or WS_VISIBLE 'Standard style for buttons class controls :)    
    const cUpDnStyle = cStyle or UDS_AUTOBUDDY' or UDS_SETBUDDYINT  
    const cButtonStyle = cStyle  
    const cLabelStyle = cStyle
    const cStatStyle = cStyle or SBARS_SIZEGRIP
    
    const cTxtStyle =  cStyle or WS_VSCROLL or ES_MULTILINE
    const RichStyle = cStyle or ES_READONLY or ES_AUTOVSCROLL or WS_VSCROLL or ES_MULTILINE
    
    const cBrd = WS_EX_CLIENTEDGE
    
    ' **** Creating a Control ****
    CreateControl( wcButton , null , "button"        , "Click"        , cStyle      , 10 , 10 , 80 ,   24 )        
    CreateControl( wcEdit   , cBrd , "edit"          , "Hello World " , cTxtStyle   , 10 , 44 , 320 , 240 )
    CreateControl( wcStatus , null , STATUSCLASSNAME , "Status"       , cStatStyle  ,  0 ,  0 ,   0 ,   0 )
    
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
            puts("Button click!")
         end select
      end select      
      
      return 0
    
   case WM_SIZE      
      ResizeMainWindow()
      return 0
   case WM_CLOSE,WM_DESTROY 'Windows was closed/destroyed
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
