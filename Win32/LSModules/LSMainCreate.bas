if CTL(wcMain) then return 0
_InitForm()

var hEventGfxReady = CreateEvent( NULL , FALSE , FALSE , NULL )    
g_hResizeEvent = CreateEvent( NULL , FALSE , FALSE , NULL )
g_ViewerThread = ThreadCreate( @Viewer.MainThread , hEventGfxReady )

InitFont( wfDefault , g_sMainFont   , 12 ) 'default application font
InitFont( wfStatus  , g_sMainFont   , 10 )  'status bar font
InitFont( wfEdit    , g_sFixedFont  , 16 ) 'edit controls font
InitFont( wfArrows  , g_sArrowFont  , 12 )

AddButtonAT(wcBtnClose  , _pct(10)  , _pct(2) , _pct(3)  , _pct(4) , "X" )
AddTabsA  ( wcTabs      , cMarginL  , cMarginT  , _pct(85) , cRow(1.25) , cRow(1.25) , WS_CLIPCHILDREN )
AddButtonA( wcButton    , _NextCol  , _SameRow  , cMarginR , cRow(1.25) , "Build" )
AddRichA  ( wcLines     , cMarginL  , _NextRow0 , _pct(1.9*(2+1)) , _pct(100) ,  "" , WS_DISABLED or ES_RIGHT ) 'SS_OWNERDRAW )
AddRichA  ( wcEdit      , _NextCol0 , _SameRow  , cMarginR , _pct(53) , "" , WS_HSCROLL or WS_VSCROLL or ES_AUTOHSCROLL or ES_DISABLENOSCROLL or ES_NOHIDESEL )            
AddButtonA( wcRadOutput , cMarginL  , _NextRow  , _pct(15) , cRow(1) , "Output" , WS_GROUP or BS_AUTORADIOBUTTON or BS_PUSHLIKE )
AddButtonA( wcRadQuery  , _NextCol0 , _SameRow  , _pct(15) , cRow(1) , "Query"  , BS_AUTORADIOBUTTON or BS_PUSHLIKE )
AddButtonA( wcBtnExec   , _NextCol3 , _SameRow  , _pct(15) , cRow(1) , "Execute" , WS_GROUP )
AddButtonA( wcBtnLoad   , _NextCol  , _SameRow  , _pct(15) , cRow(1) , "Load"  )
AddButtonA( wcBtnSave   , _NextCol  , _SameRow  , _pct(15) , cRow(1) , "Save" )
AddButtonA( wcBtnDec    , _NextCol3 , _SameRow  , _pct(5)  , cRow(1) , "--" , WS_DISABLED )
AddButtonA( wcBtnInc    , _NextCol0 , _SameRow  , _pct(5)  , cRow(1) , "++" , WS_DISABLED )
AddButtonAT( wcBtnMinOut , _RtP(wcOutput,-4) , _SameRow , _pct(4) , cRow(1) , !"\x36" , BS_AUTOCHECKBOX or BS_PUSHLIKE )
AddRichA  ( wcOutput    , cMarginL  , _NextRow  , cMarginR , _BottomP(-5) , "" , WS_HSCROLL or WS_VSCROLL or ES_AUTOHSCROLL or ES_READONLY )
AddEditA  ( wcQuery    , cMarginL  , _SameRow  , cMarginR , _BottomP(-5) , "" , WS_HSCROLL or WS_VSCROLL or ES_AUTOHSCROLL )
AddStatusA( wcStatus    , "Ready." )
'SetParent( CTL(wcBtnMinOut) , CTL(wcOutput) )

SetControlsFont( wfEdit   , wcLines , wcEdit , wcOutput )
SetControlsFont( wfStatus , wcStatus )
SetControlsFont( wfArrows , wcBtnMinOut )

SetWindowTheme( CTL(wcEdit) , "" , "" )
SetWindowTheme( CTL(wcOutput) , "" , "" )
SetWindowTheme( CTL(wcQuery) , "" , "" )
SendMessage( CTL(wcEdit) , EM_EXLIMITTEXT , 0 , 16*1024*1024 ) '16mb text limit
SendMessage( CTL(wcEdit) , EM_SETEVENTMASK , 0 , ENM_CLIPFORMAT or ENM_SELCHANGE or ENM_KEYEVENTS) ' or ENM_SCROLL )
OrgEditProc = cast(any ptr,SetWindowLongPtr( CTL(wcEdit) , GWLP_WNDPROC , cast(LONG_PTR,@WndProcEdit) ))
OrgLinesProc = cast(any ptr,SetWindowLongPtr( CTL(wcLines) , GWLP_WNDPROC , cast(LONG_PTR,@WndProcLines) ))

dim as TC_ITEM tItem = type( TCIF_TEXT or TCIF_PARAM , 0,0 , @"Unnamed" , 0,-1 , 0 ) 
with g_tTabs(0)
   TabCtrl_InsertItem( CTL(wcTabs) , 0 , @tItem )
   .hEdit = CTL(wcEdit) : .sFilename = ""
end with
SetControlsFont( wfStatus, wcTabs )

InitSearchWindow()

'Menu.Trigger( meCompletion_Enable )
'Menu.Trigger( meView_ToggleGWDock )
'Menu.Trigger( meCompletion_Variations )

#define CallSetupFunction( _Varname , _Function , _Parms... ) _Function( _Parms )
#macro CheckSetupFunction( _Varname , _VarType , _Default , _SetupFunction... )
  #if len(#_SetupFunction)
    #define _cfgVarName ._VarName
    CallSetupFunction( _Varname , _SetupFunction )
    #undef _cfgVarName
  #endif
#endmacro
with g_tCfg
  ForEachSetting( CheckSetupFunction )
end with

ColoredControl.Colorize( CTL(wcRadOutput) , &HFF8844 )
ColoredControl.Colorize( CTL(wcRadQuery)  , &HFF8844 )
ColoredControl.Colorize( CTL(wcBtnExec)   , &H4488FF )
ColoredControl.Colorize( CTL(wcBtnLoad)   , &HFF0000 )
ColoredControl.Colorize( CTL(wcBtnSave)   , &H0000FF )
ColoredControl.Colorize( CTL(wcBtnInc)    , &H006600 )
ColoredControl.Colorize( CTL(wcBtnDec)    , &H000066 )
ColoredControl.Colorize( CTL(wcBtnMinOut) , &H00FF00 )
ColoredControl.Colorize( CTL(wcButton)    , &H00FF00 )
ColoredControl.Colorize( CTL(wcBtnClose)  , &H0000FF )
'ColoredControl.Colorize( CTL(wcOutput)    , &HFFF0F0 )
ColoredControl.Colorize( CTL(wcQuery)     , &HFF8888 )

SendMessage( CTL(wcRadQuery) , BM_CLICK , 0,0 )
'SendMessage( CTL(wcRadOutput) , BM_CLICK , 0,0 )
SendMessage( CTL(wcBtnMinOut) , BM_CLICK , 0,0 )

WaitForSingleObject( hEventGfxReady , INFINITE )    
CloseHandle( hEventGfxReady )
if g_GfxHwnd = 0 then return -1 'failed

'SetWindowPos( g_hContainer , 0 , 0,0,100,100 , SWP_NOZORDER or SWP_SHOWWINDOW or SWP_NOMOVE )
'ShowWindow( g_hContainer , SW_SHOW )
'puts "IniWid: " & g_tCfg.lGuiWid : puts "IniHei: " & g_tCfg.lGuiHei
ResizeMainWindow( true )

File_New()    
'LoadFileIntoEditor( exePath+"\sample.ls" )
SetForegroundWindow( ctl(wcMain) )
SetFocus( ctl(wcEdit) )
ChangeToTab( 0 )

'SetTimer( hwnd , 1 , 100 , NULL )
