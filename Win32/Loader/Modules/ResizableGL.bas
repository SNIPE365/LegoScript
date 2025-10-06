#include once "windows.bi"
#include once "win\mmsystem.bi"
#include once "crt.bi"
#include once "fbgfx.bi"

#undef HWND_TOPMOST
#undef HWND_NOTOPMOST
#define HWND_TOPMOST cast(handle, -1)
#define HWND_NOTOPMOST cast(handle, -2)
#define GfxResize

extern GfxWin32(290) alias "fb_win32" as any ptr

namespace gfx
  dim shared as long lOrgFbProc,lOldStyle,lScreenFlags
  dim shared as integer g_iScrWid,g_iScrHei,g_lFirstSize,g_iAspect,g_iOffLeft,g_iOffTop
  dim shared as integer g_iCliWid,g_iCliHei
  dim shared as byte g_Temp,g_Fullscreen
  dim shared as string g_sGfxDriver
  dim shared as COLORREF g_BorderColor 
  dim shared as point tOldPt = type(-9999,9999)
      
  declare sub Resize(iWid as integer=0,iHei as integer=0,iCenter as integer=1,iResizable as integer=0)  
  
  private function FbSubClass(hwnd as hwnd,iMsg as integer,wparam as wparam,lparam as lparam) as lresult
    select case iMsg
    case WM_NCCALCSIZE
      if wParam then        
        var iResu = DefWindowProc(hWnd,iMsg,wParam,lParam)                        
        with *cptr(NCCALCSIZE_PARAMS ptr,lParam)          
          .rgrc(0).left  += g_iOffLeft : .rgrc(0).top    += iif(lScreenFlags and fb.GFX_OPENGL,0,g_iOffTop)
          .rgrc(0).right -= g_iOffLeft : .rgrc(0).bottom -= g_iOffTop                  
          'if (lScreenFlags and fb.GFX_OPENGL) then            
          '  var iWndWid = .rgrc(1).right-.rgrc(1).left, iWndHei = .rgrc(1).bottom-.rgrc(0).top
          '  var iCliWid = .rgrc(2).right-.rgrc(2).left, iCliHei = .rgrc(2).bottom-.rgrc(3).top
          '  g_iCliWid = iCliWid
          'end if
        end with        
        return iResu
      end if
    case WM_SIZING       
       with *cptr(RECT ptr,lParam)
          if (.right-.left) < 64 then .right = .left+64
          if (.bottom-.top) < 48 then .bottom = .top+48
       end with
       return DefWindowProc(hwnd,imsg,wparam,lparam)      
    case WM_SIZE
      if (lScreenFlags and fb.GFX_OPENGL) then
        dim as RECT tRc : GetClientRect(hWnd,@tRc)
        if g_iCliWid <> tRc.right orelse g_iCliHei <> tRc.bottom then
          g_iCliWid = tRc.right : g_iCliHei = tRc.bottom                  
          #if __Main = "LegoScript"          
          if CTL(wcMain) andalso IsWindowVisible(CTL(wcMain)) then 
             'puts("size")
             SendMessage( CTL(wcMain) , WM_USER+1 , 0,0 )
          end if
          #endif        
        end if
      end if
      return DefWindowProc(hwnd,imsg,wparam,lparam)
    case WM_MOVING,WM_MOVE      
      #if __Main = "LegoScript"        
        dim as point tNewPt : ClientToScreen( hwnd , @tNewPt )
        if tOldPt.x <> tNewPt.x orelse tOldPt.y <> tNewPt.y then           
           'var bForced = (tOldPt.x = -65537) : tOldPt = tNewPt           
           if CTL(wcMain) andalso IsWindowVisible(CTL(wcMain)) then 
              'puts("moving")              
              PostMessage( CTL(wcMain) , WM_USER+2 , 0,0 )
           end if
        end if
      #endif
      DefWindowProc(hwnd,imsg,wparam,lparam)
    case WM_SETCURSOR      
      return DefWindowProc(hwnd,imsg,wparam,lparam)
    case WM_LBUTTONUP,WM_LBUTTONDOWN,WM_RBUTTONUP,WM_RBUTTONDOWN,WM_MBUTTONUP,WM_MBUTTONDOWN
      var xPos = cshort(LOWORD(lParam)),yPos = cshort(HIWORD(lParam))
      dim as rect fbcli = any: GetClientRect(hwnd,@fbcli)            
      xPos = cshort((xPos*g_iScrWid)\fbcli.Right)
      yPos = cshort((yPos*g_iScrHei)\fbcli.Bottom)      
      lParam = MAKELONG(cushort(xPos),cushort(yPos))
    case WM_LBUTTONDBLCLK,WM_RBUTTONDBLCLK,WM_MBUTTONDBLCLK
      var xPos = cshort(LOWORD(lParam)),yPos = cshort(HIWORD(lParam))
      dim as rect fbcli = any: GetClientRect(hwnd,@fbcli)            
      xPos = cshort((xPos*g_iScrWid)\fbcli.Right)
      yPos = cshort((yPos*g_iScrHei)\fbcli.Bottom)      
      lParam = MAKELONG(cushort(xPos),cushort(yPos))
    case WM_MOUSEMOVE      
      var xPos = cshort(LOWORD(lParam)),yPos = cshort(HIWORD(lParam))      
      dim as rect fbcli = any: GetClientRect(hwnd,@fbcli)            
      xPos = cshort((xPos*g_iScrWid)\fbcli.Right)
      yPos = cshort((yPos*g_iScrHei)\fbcli.Bottom)
      lParam = MAKELONG(cushort(xPos),cushort(yPos))      
    case WM_NCHITTEST,WM_NCMOUSEMOVE,12,174,32            
      return DefWindowProc(hwnd,imsg,wparam,lparam)    
    case WM_GETMINMAXINFO
      return DefWindowProc(hwnd,imsg,wparam,lparam)    
    case WM_USER+90
      if lOldStyle then                                            
        g_Fullscreen = 0
        g_iOffLeft = 0 : g_iOffTop=0
        ShowWindow( hwnd , SW_RESTORE )        
        SetWindowLong( hwnd , GWL_STYLE , lOldStyle ) : lOldStyle = 0
        SetWindowPos( hwnd , HWND_NOTOPMOST , 0 , 0 , 0 , 0 , SWP_NOMOVE or SWP_NOSIZE or SWP_FRAMECHANGED)                
      else        
        g_Fullscreen = 1
        var iDeskWid = GetSystemMetrics(SM_CXSCREEN), iDeskHei = GetSystemMetrics(SM_CYSCREEN)        
        if g_iAspect then
          screeninfo g_iScrWid,g_iScrHei
          dim as long iWid,iHei
          iHei=iDeskHei : iWid=(iHei*g_iScrWid)\g_iScrHei
          if iWid>iDeskWid then
            iWid=iDeskWid : iHei=(iWid*g_iScrHei)\g_iScrWid
          end if
          g_iOffLeft = (iDeskWid-iWid)\2 : g_iOffTop = (iDeskHei-iHei)\2      
        else
          g_iOffLeft = 0 : g_iOffTop = 0
        end if
        lOldStyle = GetWindowLong( hwnd , GWL_STYLE ) or WS_VISIBLE
        SetWindowLong( hwnd , GWL_STYLE , WS_POPUP or WS_VISIBLE)
        ShowWindow( hwnd , SW_MAXIMIZE )
        SetWindowPos( hwnd , HWND_TOPMOST , 0 , 0 , 0 , 0 , SWP_NOMOVE or SWP_NOSIZE or SWP_FRAMECHANGED)        
        if g_iOffLeft orelse g_iOffTop then
          RedrawWindow( hwnd , NULL , NULL , RDW_FRAME or RDW_INVALIDATE or RDW_NOERASE	or RDW_UPDATENOW or RDW_NOCHILDREN ) 	
        end if
        
      end if      
    'case WM_CREATE
      'puts("WM_CREATE!")
      'const NOTVIS = (not (WS_VISIBLE or WS_MAXIMIZEBOX or WS_MINIMIZEBOX))
      'const CANRES = WS_THICKFRAME
      'const BETRANS = WS_EX_TRANSPARENT
      'const NOTASK = WS_EX_TOOLWINDOW
    case else
      'printf "%i(%x) ",iMsg,iMsg
      'return DefWindowProc(hwnd,imsg,wparam,lparam)
    end select
    if g_Temp then return DefWindowProc(hwnd,imsg,wparam,lparam)      
    return CallWindowProc(cast(any ptr,lOrgFbProc),hwnd,iMsg,wparam,lparam)
  end function
  sub Resize(iWid as integer=0,iHei as integer=0,iAspect as integer=1,iResizable as integer=0)    
    static fbWnd as hwnd, fbrct as rect, fbcli as rect
    static iDeskWid as integer,iDeskHei as integer    
    dim as hwnd newWnd
    Screencontrol(fb.get_window_handle,*cast(ulong ptr,@newWnd))      
    screeninfo g_iScrWid,g_iScrHei
    if newWnd<>fbWnd then
      fbWnd = newWnd
      lOrgFbProc = SetWindowLong(fbWnd,GWL_WNDPROC,clng(@FbSubClass))                    
    end if   
        
    var iStyle   = GetWindowLong(fbwnd,GWL_STYLE)
    if iResizable then iStyle or= WS_SIZEBOX else iStyle and= (not WS_THICKFRAME)    
    g_temp=1
    SetWindowLong(fbWnd,GWL_STYLE,iStyle)        
    SetWindowPos(fbWnd,0,0,0,0,0,SWP_NOSIZE or SWP_FRAMECHANGED or SWP_NOZORDER or SWP_NOMOVE)
    g_temp=0
    
    iDeskWid = GetSystemMetrics(SM_CXSCREEN)
    iDeskHei = GetSystemMetrics(SM_CYSCREEN)
    GetWindowRect(fbwnd,@fbrct)
    GetClientRect(fbwnd,@fbcli)
    
    var iSx = ((fbrct.right-fbrct.left)-(fbcli.right-fbcli.left))
    var iSy = ((fbrct.bottom-fbrct.top)-(fbcli.bottom-fbcli.top))
    var iWid2 = iWid+iSx , iHei2 = iHei+iSy    
    var iFlags = SWP_SHOWWINDOW or SWP_NOZORDER or SWP_FRAMECHANGED
    
    dim as long iLeft,iTop             
    if iWid<=0 orelse iHei<=0 then 
      iFlags and= (not SWP_NOZORDER)
      if iWid=0 then iWid2 = iDeskWid': iLeft=0
      if iHei=0 then iHei2 = iDeskHei': iTop=0
      if iWid<0 andalso iHei>=0 then
        iWid2=iSx+(((iHei2-iSy)*g_iScrWid)\g_iScrHei)      
      elseif iHei<0 andalso iWid>=0 then
        iHei2=iSy+(((iWid2-iSx)*g_iScrHei)\g_iScrWid)        
      end if      
    end if       
    
    if 1 then iLeft = (iDeskWid-iWid2)\2 : iTop = (iDeskHei-iHei2)\2      
    g_iAspect = iAspect : g_iOffLeft = 0 : g_iOffTop=0 : lOldStyle=0
        
    SetWindowPos(fbWnd,HWND_TOPMOST,iLeft,iTop,iWid2,iHei2,iFlags)
    'end if
    
    if g_Fullscreen=0 andalso g_lFirstSize andalso (lScreenFlags and fb.gfx_fullscreen) then
      SendMessage(fbWnd,WM_USER+90,0,0)
    end if
    
  end sub
      
end namespace

#define BeforeScreenRes PreResize

sub _screenres(iWid as long,iHei as long,depth as long=8,num_pages as long=1,flags as long=0,refresh_rate as long=0)  
  'if gfx.PreDetour then
    gfx.lScreenflags = flags : gfx.g_lFirstSize = 1 : gfx.g_BorderColor = 0 : gfx.g_Fullscreen = 0
    Flags = (flags and (not fb.gfx_fullscreen)) or fb.gfx_No_Switch
  'else
  '  gfx.lScreenflags=0
  'end if
  gfx.g_iCliWid = 0: gfx.g_iCliHei=0   
  if (flags and fb.gfx_shaped_window) then screencontrol(fb.SET_DRIVER_NAME,"GDI")    
  screenres iWid,iHei,depth,num_pages,flags,refresh_rate  
  if (flags and fb.gfx_shaped_window) then screencontrol(fb.SET_DRIVER_NAME,"")    
  screencontrol(fb.GET_DRIVER_NAME,gfx.g_sGfxDriver)
end sub
#undef screenres
#define screenres _screenres

#define _UNUSED -32768
function _SetMouse( x As long = _UNUSED, y As long = _UNUSED, visibility As long = _UNUSED, clip As long = _UNUSED ) As long
  dim as HWND gfxWnd : Screencontrol(fb.get_window_handle,*cast(uinteger ptr,@gfxWnd))      
  if gfxWnd=0 then return 1
  dim as RECT tRC = any : GetClientRect(gfxWnd,@tRC)  
  if x<>_UNUSED andalso y <> _UNUSED then     
    if cuint(x)>=gfx.g_iScrWid orelse cuint(y)>=gfx.g_iScrHei then return 1
    dim as POINT tPT = ( (x*((tRC.right)-0))\gfx.g_iScrWid , (y*((tRC.bottom)-0))\gfx.g_iScrHei )
    ClientToScreen(gfxWnd,@tPT) : SetCursorPos( tPT.x , tPT.y )
  end if  
  if visibility <> _UNUSED then SetMouse ,,abs(visibility)
  if clip <> _UNUSED then 
    ClientToScreen(gfxWnd,cast(point ptr,@tRC))
    ClientToScreen(gfxWnd,cast(point ptr,@tRC)+1)
    if clip then ClipCursor(@tRC) else ClipCursor(NULL)
  end if
end function
#undef setmouse
#define setmouse _setmouse
  

