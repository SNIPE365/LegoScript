
if CTL(wcMain) then return 0
_InitForm()

var hEventGfxReady = CreateEvent( NULL , FALSE , FALSE , NULL )    
g_hResizeEvent = CreateEvent( NULL , FALSE , FALSE , NULL )
g_ViewerThread = ThreadCreate( @Viewer.MainThread , hEventGfxReady )

InitFont( wfDefault , g_sMainFont   , 12 ) 'default application font
InitFont( wfStatus  , g_sMainFont   , 10 ) 'status bar font
InitFont( wfSmall   , g_sMainFont  ,  8 )
InitFont( wfEdit    , g_sFixedFont  , 16 ) 'edit controls font
InitFont( wfArrows  , g_sArrowFont  , 12 )

#define cLeftSide _RtN( wcSideSplit , 0 )

AddButtonA (wcBtnClose  , _pct(10)  , _num(0) , _pct(3)  , cEm(1.1) , !"\x72" )
AddTabsA   ( wcTabs      , _Num(0)   , cMarginT  , _Rtp(-1,-10) , cEm(1.25) , cRow(1.25) , WS_CLIPSIBLINGS )

AddButtonA ( wcButton    , _NextCol  , _SameRow  , cMarginR , cRow(1.25) , "Build" )
AddTabsA   ( wcSidePanel , _Num(0)   , _NextRow0  , _Num(1) , cEm(2) , cEm(2) ) ', TBSTYLE_WRAPABLE )
'search combo controls in the side panel
AddFieldA( wcSearchEdit , _Num(0)  , _NextRow0 , _NextCol0 , cEm(1.2) , 0 )
AddFieldA( wcFilterEdit , _Num(0)  , _NextRow0 , _NextCol0 , cEm(1.2) , 0 )
AddListW ( wcSearchList , _SameCol , _NextRow0 , _NextCol0 , _BottomE(-1.15) , LBS_NOTIFY or WS_VSCROLL )

AddSplitter( wcSideSplit , _Rtn(wcSidePanel,0) , _SameRow  , _pct(0.5)  , _NextRow0 )

'editor
AddRichA   ( wcLines     , cLeftSide , _TpN(wcSidePanel,0)  , _pct(1.9*(2+1)) , _BtP(wcEdit,-3.5) ,  "" , WS_DISABLED or ES_RIGHT ) 'SS_OWNERDRAW )
AddRichA   ( wcEdit      , _NextCol0 , _SameRow  , cMarginR , _pct(53) , "" , WS_HSCROLL or WS_VSCROLL or ES_AUTOHSCROLL or ES_DISABLENOSCROLL or ES_NOHIDESEL )
AddSplitter( wcOutSplit  , _SameCol  , _NextRow0 , _NextCol0, _pct(1) )
'output panel
'AddButtonA ( wcRadOutput , _RtN(wcLines,0) , _SameRow  , _pct(11) , cEm(1.1) , "Output" , WS_GROUP or BS_AUTORADIOBUTTON or BS_PUSHLIKE )
AddButtonA ( wcRadOutput , _RtP( wcSideSplit , 1 ) , _NextRow0  , _pct(11) , cEm(1.1) , "Output" , WS_GROUP or BS_AUTORADIOBUTTON or BS_PUSHLIKE )
AddButtonA ( wcRadQuery  , _NextCol0 , _SameRow  , _pct(9)  , cEm(1.1) , "Query"  , BS_AUTORADIOBUTTON or BS_PUSHLIKE )
AddButtonA ( wcBtnExec   , _NextCol3 , _SameRow  , _pct(12) , cEm(1.1) , "Execute" , WS_GROUP )
AddButtonA ( wcBtnLoad   , _NextCol  , _SameRow  , _pct(8)  , cEm(1.1) , "Load"  )
AddButtonA ( wcBtnSave   , _NextCol  , _SameRow  , _pct(8)  , cEm(1.1) , "Save" )
AddButtonA ( wcBtnDec    , _NextCol3 , _SameRow  , _pct(5)  , cEm(1.1) , "--" , WS_DISABLED or BS_NOTIFY )
AddButtonA ( wcBtnInc    , _NextCol0 , _SameRow  , _pct(5)  , cEm(1.1) , "++" , WS_DISABLED or BS_NOTIFY )
AddEditA   ( wcOutput    , cLeftSide , _NextRow  , cMarginR , _BottomE(-1.15) , "" , WS_HSCROLL or WS_VSCROLL or ES_AUTOHSCROLL or ES_READONLY )
AddEditA   ( wcQuery     , cLeftSide , _SameRow  , cMarginR , _BottomE(-1.15) , "" , WS_HSCROLL or WS_VSCROLL or ES_AUTOHSCROLL )
AddButtonA( wcBtnSide  , _LtN( wcRadOutput,0) , _BtP(wcEdit,-3.5) , _pct(4) , _pct(3.5) , !"\x34" , BS_AUTOCHECKBOX or BS_PUSHLIKE ) '_RtP(wcSidePanel,-4)
AddButtonA( wcBtnMinOut , _RightP(-4)         , _BtP(wcEdit,-3.5) , _pct(4) , _pct(3.5) , !"\x36" , BS_AUTOCHECKBOX or BS_PUSHLIKE )
AddStatusA ( wcStatus    , "Ready." )
'SetParent( CTL(wcBtnMinOut) , CTL(wcOutput) )
Setparent( CTL(wcBtnClose) , CTL(wcTabs) )

SetControlsFont( wfEdit   , wcLines , wcEdit , wcOutput )
SetControlsFont( wfStatus , wcStatus )
SetControlsFont( wfArrows , wcBtnMinOut , wcBtnSide , wcBtnClose )

SetWindowTheme( CTL(wcEdit) , "" , "" )
SetWindowTheme( CTL(wcOutput) , "" , "" )
SetWindowTheme( CTL(wcQuery) , "" , "" )
SendMessage( CTL(wcEdit) , EM_EXLIMITTEXT , 0 , 16*1024*1024 ) '16mb text limit
SendMessage( CTL(wcEdit) , EM_SETEVENTMASK , 0 , ENM_CLIPFORMAT or ENM_SELCHANGE or ENM_KEYEVENTS) ' or ENM_SCROLL )
OrgEditProc  = cast(any ptr,SetWindowLongPtr( CTL(wcEdit)  , GWLP_WNDPROC , cast(LONG_PTR,@WndProcEdit) ) )
OrgLinesProc = cast(any ptr,SetWindowLongPtr( CTL(wcLines) , GWLP_WNDPROC , cast(LONG_PTR,@WndProcLines)) )
OrgTabsProc  = cast(any ptr,SetWindowLongPtr( CTL(wcTabs)  , GWLP_WNDPROC , cast(LONG_PTR,@WndProcTabs) ) )

dim as long lTop(...) = { wcBtnClose , wcBtnSide , wcBtnMinOut }
for N as long = 0 to ubound(lTop)
  SetWindowPos( CTL(lTop(N)) , HWND_TOPMOST , 0,0,0,0 , SWP_NOMOVE or SWP_NOSIZE )
  SetWindowPos( CTL(lTop(N)) , HWND_TOP , 0,0,0,0 , SWP_NOMOVE or SWP_NOSIZE )
next N

dim as TC_ITEM tItem = type( TCIF_TEXT or TCIF_PARAM , 0,0 , @"Unnamed" , 0,-1 , 0 ) 
with g_tTabs(0)
   TabCtrl_InsertItem( CTL(wcTabs) , 0 , @tItem )
   .hEdit = CTL(wcEdit) : .sFilename = "" 
end with
static as zstring ptr pzPanels(...) = {@"Project",@"Parts Bin",@"Solution"}
for N as long = 0 to ubound(pzPanels)
  tItem.pszText = pzPanels(N)
  TabCtrl_InsertItem( CTL(wcSidePanel) , N , @tItem )
next N
TabCtrl_SetCurSel( CTL(wcSidePanel) , 1 )


SetControlsFont( wfStatus, wcTabs )
SetControlsFont( wfSmall , wcSidePanel )

#ifdef SearchIsInPanel
  InitSearchWindow( CTL(wcSearchList) )
#else
  InitSearchWindow( )
#endif

ColoredControl.Colorize( CTL(wcRadOutput) , &HFF8844 )
ColoredControl.Colorize( CTL(wcRadQuery)  , &HFF8844 )
ColoredControl.Colorize( CTL(wcBtnExec)   , &H4488FF )
ColoredControl.Colorize( CTL(wcBtnLoad)   , &HFF0000 )
ColoredControl.Colorize( CTL(wcBtnSave)   , &H0000FF )
ColoredControl.Colorize( CTL(wcBtnInc)    , &H006600 )
ColoredControl.Colorize( CTL(wcBtnDec)    , &H000066 )
ColoredControl.Colorize( CTL(wcBtnMinOut) , &H00FF00 )
ColoredControl.Colorize( CTL(wcBtnSide)   , &H00FF00 )
ColoredControl.Colorize( CTL(wcButton)    , &H00FF00 )
ColoredControl.Colorize( CTL(wcBtnClose)  , &H0000FF )
SetDoubleBuffer( CTL(wcOutput) )
SetDoubleBuffer( CTL(wcQuery) )
'ColoredControl.Colorize( CTL(wcOutput)    , &HFFF0F0 )
'ColoredControl.Colorize( CTL(wcQuery)     , &HFF8888 )

WaitForSingleObject( hEventGfxReady , INFINITE )    
CloseHandle( hEventGfxReady )

'var hParent = GetParent( CTL(wcQuery) )
'ShowWindow(CTL(wcQuery),SW_HIDE)
'CTL(wcQuery) = g_GfxHwnd
'SetParent( g_GfxHwnd , hParent )

if g_GfxHwnd = 0 then return -1 'failed

'SetWindowPos( g_hContainer , 0 , 0,0,100,100 , SWP_NOZORDER or SWP_SHOWWINDOW or SWP_NOMOVE )
'ShowWindow( g_hContainer , SW_SHOW )
'puts "IniWid: " & g_tCfg.lGuiWid : puts "IniHei: " & g_tCfg.lGuiHei
ResizeMainWindow( true )

'SendMessage( CTL(wcRadQuery) , BM_CLICK , 0,0 )
'SendMessage( CTL(wcRadOutput) , BM_CLICK , 0,0 )
PostMessage( CTL(wcBtnMinOut) , BM_CLICK , 0,0 )

File_New()    
'LoadFileIntoEditor( exePath+"\sample.ls" )
SetForegroundWindow( ctl(wcMain) )
SetFocus( ctl(wcEdit) )
ChangeToTab( 0 )

'Menu.Trigger( meCompletion_Enable )
'Menu.Trigger( meView_ToggleGWDock )
'Menu.Trigger( meCompletion_Variations )

#define CallSetupFunction( _Varname , _Function , _Parms... ) _Function( _Parms )
#macro CheckSetupFunction( _Varname , _Section , _VarType , _Default , _SetupFunction... )
  #if len(#_SetupFunction)
    #define _cfgVarName ._VarName
    CallSetupFunction( _Varname , _SetupFunction )
    #undef _cfgVarName
  #endif
#endmacro
with g_tCfg  
  ForEachSetting( CheckSetupFunction )
end with

'SetTimer( hwnd , 1 , 100 , NULL )
