namespace ColoredControl

  dim shared as hBitmap hBmAlpha
  dim shared as hDC hDcAlpha
  dim shared as CRITICAL_SECTION csColorize
  
  type ColoredContext
    pOrgProc  as any ptr
    ccColor   as COLORREF
    tRect     as RECT
    bLocked:1 as ubyte
    bLeft  :1 as ubyte
  end type
  
  sub Init() constructor
    dim as HDC hDC = GetDC(null)
    hDcAlpha  = CreateCompatibleDC(hDC)
    hBmAlpha = CreateBitmap(1,1,1,1,NULL)
    SelectObject( hDcAlpha  , hBmAlpha )
    ReleaseDC( 0 , hDC )
    InitializeCriticalSection( @csColorize )
  end sub
  
  function WndProc( hWnd as HWND, message as UINT, wParam as WPARAM, lParam as LPARAM ) as LRESULT
    
    #define _CallNext( _Parms... ) iif(IsWindowUnicode( hWnd ),CallWindowProcW( pOrgProc , hWnd , _Parms ),CallWindowProcA( .pOrgProc , hWnd , _Parms ))
    
    var pCtx = cptr(ColoredContext ptr, GetProp( hWnd , "cbCtx" ) )
    if pCtx=0 then return DefWindowProc( hWnd , message , wParam , lParam )
    with *pCtx
      var pOrgProc = .pOrgProc
        
      select case message      
      case WM_MOUSEMOVE
        if .bLocked then
          var xPos = cshort(LOWORD(lParam)) , yPos = cshort(HIWORD(lParam))  
          var bNewLeft = (cuint(xPos)>= .tRect.Right orelse cuint(yPos)>= .tRect.Bottom)
          if .bLeft <> bNewLeft then
            .bLeft = bNewLeft
            var iResu = _CallNext( message , wParam , lParam )
            InvalidateRect( hWnd , null , true )
          end if
        end if            
      case WM_ENABLE,WM_ACTIVATE,WM_LBUTTONDOWN,WM_LBUTTONUP,WM_KEYDOWN,WM_KEYUP 'force repaint when text change
        if message = WM_LBUTTONDOWN then .bLocked = 1 : .bLeft=0
        if message = WM_LBUTTONUP then .bLocked = 0
        var iResu = _CallNext( message , wParam , lParam )
        InvalidateRect( hWnd , null , true )    
      case WM_SIZE      'caches size for mouse movement
        GetClientRect( hWnd , @.tRect )
        InvalidateRect( hWnd , null , true )
      case WM_SETTEXT   'force repaint when text change
        'prevent paint right away when processing text change on control
        SendMessage( hWnd , WM_SETREDRAW , false , 0 )
        var iResu = _CallNext( message , wParam , lParam )
        SendMessage( hWnd , WM_SETREDRAW , true , 0 )
        'invalidate whole control now
        InvalidateRect( hWnd , null , true )
      case WM_PAINT     'backbuffer alpha paint and blit to screen
        
        EnterCriticalSection( @csColorize )
        dim as RECT rcCTL = any : GetClientRect( hWnd , @rcCTL )
        'bitmap of the size of the button
        dim as HDC hCtlDC = GetDC(0)      
        dim as HDC hDcBuffer = CreateCompatibleDC( hCtlDC )
        static as HBITMAP hBufBM
        if hBufBM = 0 then hBufBM = CreateCompatibleBitmap( hCtlDC , 2048 , 1024 )
        'dim as HBITMAP hBufBM = CreateCompatibleBitmap( hCtlDC , rcCTL.right , rcCTL.bottom )
        dim as HBITMAP hOldBM = SelectObject( hDcBuffer , hBufBM )      
        dim as PAINTSTRUCT tPaint = type( hDcBuffer )
        ReleaseDC( 0 , hCtlDC )
        
        'use HDC if it was passed... ignore otherwise
        if wParam=0 then BeginPaint( hwnd , @tPaint )      
        
        'call original WM_PAINT to make it paint
        var uResu = _CallNext( WM_ERASEBKGND , cast(..wParam,hDcBuffer) , lParam )
        
        var iDC = SaveDC( hDcBuffer )
        uResu = _CallNext( message , cast(..wParam,hDcBuffer) , lParam )
        hCtlDC = iif( wParam , cast(hDC,wParam) , tPaint.hDC )      
        RestoreDC( hDcBuffer , iDC )
        
        'blend scale a 1x1 bw image with 25% alpha on top of the button
        'since bw images use background/foreground colors we can set the color we want here
        dim as BLENDFUNCTION SRCBLEND = type(AC_SRC_OVER,0,64,0)                        
        SetTextColor( hDcAlpha , .ccColor )
        AlphaBlend( hDcBuffer , 0 , 0 , rcCTL.right , rcCTL.bottom , hDcAlpha , 0 , 0 , 1 , 1 , SRCBLEND )
        
        'blit to the screen
        BitBlt( hCtlDC , 0 , 0 , rcCTL.right , rcCTL.bottom , hDcBuffer , 0 , 0 , SRCCOPY )
        
        'delete the created bitmap
        SelectObject( hDcBuffer , hOldBM ) : 
        'DeleteObject( hBufBM )
        DeleteDC( hDcBuffer )       
        
        'if HDC was passed then dont call EndPaint
        if wParam=0 then EndPaint( hwnd , @tPaint )
        
        LeaveCriticalSection( @csColorize )
        return 0
    
      case WM_NCDESTROY
        RemoveProp( hWnd , "cbCtx" )
        free( pOrgProc )
      end select  
      
      return _CallNext( message , wParam , lParam )
      
    end with
    
  end function 
  
  sub Subclass( hWnd as HWND , pfnWndProc as any ptr , ccColor as COLORREF = 0 )
    var pCtx = cptr( ColoredContext ptr , calloc(sizeof(ColoredContext),1) )
    with *pCtx
      .ccColor = ccColor : GetClientRect( hWnd , @.tRect )
      .pOrgProc = cast(any ptr,GetWindowLongPtr( hWnd , GWLP_WNDPROC ))
    end with
    SetProp( hWnd , "cbCtx" , pCtx )    
    SetWindowLongPtr( hWnd , GWLP_WNDPROC , cast(LONG_PTR,pfnWndProc) )    
  end sub
  sub Colorize( hWnd as HWND , ccColor as COLORREF )
    var pCtx = cptr(ColoredContext ptr, GetProp( hWnd , "cbCtx" ) )
    if ccColor = 0 then ccColor = 1
    if pCtx then 
      pCtx->ccColor = ccColor      
    else      
      'SetWindowLong( hWnd , GWL_EXSTYLE , GetWindowLong( hWnd , GWL_EXSTYLE ) or WS_EX_TRANSPARENT ) 
      Subclass( hWnd , @WndProc , ccColor )
    end if
  end sub
  
end namespace

function FlickerFreeSubClass(hwnd as hwnd,msg as integer,wparam as wparam,lparam as lparam) as lresult    
  var pProc = GetPropA(hwnd,"OrgProc")
  
  #macro CheckFlick()    
    if cint(GetPropA(hwnd,"Redraw"))=false then
      return CallWindowProc(pProc,hwnd,msg,wparam,lparam)
    end if
    var hFlickDC = GetPropA(hwnd,"FlickDC")
    var hFlickBMP = GetPropA(hwnd,"FlickBMP")
    dim as Rect FlickRect = any
    GetClientRect(hwnd,@FlickRect)  
    if hFlickDC = 0 then    
      var TempDC = GetDC(hwnd)
      hFlickDC = CreateCompatibleDC(TempDC)
      hFlickBMP = CreateCompatibleBitmap(TempDC,FlickRect.right,FlickRect.bottom)    
      ReleaseDC(hwnd,TempDC)    
    else
      dim as size FlickSize = any
      GetBitmapDimensionEx(hFlickBMP,@FlickSize)
      if FlickSize.cx <> FlickRect.right or FlickSize.cy <> FlickRect.bottom then      
        var TempDC = GetDC(hwnd)
        DeleteObject(hFlickBMP) : DeleteObject(hFlickDC)
        hFlickDC = CreateCompatibleDC(TempDC)
        var hTempBMP = CreateCompatibleBitmap(TempDC,FlickRect.right,FlickRect.bottom)
        ReleaseDC(hwnd,TempDC) : hFlickBMP = hTempBMP      
      end if    
    end if
    SelectObject(hFlickDC,hFlickBMP)
    SetBitmapDimensionEx(hFlickBMP,FlickRect.right,FlickRect.bottom,null)    
    SetPropA(hwnd,"FlickDC",hFlickDC)
    SetPropA(hwnd,"FlickBMP",hFlickBMP)    
  #endmacro
  
  'printf(!"%lf\r",timer)
  
  select case msg  
  case WM_ERASEBKGND
    return true
    'if lparam <> -1 then return true
    'CheckFlick() 
    'return CallWindowProc(pProc,hwnd,msg,cuint(hFlickDC),lparam)
  case WM_LBUTTONDOWN
    if cint(GetProp(hwnd,"Redraw")) then 
      SendMessage( hwnd , WM_SETREDRAW , false , 0  )
    end if
  case WM_MOUSEMOVE           
    if cint(GetProp(hwnd,"Redraw"))=false then
      PostMessage( hwnd , WM_SETREDRAW , true , 0  )
      PostMessage( hwnd , WM_PAINT , 0,0 )
      PostMessage( hwnd , WM_SETREDRAW , false , 0  )
    end if
  case WM_LBUTTONUP    
    if cint(GetProp(hwnd,"Redraw"))=false then 
      SendMessage( hwnd , WM_SETREDRAW , true , 0  ) 
    end if
  case WM_PAINT    
    CheckFlick()    
    'SendMessage(hwnd,WM_ERASEBKGND,cuint(hFlickDC),-1)
    dim as PAINTSTRUCT tPaint        
    'BeginPaint( hwnd , @tPaint )    
    if GetUpdateRect( hwnd , @tPaint.rcPaint , false )=0 orelse IsRectEmpty(@tPaint.rcPaint) then
      tPaint.rcPaint.left = 0 : tPaint.rcPaint.right = FlickRect.right
      tPaint.rcPaint.top = 0 : tPaint.rcPaint.left = FlickRect.bottom
    end if
    CallWindowProc(pProc,hwnd,WM_ERASEBKGND,cast(wparam,hFlickDC),lparam)    
    var iResu = CallWindowProc(pProc,hwnd,msg,cast(wparam,hFlickDC),lparam)    
    tPaint.hDC = GetDC(hwnd)
    with tPaint.RcPaint      
      var hDC = cast(HDC,iif(wparam,cast(HDC,wparam),cast(HDC,tPaint.hDC)))
      'FillRect( hDC , @type<rect>(0,0,640,480), GetStockOBject(BLACK_BRUSH) )
      'BitBlt(hDC,0,0,FlickRect.Right,FlickRect.Bottom,hFlickDC,0,0,SRCCOPY)
      BitBlt(hDC,.Left,.top,.Right,.Bottom,hFlickDC,.Left,.Top,SRCCOPY)
    end with    
    ReleaseDC(hwnd,tPaint.hDC)
    'EndPaint( hwnd , @tPaint )
    ValidateRect(hwnd,null)
    return iResu
  case WM_NCDESTROY
    var hFlickDC = GetProp(hwnd,"FlickDC")
    var hFlickBMP = GetProp(hwnd,"FlickBMP")
    SetWindowLong(hwnd,GWL_WNDPROC,cuint(pProc))    
    RemoveProp(hwnd,"FlickDC")
    RemoveProp(hwnd,"FlickBMP")
    RemoveProp(hwnd,"OrgProc")
    RemoveProp(hwnd,"Redraw")
    if hFlickDC then
      DeleteObject(hFlickBMP)
      DeleteObject(hFlickDC)
    end if  
  case WM_SETREDRAW
    SetProp(hwnd,"Redraw",cast(any ptr,wparam))
  end select
  return CallWindowProc(pProc,hwnd,msg,wparam,lparam)
end function
sub SetDoubleBuffer(hwnd as hwnd)
  var OldProc = GetWindowLong(hwnd,GWL_WNDPROC)
  var NewProc = cuint(@FlickerFreeSubClass)
  if OldProc = 0 then exit sub
  if OldProc = NewProc then exit sub  
  SetProp(hwnd,"OrgProc",cast(any ptr,OldProc))
  SetProp(hwnd,"Redraw",cast(any ptr,1))
  'SendMessage(hwnd,WM_SETREDRAW,true,0)
  SetWindowLong(hwnd,GWL_WNDPROC,NewProc)
end sub


