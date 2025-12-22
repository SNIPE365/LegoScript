#if 0
   #define _u2w(_zstr) scope : dim as wstring*g_MaxQueryLen _zstr##_w = any : Utf8ToWide( _zstr , zstr##_w )
   declare function Utf8ToWide( pzStr as zstring ptr , pwOutput as wstring ptr , iLen as long = -1 , byref iOutLen as long = 0 ) as wstring ptr  
   declare function WideToUtf8( pwStr as wstring ptr , pzOutput as zstring ptr , iLen as long = -1 , byref iOutSz as long = 0 ) as zstring ptr
   function SendMessageU( hWnd as hwnd , uMsg as uinteger , wParam as WPARAM , lParamU as zstring ptr ) as LRESULT
     dim as wstring*g_MaxQueryLen pwTemp = any 
     Utf8ToWide( lParamU , pwTemp )
     return SendMessageW( hWnd , uMsg , wParam , cast(LPARAM, @pwTemp) )
   end function
#endif

#define _u_() end scope
#define ComboBox_AddString( _hCtl , _pzText )                SendMessage( _hCtl , CB_ADDSTRING , 0 , cast(LPARAM,cptr(zstring ptr,_pzText)) )
#define ComboBox_AddStringW( _hCtl , _pwText )               SendMessageW( _hCtl , CB_ADDSTRING , 0 , cast(LPARAM,cptr(wstring ptr,_pwText)) )
#define ComboBox_AddStringU( _hCtl , _sText )                SendMessageU( _hCtl , CB_ADDSTRING , 0 , _sText )
#define ComboBox_DeleteString( _hCtl , _Index)               SendMessage( _hCtl , CB_DELETESTRING , _Index , 0 )
#define ComboBox_FindStringExact( _hCtl , _Start , _Text )   SendMessage( _hCtl , CB_FINDSTRINGEXACT , _Start , cptr(LPARAM,cptr(zstring ptr,_Text)) )
#define ComboBox_FindStringExactW( _hCtl , _Start , _TextW ) SendMessageW( _hCtl , CB_FINDSTRINGEXACT , _Start , cptr(LPARAM,cptr(wstring ptr,_TextW)) )
#define ComboBox_FindStringExactU( _hCtl , _Start , _TextU ) SendMessageU( _hCtl , CB_FINDSTRINGEXACT , _Start , _TextU )
#define ComboBox_GetCurSel( _hCtl )                          SendMessage( _hCtl , CB_GETCURSEL , 0 , 0 )
#define ComboBox_GetDroppedState( _hCtl )                    SendMessage( _hCtl , CB_GETDROPPEDSTATE , 0 , 0 )
#define ComboBox_GetLBText( _hCtl , _Index , _pzBuffer)      SendMessage( _hCtl , CB_GETLBTEXT , _Index , cast(LPARAM,cptr(zstring ptr,_pzBuffer)) )
#define ComboBox_GetLBTextW( _hCtl , _Index , _pwBuffer)     SendMessageW( _hCtl , CB_GETLBTEXT, _Index , cast(LPARAM,cptr(wstring ptr,_pwBuffer)) )
#define ComboBox_GetInfo( _hCtl , _ptInfo )                  SendMessage( _hCtl , CB_GETCOMBOBOXINFO , 0 , cast(LPARAM,cptr(COMBOBOXINFO ptr,_ptInfo)) )
#define ComboBox_GetText( _hCtl , _pzBuffer , _iMaxLen )     GetWindowText( _hCtl , _pzBuffer , _iMaxLen )
#define ComboBox_GetTextLen( _hCtl )                         GetWindowTextLength( _hCtl )
#define ComboBox_GetTextW( _hCtl , _pwBuffer , _iMaxLen )    GetWindowTextW( _hCtl , _pwBuffer , _iMaxLen )
#define ComboBox_GetTextU( _hCtl , _puBuffer , _iMaxLen )    GetWindowTextU( _hCtl , _pwBuffer , _iMaxLen )
#define ComboBox_ResetContent( _hCtl )                       SendMessage( _hCtl , CB_RESETCONTENT , 0 , 0 )
#define ComboBox_SetEditSel( _hCtl , _Start , _End )         SendMessage( _hCtl , CB_SETEDITSEL , 0 , MAKELPARAM( _Start , _End ) )
#define ComboBox_GetCount( _hCtl )                           SendMessage( _hCtl , CB_GETCOUNT , 0 , 0 )
#define ComboBox_SetCurSel( _hCtl , _Index )                 SendMessage( _hCtl , CB_SETCURSEL , _Index , 0 )
#define ComboBox_SetItemData( _hCtl , _Index , _Data )       SendMessage( _hCtl , CB_SETITEMDATA , _Index , _Data )
#define ComboBox_SetItemHeight( _hCtl , _Index , _Hei )      SendMessage( _hCtl , CB_SETITEMHEIGHT, _Index , _Hei )
#define ComboBox_SetText( _hCtl , _pzBuffer )                SetWindowText( _hCtl , _pzBuffer )
#define ComboBox_SetTextW( _hCtl , _pwBuffer )               SetWindowTextW( _hCtl , _pwBuffer )
#define ComboBox_SetTextU( _hCtl , _sText )                  SetWindowTextU8( _hCtl , _sText )

#define ListView_InsertItemW( _hCtl , _pItem )               SendMessageW( _hCtl , LVM_INSERTITEMW , 0 , cast(LPARAM,_pItem) )
#define ListView_SetItemW( _hCtl , _pItem )                  SendMessageW( _hCtl , LVM_SETITEMW , 0 , cast(LPARAM,_pItem) )

#define Button_GetCheck( _hCtl )                             SendMessage( _hCtl , BM_GETCHECK , 0 , 0 )
#define Button_SetCheck( _hCtl , _State )                    SendMessage( _hCtl , BM_SETCHECK , _State , 0 )
#define BUtton_Click( _hCtl )                                SendMessage( _hCtl , BM_CLICK    , 0 , 0 )

#define Control_GetFont( _hCTL )                             cast(HFONT,SendMessage( _hCTL , WM_GETFONT , 0 , 0 ))
#define COntrol_SetFont( _hCTL , _hFont , _bRedraw )         SendMessage( _hCTL , WM_SETFONT , cast(WPARAM,_hFont) , _bRedraw )

enum LayoutType
  ltPosX
  ltPosY
  ltWid
  ltHei
end enum
type ControlUnit
  wRelID:14 as ushort
  bIsPct:1  as ushort
  bIsEnd:1  as ushort
  wOffset   as short
end type

type FontStruct
  as HFONT  hFont
  as string sName
  as ubyte  bCurWid , bCurHei
  as ubyte  bSize
  as byte   bBOld  :1
  as byte   bItalic:1
end type

'type ControlStruct as ControlStruct ptr
type FormStruct_Fwd as FormStruct
type ControlStruct_Fwd as ControlStruct

type ControlAfterSizeCallback as sub ( pForm as FormStruct_Fwd , pCtl as ControlStruct_Fwd )
type ControlEventCallback as function ( pForm as FormStruct_Fwd , pCtl as ControlStruct_Fwd , pMsg as MSG ) as LRESULT

type ControlStruct
  as HWND        hwnd
  cbAfterSize    as ControlAfterSizeCallback
  cbEvent        as ControlEventCallback
  pData          as any ptr
  as ControlUnit tX,tY,tW,tH,tH2
  as short       iX,iY,iW,iH,iH2
  as byte        bFont, bResize
end type

type FormStruct
  as long iCliWid,iCliHei
  as long iCtlCnt,iFntCnt
  as ControlStruct ptr pCtl
  as FontStruct    ptr pFnt
end type

'generic form context pointer
'type FormContext as any ptr

'unit is in percent (relative to parent size)
#define _pct( _off ) type( 0 , true  , false , cshort((_off)*128) )
'unit is numeric (pixels)
#define _num( _off ) type( 0 , false  , false , _off )
'position/size is relative to left/top of a control
#define _LtN( _ID , _off ) type( _ID , false , false , _off )
#define _TpN _LtN
#define _LtP( _ID , _off ) type( _ID , true  , false , cshort((_off)*128) )
#define _TpP _LtP
#define _RtN( _ID , _off ) type( _ID , false , true  , _off )
#define _BtN _RtN
#define _RtP( _ID , _off ) type( _ID , true  , true  , cshort((_off)*128) )
#define _BtP _RtP
'position at the center of another control
#define _MidN( _ID , _off ) type( _ID , false , null , -32768 )
#define _MidP( _ID , _off ) type( _ID , true , null , -32768 )
'position is relative to parent the window
#define _RightN( _off ) _RtN( -1 , _off )
#define _BottomN( _off ) _BtN( -1 , _off )
#define _RightP( _P... ) _RtP( -1 , _P )
#define _BottomP( _P... ) _BtP( -1 , _P )

#define cEm(_N) _num(4096+cint((_N)*100))
#define _BottomE(_Off) _BtN(-1, 4096+cint((_Off)*100))
#define _BtE(_ID,_Off) _BtN(_ID,4096+cint((_Off)*100))

const _SWP_Flags = SWP_NOZORDER or SWP_NOACTIVATE or SWP_NOCOPYBITS
function ControlUpdateLayout( byref tForm as FormStruct , iCtl as long , bResize as WINBOOL ) as byte
  const cFromEdges = (1 shl 14)-1  
  const cFromCenter = -32768
  with tForm.pCtl[iCtl]
    
    'if iCtl = wcSidePanel then puts("--------------------")
    dim as long iOX=.iX , iOY=.IY , iOW=.iW , iOH=.iH
    
    var wOffset = .tX.wOffset : .iX = 0    
    if .tX.wRelID=cFromEdges then 
      .iX = iif(.tX.bIsEnd , tForm.iCliWid , 0 )
    elseif .tX.wRelID then
      var pRel = tForm.pCtl+.tX.wRelID
      if wOffset = cFromCenter then
        wOffset = 0 : .iX = pRel->iX+((pRel->iW-.iW)\2)
      else
        .iX = pRel->iX + iif(.tX.bIsEnd , pRel->iW , 0 )    
      end if
    end if
    .iX += iif( .tX.bIsPct , (wOffset*tForm.iCliWid)\(128*100) , wOffset )
    
    .iY = 0
    if .tY.wRelID=cFromEdges then 
      .iY = iif(.tY.bIsEnd , tForm.iCliHei , 0 ) 
    elseif .tY.wRelID then
      var pRel = tForm.pCtl+.tY.wRelID
      .iY = pRel->iY + iif(.tY.bIsEnd , pRel->iH , 0 )
    end if
    .iY += iif( .tY.bIsPct , (.tY.wOffset*tForm.iCliHei)\(128*100) , .tY.wOffset )
    
    .iW = 0
    if .tW.wRelID=cFromEdges then 
      .iW = iif(.tW.bIsEnd , tForm.iCliWid , 0 )-.iX
    elseif .tW.wRelID then
      var pRel = tForm.pCtl+.tW.wRelID
      .iW = (pRel->iX + iif(.tW.bIsEnd , pRel->iW , 0 ))-.iX
    end if
    .iW += iif( .tW.bIsPct , (.tW.wOffset*tForm.iCliWid)\(128*100) , .tW.wOffset )
    if .iW < 0 then .iW = -.iW : .iX -= .iW
    
    .iH = 0
    if .tH.wRelID=cFromEdges then 
      .iH = iif(.tH.bIsEnd , tForm.iCliHei , 0 )-.iY
    elseif .tH.wRelID then
      var pRel = tForm.pCtl+.tH.wRelID
      .iH = (pRel->iY + iif(.tH.bIsEnd , pRel->iH , 0 ))-.iY
    end if
    
    if iCtl = wcSidePanel then
      'printf(!"id=%i pct=%i , offset=%i\n",.tH.wRelID,.th.bIsPct,.tH.wOffset)
    end if
    
    if .th.bIsPct=0 andalso .tH.wOffset >= 2048 then
      var iFontHei = (tForm.pFnt[.bFont].bCurHei*(.tH.wOffset-4096))\100      
      .iH += iFontHei      
    else
      .iH += iif( .tH.bIsPct , (.tH.wOffset*tForm.iCliHei)\(128*100) , .tH.wOffset )
    end if
    
    'special height for controls like combobox
    .iH2 = 0
    if .tH2.wRelID=cFromEdges then 
      .iH2 = iif(.tH2.bIsEnd , tForm.iCliHei , 0 )-.iY
    elseif .tH2.wRelID then
      var pRel = tForm.pCtl+.tH2.wRelID
      .iH2 = (pRel->iY + iif(.tH2.bIsEnd , pRel->iH , 0 ))-.iY
    end if
    .iH2 += iif( .tH2.bIsPct , (.tH2.wOffset*tForm.iCliHei)\(128*100) , .tH2.wOffset )
    
    'if iCtl = wcSidePanel then puts("--------------------")
    
    'print .iX,.iY,.iW,.iH    
    if iOX<>.iX orelse iOY<>.IY orelse iOW=.iW orelse iOH<>.iH then
      if bResize then SetWindowPos(.hwnd,0,.iX,.iY,.iW,iif(.iH2,.iH2,.iH),_SWP_Flags)
      return true      
    end if
    return false
    
  end with
end function
sub ResizeLayout( hWnd as HWND , tForm as FormStruct , iWidth as long , iHeight as long )
  
  'dim as double dTMR = timer
  
  with tForm
    .iCliWid = iWidth : .iCliHei = iHeight    
    var iSzH = (.iCliWid*9)\16
    if .iCliHei < iSzH then iSzH = .iCliHei
    if iSzH < 1 then iSzH = 1
  
    ' **** Re-creating fonts ****
    var hDC = GetDC(hWnd) 
    var iLogY = GetDeviceCaps(hDC, LOGPIXELSY) , iDPI = (360*72)\iSzH '360
    var hOrgFont = GetCurrentObject( hDC , OBJ_FONT )
    
    dim as HFONT hOldFont(.iFntCnt-1)
    for N as integer = 0 to .iFntCnt-1
      with .pFnt[N]
        hOldFont(N) = .hFont
        var nHeight = -MulDiv(.bSize, iLogY, iDPI) 'calculate size matching DPI
        var cWeight = iif(.bBold, FW_BOLD , FW_NORMAL ) 
        const cQuality = DRAFT_QUALITY or ANTIALIASED_QUALITY        
        .hFont = CreateFont(nHeight,0,0,0,cWeight,.bItalic,0,0,DEFAULT_CHARSET,0,0,cQuality,0,.sName)    
        dim as size tSz = any
        SelectObject( hDC , .hFont )
        GetTextExtentPoint32( hDC , "_W^" , 3 , @tSz )
        .bCurWid = (tSz.cx\3) : .bCurHei = tSz.cy
      end with
    next N
    
    ' **** Setting this font for all controls ****
    for N as integer = 0 to .iCtlCnt-1      
      var hCurFont = .pFnt[cint(.pCtl[N].bFont)].hFont , hCtl = .pCtl[N].hwnd
      if hCtl = 0 then continue for
      'if N then SendMessage( hCtl , WM_SETREDRAW , false , 0 )
      if hCtl then 
         #ifdef g_bChangingFont
            g_bChangingFont = true
         #endif
         SendMessage( hCtl , WM_SETFONT,cast(wparam, hCurFont),false )
         #ifdef g_bChangingFont
            g_bChangingFont = false
         #endif
      end if
    next N
    
    SelectObject( hDC , hOrgFont )
    ReleaseDC( hWnd , hDC )
    for N as integer = 0 to .iFntCnt-1
      if hOldFont(N) then DeleteObject(hOldFont(N)):hOldFont(N)=0
    next N
  end with
  
  'InvalidateRect( hwnd , null , true )
  'UpdateWindow( hwnd )
  
  var Old = GetWindowLong(hWnd,GWL_EXSTYLE)
  SetWindowLong( hWnd , GWL_EXSTYLE , Old or WS_EX_COMPOSITED )
  
  var hResize = BeginDeferWindowPos(tForm.iCtlCnt)
  for R as long = 0 to 1
    var hCtl = GetWindow(hWnd,GW_CHILD)        
    do
      var N = GetDlgCtrlID( hCtl )
      if N andalso N <> wcBtnClose then
         with tForm.pCtl[N]
          if .hwnd then
            if R=0 then .bResize=0
            .bResize or= ControlUpdateLayout( tForm , N, false )           
            if R andalso .bResize then DeferWindowPos(hResize,.hwnd,0,.iX,.iY,.iW,iif(.iH2,.iH2,.iH),_SWP_Flags)        
          end if
         end with
      end if
      hCtl = GetWindow( hCtl , GW_HWNDNEXT )
    loop while hCtl
  next R
  EndDeferWindowPos( hResize )
  
  ''const rFlags = RDW_ERASE or RDW_FRAME or RDW_INTERNALPAINT or RDW_INVALIDATE or RDW_UPDATENOW or RDW_ALLCHILDREN 
  ''RedrawWindow(hWnd, NULL , NULL , rFlags )
  'UpdateWindow(hWnd)
  'InvalidateRect(hWnd,null,true)
  
  UpdateWindow( hWnd )
  SetWindowLong( hWnd , GWL_EXSTYLE , Old )        
  
  'print cint((timer-dTMR)*1000)
  
end sub
#undef _SWP_Flags
sub LayoutFreeResources( tForm as FormStruct )
  with tForm            
    for N as integer = 0 to .iFntCnt-1
      with .pFnt[N]
        if .hFont then DeleteObject(.hFont):.hFont=NULL        
      end with
    next N
  end with
end sub
sub _SetFont( byref hFnt as FontStruct , sName as string , iSize as ubyte , bBold as byte = 0 , bItalic as byte = 0 )
  with hFnt
    .sName = sName : .bSize = iSize : .bBold = bBold : .bItalic = bItalic
  end with
end sub

#define InitFont( _ID , _Name , _Size_Bold_Italic... ) _SetFont( pCtx->hFnt(_ID) , _Name , _Size_Bold_Italic )
#ifndef CTL
#define CTL(_I) pCtx->hCTL(_I).hwnd
#endif


#if 0
   '#define v_first(_last) va_first()
   '#define v_arg(_p , _t) va_arg(_p,_t)
   '#define v_next(_p) va_next(_p,_t)
#else
   #define v_first(_last) cast(any ptr,@_last+1)
   #define v_arg(_p , _t) *cptr( _t ptr , (_p) )
   #define v_next(_p , _t) cast(any ptr,_p)+sizeof(_t)
#endif

'set fonts to multiple controls
sub _SetControlsFont cdecl ( pCtl as ControlStruct ptr , bFont as long , iCount as long , ... )   
  
   dim args as Cva_List
   Cva_Start( args, iCount )
   For i as long = 1 To iCount
     var iID = Cva_Arg(args, long)
     pCtl[iID].bFont = bFont
   Next
   Cva_End( args )
   
end sub
#define SetControlsFont( _Font , _IDs... ) _SetControlsFont( @(pCtx->hCtl(0)) , _Font , __FB_ARG_COUNT__( _IDs) , _IDs )
'set color callback to multiple controls (WM_CTLCOLOR*)
sub _SetControlsEventCallback cdecl ( pCtl as ControlStruct ptr , pCb as ControlEventCallback , ... ) 
  var p = v_first(pCb)
  do
    var iID = v_arg(p,long)
    if iID < 0 then exit do
    pCtl[iID].cbEvent = pCb
    p = v_next(p,long)
  loop
end sub
#define SetControlsEventCallback( _Callback , _IDs... ) _SetControlsEventCallback( @(pCtx->hCtl(0)) , _Callback , _IDs , -1 )

'set after size callback to multiple controls (for special resize?)
sub _SetControlsAfterSize cdecl ( pCtl as ControlStruct ptr , pCb as ControlAfterSizeCallback , ... )   
  var p = v_first(pCb)
  do
    var iID = v_arg(p,long)
    if iID < 0 then exit do
    pCtl[iID].cbAfterSize = pCb
    p = v_next(p,long)
  loop
end sub

#define SetControlsAfterSize( _Callback , _IDs... ) _SetControlsAfterSize( @(pCtx->hCtl(0)) , _Callback , _IDs , -1 )

sub _ShowHideControlRange( pCtl as ControlStruct ptr , iShow as long , iBegin as long , iEnd as long )
  const cShowFlags = SWP_NOSIZE or SWP_NOMOVE or SWP_NOZORDER or SWP_NOACTIVATE
  var hDefer = BeginDeferWindowPos( (iEnd-iBegin)+1 )
  for N as integer = iBegin to iEnd
    if iShow then
      DeferWindowPos( hDefer , pCtl[N].hWnd , 0,0,0,0,0, cShowFlags or SWP_SHOWWINDOW ) 
    else
      DeferWindowPos( hDefer , pCtl[N].hWnd , 0,0,0,0,0, cShowFlags or SWP_HIDEWINDOW )       
    end if
  next N
  EndDeferWindowPos( hDefer )
end sub
#define ShowControlRange( _Begin , _End ) _ShowHideControlRange( @(pCtx->hCtl(0)) , TRUE  , _Begin , _End )
#define HideControlRange( _Begin , _End ) _ShowHideControlRange( @(pCtx->hCtl(0)) , FALSE , _Begin , _End )

sub _InvalidateControlArea( pCtl0 as any ptr , iCtl as long )
  var pCtl = cast(ControlStruct ptr,pCtl0)
  if pCtl[iCtl].hWnd andalso pCtl[0].hWnd then    
    dim as RECT tRc = any : GetClientRect( pCtl[iCtl].hWnd , @tRC )    
    MapWindowPoints( pCtl[iCtl].hWnd , pCtl[0].hWnd , cast(POINT ptr,@tRc) , 2 )    
    InvalidateRect( pCtl[0].hWnd , @tRc , true )    
  end if  
end sub
#define InvalidateControlArea( _Ctl ) _InvalidateControlArea( @(pCtx->hCtl(0)) , _Ctl )

function DefFormProc( tForm as FormStruct , hwnd as HWND , message as UINT , wParam as WPARAM , lParam as LPARAM ) as LRESULT
  select case as const message  
  case WM_CTLCOLORBTN,WM_CTLCOLORDLG,WM_CTLCOLOREDIT,WM_CTLCOLORLISTBOX,WM_CTLCOLORMSGBOX,WM_CTLCOLORSCROLLBAR,WM_CTLCOLORSTATIC
    var iID = GetDlgCtrlID(cast(HWND,lParam))
    if cuint(iID) < tForm.iCtlCnt then
      with tForm.pCtl[iID]
        if .cbEvent then 
          var dwResu = .cbEvent( tForm , tForm.pCtl[iID] , type<MSG>(hwnd,message,wParam,lParam) )
          if dwResu then return dwResu
        end if
      end with
    end if
    'return cast(LRESULT,GetStockObject(BLACK_BRUSH))
  case WM_NOTIFY
    var iID = cptr(NMHDR ptr,lParam)->idFrom
    if cuint(iID) < tForm.iCtlCnt then
      with tForm.pCtl[iID]
        if .cbEvent then return .cbEvent( tForm , tForm.pCtl[iID] , type<MSG>(hwnd,message,wParam,lParam) )
      end with
    end if
  case WM_COMMAND
    var iID = cint(LOWORD(wParam))
    if cuint(iID) < tForm.iCtlCnt then
      with tForm.pCtl[iID]
        if .cbEvent then return .cbEvent( tForm , tForm.pCtl[iID] , type<MSG>(hwnd,message,wParam,lParam) )
      end with
    end if
  case WM_SIZE  
    if lParam = 0 then
      dim as RECT tRc = any : GetClientRect( hWnd , @tRc )
      lParam = MAKELPARAM( tRc.right , tRc.bottom )
    end if
    ResizeLayout( hWnd ,tForm , LOWORD(lParam) , HIWORD(lParam) )
    'return 0
  case WM_ERASEBKGND,WM_NCPAINT',WM_PAINT
    'return 0
  end select
  return DefWindowProc( hWnd, message, wParam, lParam )
end function