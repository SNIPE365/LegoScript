namespace ColoredControl

  dim shared as hBitmap hBmAlpha
  dim shared as hDC hDcAlpha
  dim shared as CRITICAL_SECTION csColorize
  
  sub Init() constructor
    dim as HDC hDC = GetDC(null)
    hDcAlpha  = CreateCompatibleDC(hDC)
    hBmAlpha = CreateBitmap(1,1,1,1,NULL)
    SelectObject( hDcAlpha  , hBmAlpha )
    ReleaseDC( 0 , hDC )
    InitializeCriticalSection( @csColorize )
  end sub
  function WndProc( hWnd as HWND, message as UINT, wParam as WPARAM, lParam as LPARAM ) as LRESULT
    
    var OrgProc = cast(any ptr,GetWindowLong(hWnd,GWL_USERDATA))
    
    select case message      
    case WM_ENABLE,WM_ACTIVATE 'force repaint when text change
      var iResu = CallWindowProc( OrgProc , hWnd , message , wParam , lParam )
      InvalidateRect( hWnd , null , true )    
    case WM_SETTEXT 'force repaint when text change
      'prevent paint right away when processing text change on control
      SendMessage( hWnd , WM_SETREDRAW , false , 0 )
      var iResu = CallWindowProc( OrgProc , hWnd , message , wParam , lParam )
      SendMessage( hWnd , WM_SETREDRAW , true , 0 )
      'invalidate whole control now
      InvalidateRect( hWnd , null , true )
    case WM_PAINT 'backbuffer alpha paint and blit to screen
      
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
      CallWindowProc( OrgProc , hWnd , WM_ERASEBKGND , cast(.wParam,hDcBuffer) , lParam )
      
      var iDC = SaveDC( hDcBuffer )
      CallWindowProc( OrgProc , hWnd , message , cast(.wParam,hDcBuffer) , lParam )
      hCtlDC = iif( wParam , cast(hDC,wParam) , tPaint.hDC )      
      RestoreDC( hDcBuffer , iDC )
      
      'blend scale a 1x1 bw image with 25% alpha on top of the button
      'since bw images use background/foreground colors we can set the color we want here
      dim as BLENDFUNCTION SRCBLEND = type(AC_SRC_OVER,0,64,0)                        
      SetTextColor( hDcAlpha , cast(COLORREF,GetProp(hWnd,"ccColor")) )
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
  
    end select  
    
    return CallWindowProc( OrgProc , hWnd , message , wParam , lParam )
    
  end function
  function WndProcW( hWnd as HWND, message as UINT, wParam as WPARAM, lParam as LPARAM ) as LRESULT
    
    var OrgProc = cast(any ptr,GetWindowLongW(hWnd,GWL_USERDATA))
    
    select case message      
    case WM_ENABLE,WM_ACTIVATE 'force repaint when text change
      var iResu = CallWindowProcW( OrgProc , hWnd , message , wParam , lParam )
      InvalidateRect( hWnd , null , true )    
    case WM_SETTEXT 'force repaint when text change
      'prevent paint right away when processing text change on control
      SendMessageW( hWnd , WM_SETREDRAW , false , 0 )
      var iResu = CallWindowProcW( OrgProc , hWnd , message , wParam , lParam )
      SendMessageW( hWnd , WM_SETREDRAW , true , 0 )
      'invalidate whole control now
      InvalidateRect( hWnd , null , true )
    case WM_PAINT 'backbuffer alpha paint and blit to screen
      
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
      CallWindowProcW( OrgProc , hWnd , WM_ERASEBKGND , cast(.wParam,hDcBuffer) , lParam )
      
      var iDC = SaveDC( hDcBuffer )
      CallWindowProcW( OrgProc , hWnd , message , cast(.wParam,hDcBuffer) , lParam )
      hCtlDC = iif( wParam , cast(hDC,wParam) , tPaint.hDC )      
      RestoreDC( hDcBuffer , iDC )
      
      'blend scale a 1x1 bw image with 25% alpha on top of the button
      'since bw images use background/foreground colors we can set the color we want here
      dim as BLENDFUNCTION SRCBLEND = type(AC_SRC_OVER,0,64,0)                        
      SetTextColor( hDcAlpha , cast(COLORREF,GetProp(hWnd,"ccColor")) )
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
  
    end select  
    
    return CallWindowProcW( OrgProc , hWnd , message , wParam , lParam )
    
  end function
  sub Subclass( hWnd as HWND , pfnWndProc as any ptr )
    if IsWindowUnicode( hWnd ) then
      SetWindowLongW( hWnd , GWL_USERDATA , SetWindowLongPtrW( hWnd , GWL_WNDPROC , cast(LONG_PTR,pfnWndProc) ) )
    else
      SetWindowLong( hWnd , GWL_USERDATA , SetWindowLongPtr( hWnd , GWL_WNDPROC , cast(LONG_PTR,pfnWndProc) ) )
    end if
  end sub
  sub Colorize( hWnd as HWND , uColor as COLORREF )
    if uColor = 0 then uColor = 1
    if GetProp( hWnd , "ccColor" ) then
      SetProp( hWnd , "ccColor" , cast(HANDLE, uColor) )
    else
      SetProp( hWnd , "ccColor" , cast(HANDLE, uColor) )    
      Subclass( hWnd , @WndProc )
    end if
  end sub  
  
  #if 0
  function WndProcW( hWnd as HWND, message as UINT, wParam as WPARAM, lParam as LPARAM ) as LRESULT
    
    var OrgProc = cast(any ptr,GetWindowLongW(hWnd,GWL_USERDATA))
    
    select case message      
    case WM_ENABLE,WM_ACTIVATE 'force repaint when text change
      var iResu = CallWindowProcW( OrgProc , hWnd , message , wParam , lParam )
      InvalidateRect( hWnd , null , true )    
    case WM_SETTEXT 'force repaint when text change
      'prevent paint right away when processing text change on control
      SendMessageW( hWnd , WM_SETREDRAW , false , 0 )
      var iResu = CallWindowProc( OrgProc , hWnd , message , wParam , lParam )
      SendMessageW( hWnd , WM_SETREDRAW , true , 0 )
      'invalidate whole control now
      InvalidateRect( hWnd , null , true )
    case WM_PAINT 'backbuffer alpha paint and blit to screen
      
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
      CallWindowProc( OrgProc , hWnd , WM_ERASEBKGND , cast(.wParam,hDcBuffer) , lParam )
      
      var iDC = SaveDC( hDcBuffer )
      CallWindowProc( OrgProc , hWnd , message , cast(.wParam,hDcBuffer) , lParam )
      hCtlDC = iif( wParam , cast(hDC,wParam) , tPaint.hDC )      
      RestoreDC( hDcBuffer , iDC )
      
      'blend scale a 1x1 bw image with 25% alpha on top of the button
      'since bw images use background/foreground colors we can set the color we want here
      dim as BLENDFUNCTION SRCBLEND = type(AC_SRC_OVER,0,64,0)                        
      SetTextColor( hDcAlpha , cast(COLORREF,GetProp(hWnd,"ccColor")) )
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
  
    end select  
    
    return CallWindowProc( OrgProc , hWnd , message , wParam , lParam )
    
  end function
  sub Subclass( hWnd as HWND , pfnWndProc as any ptr )
    SetWindowLong( hWnd , GWL_USERDATA , SetWindowLongPtr( hWnd , GWL_WNDPROC , cast(LONG_PTR,pfnWndProc) ) )
  end sub
  sub Colorize( hWnd as HWND , uColor as COLORREF )
    SetProp( hWnd , "ccColor" , cast(HANDLE, uColor) )    
    Subclass( hWnd , @WndProc )
  end sub  
  #endif
  
end namespace

