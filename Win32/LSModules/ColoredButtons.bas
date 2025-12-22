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

