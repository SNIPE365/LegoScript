' ================= THIS FILE IS TO BE INCLUDED ON WindowProc =========================

'Create context (MUST be named FormContext and must contain hCTL and hFnt arrays)
'Class name MUST be named g_sFormClass
'wcMain is the first control (that is the window itself)

#ifndef pCtx
var pCtx = cast(FormContext ptr,GetWindowLongPtr(hWnd,0))
#endif
if pCtx=0 andalso message <> WM_CREATE then Return DefWindowProc( hWnd, message, wParam, lParam )  
#ifndef CTL
   #define CTL(_I) pCtx->hCTL(_I).hwnd
#endif

#ifndef FormContext
  #error " FormContext type with the window context must exist and declared as pCtx
#endif

#macro _InitForm()
  'if pCtx then return -1 
  'pCtx = AllocStruct(FormContext)
  if pCtx=0 then 
    dim as zstring*128 zCls = any : GetClassName(hwnd,@zCls,128)
    Errorf(!"Failed to allocate context for '%s'\n",zCls)
    return -1
  end if
  CTL(wcMain) = hwnd  
  with pCtx->tForm
    scope
      dim as RECT tRc = any : GetClientRect( hWnd , @tRc )
      .iCliWid = tRc.right : .iCliHei = tRc.bottom
      .iCtlCnt = wcLast             : .pCtl = @(pCtx->hCTL(0))      
      .iFntCnt = ubound(pCtx->hFnt) : .pFnt = @(pCtx->hFnt(0))
    end scope
  end with
  SetWindowLongPtr( hwnd , 0 , cast(LONG_PTR,pCtx) )  
#endmacro


'just a macro to help creating controls
#macro Control( _AW , _mID , _mExStyle , _mClass , _mCaption , _mStyle , _mX , _mY , _mWid , _mHei , _OrStyle... )   
  scope
    var p = @(pCtx->hCTL(_mID))
  'with pCtx->hCTL(_mID)
    #ifndef __LinkedCtx
    #define __LinkedCtx null
    #endif
    #ifndef __OrStyle
      #define __OrStyle_Remove
      #if #_OrStyle <> ""
        #define __OrStyle _OrStyle
      #else
        #define __OrStyle 0
      #endif
    #endif
    scope
      #ifndef _IncludeStyles
      const _IncludeStyles = WS_VISIBLE
      #endif      
      p->tX = _mX : p->tY = _mY : p->tW = _mWid : p->tH = _mHei          
      'p->iX = -10000 : p->iY = -10000 : p->iW = 1 : p->iH = 1
      p->iX = 0 : p->iY = 0 : p->iW = 100 : p->iH = 100
      'CalcLayout( g_Form , _mID )      
      p->hWnd = CreateWindowEx##_AW(_mExStyle,_mClass,_mCaption,_mStyle or _IncludeStyles or __OrStyle, _
      p->iX,p->iY,p->iW,p->iH,hwnd,iif((_mStyle) and WS_CHILD,cast(hmenu,_mID),0),g_AppInstance,__LinkedCtx)      
      if p->hWnd=0 then 
        var iErr = GetLastError()
        Debugf( !"Failed to create control %s error 0x%X\n",#_mID,iErr)      
      end if      
    end scope
    #ifdef IdPrevCtl
    IdPrevCtl = _mID
    #endif
    #undef __LinkedCtx
    #ifdef __OrStyle_Remove
      #undef __OrStyle_Remove
      #undef __OrStyle
    #endif    
  end scope
  'end with
#endmacro
#macro SetControl( _mID , _mX , _mY , _mWid , _mHei , _mhWnd )
  with pCtx->hCTL(_mID)
    scope                    
      .tX = _mX : .tY = _mY : .tW = _mWid : .tH = _mHei    
      if .iW = 0 then .iX = -10000 : .iY = -10000 : .iW = 1 : .iH = 1
      .hWnd = _mhWnd : if IsWindow(.hWnd)=0 then .hWnd=0
      'if .hWnd=0 then Debugf( !"Failed to create control %s\n",#_mID)
    end scope
    #ifdef IdPrevCtl
    IdPrevCtl = _mID
    #endif
  end with
#endmacro

#define ControlA( _P...) Control( A , _P )
#define ControlW( _mID , _mExStyle , _mClass , _mCaption , _P...) Control( W , _mID , _mExStyle , wstr(_mClass) , wstr(_mCaption) , _P )
#define UpDn UPDOWN_CLASS

const cStyle = WS_CHILD 'Standard style for buttons class controls :)    
const cStyleT = cStyle or WS_TABSTOP
const cUpDnStyle = cStyleT or UDS_AUTOBUDDY' or UDS_SETBUDDYINT  
const cButtonStyle = cStyleT or BS_NOTIFY
const cListStyle = cStyleT or LBS_NOTIFY or LBS_NOINTEGRALHEIGHT
const cCheckStyle = cStyleT or BS_AUTOCHECKBOX or BS_NOTIFY
const cBtnChkStyle = cCheckStyle	or BS_PUSHLIKE
const cRadioStyle = cStyleT or BS_AUTORADIOBUTTON or BS_NOTIFY
const cBtnRadStyle = cRadioStyle or BS_PUSHLIKE
const cLabelStyle = cStyle or SS_RIGHT
const cTextStyle = cStyle
const cSplitStyle = cStyleT
const cComboStyle = cStyleT or CBS_DROPDOWN or CBS_NOINTEGRALHEIGHT or WS_VSCROLL'or CBS_AUTOHSCROLL 
const cDropStyle = cStyleT or CBS_DROPDOWNLIST or CBS_NOINTEGRALHEIGHT or CBS_AUTOHSCROLL
const cSearchStyle = cStyleT or CBS_SIMPLE or CBS_NOINTEGRALHEIGHT or CBS_AUTOHSCROLL
const cFieldStyle = cStyleT or ES_AUTOHSCROLL
const cFNumbStyle = cStyleT or ES_AUTOHSCROLL or ES_NUMBER
const cEditStyle =  cStyleT or WS_VSCROLL or ES_MULTILINE or ES_WANTRETURN
const cFrameStyle = cStyleT or BS_GROUPBOX
const cInfoStyle = cFieldStyle or ES_READONLY
const cTreeStyle = cStyleT or TVS_HASLINES or TVS_SINGLEEXPAND or TVS_HASBUTTONS
const cTabsStyle = cStyleT 'or TCS_MULTILINE
const cReportStyle = cStyleT or LVS_REPORT or LVS_SHOWSELALWAYS
const cCalStyle = cStyleT 'or MCS_NOTODAY
const cDateSTyle = cStyleT or DTS_SHORTDATECENTURYFORMAT 
const cRichStyle = cStyleT or ES_MULTILINE or ES_WANTRETURN
const cStatStyle = cStyle or SBARS_SIZEGRIP

const cBrd = WS_EX_CLIENTEDGE , cDlg = cBrd or WS_EX_WINDOWEDGE
const cTrn = WS_EX_TRANSPARENT
const cLay = WS_EX_TRANSPARENT

': SetLayeredWindowAttributes( pCtx->hCTL(_ID).hWnd , 0,254,LWA_ALPHA )
#define AddButtonA(_ID , _X , _Y , _W , _H , _T , _S...) ControlA( _ID , cLay , "button"    , _T , cButtonStyle, _X , _Y , _W , _H , _S )
#define AddButtonAT(_ID , _X , _Y , _W , _H , _T , _S...) ControlA( _ID , cTrn , "button"    , _T , cButtonStyle, _X , _Y , _W , _H , _S )
#define AddButtonW(_ID , _X , _Y , _W , _H , _T , _S...) ControlW( _ID , cLay , "button"    , _T , cButtonStyle, _X , _Y , _W , _H , _S )
#define AddButtonWT(_ID , _X , _Y , _W , _H , _T , _S...) ControlW( _ID , cTrn , "button"    , _T , cButtonStyle, _X , _Y , _W , _H , _S )
#define AddBtChkA( _ID , _X , _Y , _W , _H , _T , _S...) ControlA( _ID , null , "button"    , _T , cBtnChkStyle, _X , _Y , _W , _H , _S )
#define AddBtChkW( _ID , _X , _Y , _W , _H , _T , _S...) ControlW( _ID , null , "button"    , _T , cBtnChkStyle, _X , _Y , _W , _H , _S )
#define AddBtRadA( _ID , _X , _Y , _W , _H , _T , _S...) ControlA( _ID , null , "button"    , _T , cBtnRadStyle, _X , _Y , _W , _H , _S )
#define AddBtRadW( _ID , _X , _Y , _W , _H , _T , _S...) ControlW( _ID , null , "button"    , _T , cBtnRadStyle, _X , _Y , _W , _H , _S )
#define AddCheckA( _ID , _X , _Y , _W , _H , _T , _S...) ControlA( _ID , null , "button"    , _T , cCheckStyle , _X , _Y , _W , _H , _S )
#define AddCheckW( _ID , _X , _Y , _W , _H , _T , _S...) ControlW( _ID , null , "button"    , _T , cCheckStyle , _X , _Y , _W , _H , _S )
#define AddComboA( _ID , _X , _Y , _W , _H , _H2 , _S... ) pCtx->hCTL(_ID).tH2 = _H2 : ControlA( _ID , null , "combobox" ,null, cComboStyle , _X , _Y , _W , _H , _S )
#define AddComboW( _ID , _X , _Y , _W , _H , _H2 , _S... ) pCtx->hCTL(_ID).tH2 = _H2 : ControlW( _ID , null , "combobox" ,null, cComboStyle , _X , _Y , _W , _H , _S )
#define AddDayPick(_ID , _X , _Y , _W , _H , _S...)      ControlA( _ID , cBrd,MONTHCAL_CLASS,null, cCalStyle   , _X , _Y , _W , _H , _S )
#define AddDatePick(_ID , _X , _Y , _W , _H , _S...)     ControlA( _ID , cBrd,DATETIMEPICK_CLASS,null, cDateStyle   , _X , _Y , _W , _H , _S )
#define AddDropA(  _ID , _X , _Y , _W , _H , _H2 , _S... ) pCtx->hCTL(_ID).tH2 = _H2 : ControlA( _ID , null , "combobox" ,null, cDropStyle  , _X , _Y , _W , _H , _S )
#define AddDropW(  _ID , _X , _Y , _W , _H , _H2 , _S... ) pCtx->hCTL(_ID).tH2 = _H2 : ControlW( _ID , null , "combobox" ,null, cDropStyle  , _X , _Y , _W , _H , _S )
#define AddSearchA(  _ID , _X , _Y , _W , _H , _S... ) ControlA( _ID , null , "combobox" ,null, cSearchStyle  , _X , _Y , _W , _H , _S )
#define AddSearchW(  _ID , _X , _Y , _W , _H , _S... ) ControlW( _ID , null , "combobox" ,null, cSearchStyle  , _X , _Y , _W , _H , _S )
#define AddEditA(  _ID , _X , _Y , _W , _H , _T , _S... ) ControlA( _ID , cBrd , "edit"      , _T , cEditStyle  , _X , _Y , _W , _H , _S )
#define AddEditW(  _ID , _X , _Y , _W , _H , _T , _S...) ControlW( _ID , cBrd , "edit"      , _T , cEditStyle  , _X , _Y , _W , _H , _S )
#define AddFieldA( _ID , _X , _Y , _W , _H , _T , _S...) ControlA( _ID , cBrd , "edit"      , _T , cFieldStyle , _X , _Y , _W , _H , _S )
#define AddFieldW( _ID , _X , _Y , _W , _H , _T , _S...) ControlW( _ID , cBrd , "edit"      , _T , cFieldStyle , _X , _Y , _W , _H , _S )
#define AddFNumbA( _ID , _X , _Y , _W , _H , _T , _S...) ControlA( _ID , cBrd , "edit"      , _T , cFNumbStyle , _X , _Y , _W , _H , _S )
#define AddFrameA( _ID , _X , _Y , _W , _H , _T , _S...) ControlA( _ID , cTrn , "button"    , _T , cFrameStyle , _X , _Y , _W , _H , _S )
#define AddFrameW( _ID , _X , _Y , _W , _H , _T , _S...) ControlW( _ID , cTrn , "button"    , _T , cFrameStyle , _X , _Y , _W , _H , _S )
#define AddInfoA(  _ID , _X , _Y , _W , _H , _T , _S...) ControlA( _ID , cBrd , "edit"      , _T , cInfoStyle , _X , _Y , _W , _H , _S )
#define AddInfoW(  _ID , _X , _Y , _W , _H , _T , _S...) ControlW( _ID , cBrd , "edit"      , _T , cInfoStyle , _X , _Y , _W , _H , _S )
#define AddLabelA( _ID , _X , _Y , _W , _H , _T , _S...) ControlA( _ID , null , "static"    , _T , cLabelStyle , _X , _Y , _W , _H , _S )
#define AddLabelW( _ID , _X , _Y , _W , _H , _T , _S...) ControlW( _ID , null , "static"    , _T , cLabelStyle , _X , _Y , _W , _H , _S )
#define AddTextA(  _ID , _X , _Y , _W , _H , _T , _S...) ControlA( _ID , null , "static"    , _T , cTextStyle , _X , _Y , _W , _H , _S )
#define AddTextW(  _ID , _X , _Y , _W , _H , _T , _S...) ControlW( _ID , null , "static"    , _T , cTextStyle , _X , _Y , _W , _H , _S )
#define AddListA(  _ID , _X , _Y , _W , _H , _S...)      ControlA( _ID , cBrd , "listbox"   ,null, cListStyle  , _X , _Y , _W , _H , _S )
#define AddListW(  _ID , _X , _Y , _W , _H , _S...)      ControlW( _ID , cBrd , "listbox"   ,null, cListStyle  , _X , _Y , _W , _H , _S )
#define AddRadioA( _ID , _X , _Y , _W , _H , _T , _S...) ControlA( _ID , null , "button"    , _T , cRadioStyle , _X , _Y , _W , _H , _S )
#define AddRadioW( _ID , _X , _Y , _W , _H , _T , _S...) ControlW( _ID , null , "button"    , _T , cRadioStyle , _X , _Y , _W , _H , _S )
#define AddReportA(_ID , _X , _Y , _W , _H , _S...)      ControlA( _ID , cBrd , WC_LISTVIEW ,null, cReportStyle, _X , _Y , _W , _H , _S )
#define AddReportW(_ID , _X , _Y , _W , _H , _S...)      ControlW( _ID , cBrd , WC_LISTVIEW ,null, cReportStyle, _X , _Y , _W , _H , _S )
#define AddTreeA(  _ID , _X , _Y , _W , _H , _S...)      ControlA( _ID , null ,WC_TREEVIEW  ,null, cTreeStyle  , _X , _Y , _W , _H , _S )
#define AddTreeW(  _ID , _X , _Y , _W , _H , _S...)      ControlW( _ID , null ,WC_TREEVIEW  ,null, cTreeStyle  , _X , _Y , _W , _H , _S )
#define AddRichA(  _ID , _X , _Y , _W , _H , _T , _S...) ControlA( _ID , cBrd , "RICHEDIT20W"  , _T , cRichStyle  , _X , _Y , _W , _H , _S )
#define AddRichW(  _ID , _X , _Y , _W , _H , _T , _S...) ControlW( _ID , cBrd , "RICHEDIT20W"  , _T , cRichStyle  , _X , _Y , _W , _H , _S )
#define AddStatusA( _ID , _T , _S... )                   ControlA( _ID , null ,STATUSCLASSNAME,_T, cStatStyle , _num(0),_num(0) , _num(0),_num(0) , _S )
#define AddStatusW( _ID , _T , _S... )                   ControlW( _ID , null ,STATUSCLASSNAME,_T, cStatStyle , _num(0),_num(0) , _num(0),_num(0) , _S )
#define AddTabsA(  _ID , _X , _Y , _W , _H , _H2 , _S...) pCtx->hCTL(_ID).tH2 = _H2 : ControlA( _ID , null ,WC_TABCONTROL,null, cTabsStyle  , _X , _Y , _W , _H , _S )
#define AddTabsW(  _ID , _X , _Y , _W , _H , _H2 , _S...) pCtx->hCTL(_ID).tH2 = _H2 : ControlW( _ID , null ,WC_TABCONTROL,null, cTabsStyle  , _X , _Y , _W , _H , _S )
#define AddSplitter( _ID , _X , _Y , _W , _H , _S... ) ControlA( _ID , 0 , "splitter" , null , cSplitStyle , _X , _Y , _W , _H , _S )

#macro AddCtlA(   _ID , _X , _Y , _W , _H , _N , _S , _E , _P ) 
  #define __LinkedCtx _P
  ControlA( _ID , _E , _N ,null, _S          , _X , _Y , _W , _H )  
#endmacro
#macro AddCtlW(   _ID , _X , _Y , _W , _H , _N , _S , _E , _P )
  #define __LinkedCtx _P
  ControlW( _ID , _E , _N ,null, _S          , _X , _Y , _W , _H , _P )  
#endmacro
#define DelControl( _ID ) DestroyWindow( CTL(_ID) ):CTL(_ID) = 0
