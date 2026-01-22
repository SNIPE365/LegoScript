'#cmdline "Res\LS.rc  -gen gcc -O 3 -g"
'#cmdline "Res\LS.rc  -gen gcc -O 3  -Wl '--large-address-aware' "
#cmdline "res\LS.rc -gen gcc -O 2 -Wl '--large-address-aware'"
'#cmdline "res\LS.rc -Wl '--large-address-aware'"

'-O 1

#define __Main "LegoScript"
#define __DebugShadowLoad
#define SearchIsInPanel

#define _WIN32_WINNT &h0600
#include once "windows.bi"
#include once "win\commctrl.bi"
#include once "win\commdlg.bi"
#include once "win\cderr.bi"
#include once "win\ole2.bi"
#include once "win\Richedit.bi"
#include once "win\uxtheme.bi"
#include once "win\shlwapi.bi"
#include once "crt.bi"
#include once "fbthread.bi"

#if __FB_DEBUG__
  #include once "MyTDT\Exceptions.bas"
  StartExceptions()
#endif

#undef File_Open
#define Errorf(p...)
#define Debugf(p...)

' !!! some pieces have unmatched studs vs clutch (and i suspect that's their design problem) !!!
' !!! because when using ldraw it does not matter the order, so they never enforced that     !!!

'TODO (12/01/26): add option for rotate on cursor pos instead of model center
'TODO (21/12/25): make the buttons smaller / change colors
'TODO (21/12/25): the gray parts should now be very dark gray / buttons should be yellow
'TODO (21/12/25): fix 3005 B1 s1 = 3024 P1 c1
'TODO (02/09/25): fix piece declaration + forward reference (RotatePivot.ls)
'TODO (30/06/25): continue fixing/improving the row counter
'TODO (13/06/25): fix LS2LDR showing wrong error line numbers with #defines
'TODO (19/05/25): fix LS2LDR parsing bugs (prevent part that is connected from moving)
'TODO (17/05/25): investigate crash when building before opening graphics window
'TODO (16/05/25): clutches [slide=true] are real clutches??
'TODO (13/05/25): Add Menu entries for the Query window/buttons 
'TODO (16/05/25): TAB structure must keep the selection position
'TODO (06/03/25): check bug regarding wheel positioning and the line numbers
'TODO (21/04/25): prevent buffer overflow when doing a FIND/REPLACE when the selected text is bigger than 32k

'*************** Enumerating our control id's ***********
enum StatusParts
   spStatus
   spCursor
end enum
enum WindowControls
  wcMain
  wcBtnClose
  wcTabs
  wcButton  
  wcSidePanel
  'Side Panel search tab
  wcSearchEdit
  wcSearchList  
  wcSideSplit  
  wcBtnSide
  'editor
  wcLines
  wcEdit  
  wcOutSplit  
  'output
  wcRadOutput
  wcRadQuery
  wcBtnExec
  wcBtnLoad
  wcBtnSave
  wcBtnInc
  wcBtnDec
  wcBtnMinOut
  wcOutput
  wcQuery
  wcStatus
  wcLast
end enum
enum WindowFonts
   wfDefault
   wfEdit
   wfStatus
   wfSmall
   wfArrows
   wfLast
end enum
enum Accelerators
   acFirst = 9100-1
   acToggleMenu   
   acFilterDump
end enum

#define CTL(_I) g_tMainCtx.hCtl(_I).hwnd
#define AsBool(_var) cast(boolean,((_var)<>0))

dim shared as boolean g_bChangingFont = false

#include Once "LSModules\ColoredButtons.bas"
#include once "LSModules\TryCatch.bas"
#include once "LSModules\Layout.bas"

type FormContext
  as FormStruct        tForm        'Form structure
  as ControlStruct     hCTL(wcLast) 'controls
  as FontStruct        hFnt(wfLast) 'fonts  
end type
type TabStruct
   hEdit      as hwnd
   sFilename  as string
   iLinked    as long   = -1
end type
redim shared g_tTabs(0) as TabStruct 
dim shared as long g_iTabCount = 1 , g_iCurTab = 0

const g_sMainFont  = "verdana" , g_sFixedFont = "consolas" , g_sArrowFont = "Webdings"

dim shared as FormContext g_tMainCtx
dim shared as hinstance g_AppInstance  'instance
dim shared as string sAppName        'AppName (window title 'prefix')
dim shared as HMENU g_WndMenu        'Main Menu handle
'dim shared as long g_WndWid=640 , g_WndHei=480
dim shared g_hCurMenu as any ptr , g_CurItemID as long , g_CurItemState as long

dim shared as HANDLE g_hResizeEvent
dim shared as hwnd g_GfxHwnd
dim shared as byte g_DoQuit
dim shared as any ptr g_ViewerThread
dim shared as string g_CurrentFilePath

#define g_Show3D           g_tCfg.bGfxEnable
#define g_Dock3D           g_tCfg.bGuiAttached
#define g_CompletionEnable g_tCfg.bCompletionEnable

declare sub DockGfxWindow( bForce as boolean = false )
declare sub File_SaveAs()
declare sub RichEdit_Replace( hCtl as HWND , iStart as long , iEnd as long , sText as string , bKeepSel as long = true )

#define GiveUp(_N) return false

declare sub ChangeToTabByFile( sFullPath as string , iLine as long = -1 )

#include "Loader\Modules\Matrix.bas"
#include "Loader\LoadLDR.bas"
#include once "LSModules\Settings.bas"
#include "Loader\Include\Colours.bas"
#include "Loader\Modules\Clipboard.bas"
#include "Loader\Modules\InitGL.bas"
#include "Loader\Modules\Math3D.bas"
#include "Loader\Modules\Normals.bas"
#include "Loader\Modules\Model.bas"
'#include "Loader\Modules\modelA.bas"
'#include "Loader\Modules\modelB.bas"
#include "LSModules\LS2LDR.bas"
#include "LSModules\ComboBox.bas"
#include once "LSModules\CommandLine.bas"

sub LogError( sError as string )   
   var f = freefile()
   open exepath+"\FatalErrors.log" for append as #f
   print #f, date() + " " + time() + sError
   close #f   
   puts(sError)
   SetWindowText( CTL(wcStatus) , sError )   
   MessageBox( CTL(wcMain) , sError , NULL , MB_ICONERROR )
end sub

static shared as long g_iPrevTopRow = 0 , g_iPrevRowCount = 0 , g_RowDigits = 2
static shared as long g_ZoomNum , g_ZoomDiv
static shared as zstring*128 g_zRows
static shared as SearchQueryContext g_SQCtx
static shared as string sLastSearch

#include "LsModules\LSMenu.bas"
#include "LsModules\LSViewer.bas"
#include "LSModules\LSActions.bas"

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
         #if _Accelerator >= VK_F1 and _Accelerator <= VK_F24
            #define _sKey "F" & (_Accelerator-((VK_F1)-1))
         #elseif _Accelerator >= asc("A") and _Accelerator <= asc("Z")           
            #define _sKey +chr(_Accelerator)
         #elseif _Accelerator >= asc("0") and _Accelerator <= asc("9")           
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
   dim as LPARAM lZoomNum = any , lZoomDiv = any
   SendMessage( CTL(wcEdit) , EM_GETZOOM , cast(WPARAM,@lZoomNum) , cast(LPARAM,@lZoomDiv) )
   if g_ZoomNum <> lZoomNum orelse g_ZoomDiv <> lZoomDiv then
      g_ZoomNum = lZoomNum : g_ZoomDiv = lZoomDiv      
      g_iPrevRowCount = -1 : g_RowDigits = -1 : g_iPrevTopRow = -1
   end if
   
   if g_iPrevTopRow <> iTopRow orelse g_iPrevRowCount <> iRows then
      g_iPrevTopRow = iTopRow 
      var pzRows = @g_zRows , iRowsMax = 15
      if g_ZoomDiv then iRowsMax = (iRowsMax*g_ZoomDiv)\g_ZoomNum
      for N as long = 1 to iif(iRows<iRowsMax,iRows,iRowsMax)
         pzRows += sprintf(pzRows,!"%i\r\n",iTopRow+N)
      next N
      'InvalidateRect( CTL(wcLines) , NULL , FALSE )
      SendMessage( CTL(wcLines) , WM_SETREDRAW , 0 , 0 )
      SetWindowText( CTL(wcLines) , g_zRows )      
      
      SendMessage( CTL(wcLines) , WM_SETREDRAW , 1 , 0 )
      SendMessage( CTL(wcLines) , EM_SETZOOM , lZoomNum , lZoomDiv )
      
      'SendMessage( CTL(wcLines) , EM_SETRECT , 0 , cast(LPARAM,@Type<RECT>(0,10,100,100)) )
      'dim as RECT tRC = any
      'SendMessage( CTL(wcEdit) , EM_GETRECT , 0 , cast(LPARAM,@tRc) )
      'with tRc
      '   printf(!"(%i,%i)-(%i,%i)\n",.left,.top,.right,.bottom)
      'end with
      'if g_iPrevRowCount <> iRows then SendMessage( CTL(wcLines) , WM_SETREDRAW , 1 , 0 )
   end if
   
   if g_iPrevRowCount <> iRows then
      'puts("rows changed")
      g_iPrevRowCount = iRows
      var iRowDigits = 2
      if iRows > 99 then iRowDigits += 1
      if iRows > 999 then iRowDigits += 1
      if iRows > 9999 then iRowDigits += 1
      if iRows > 99999 then iRowDigits += 1
      if iRowDigits <> g_RowDigits then
         g_RowDigits = iRowDigits
         'printf(!"Num=%i , Div=%i\n",g_ZoomNum,g_zoomDiv)
         PostMessage( CTL(wcMain) , WM_USER+3 , 0 , 0 )
      end if
   end if
end sub
sub RichEdit_SelChange( hCtl as HWND , iRow as long , iCol as long )
   
   'puts(__FUNCTION__)
   #define zRow t.zRow_      
   type tBuffer
      union
         wSize as ushort
         zRow_ as zstring*1024
      end union
   end type
   dim t as tBuffer = any : t.wSize = 1023   
   
   'changed to edit (for now?) only matter if Auto Completion is enabled
      
   if g_SQCtx.iRow <> iRow then 'row changed, handle case
      var iSz = SendMessage( hCtl , EM_GETLINE , g_SQCtx.iRow , cast(LRESULT,@t) )
      if iSz then 'if line is not empty
         zRow[iSz-1]=0 : var sText = zRow
         if _cfg(bAutoFmtCase) andalso asBool(HandleCasing( sText , g_SQCtx )) then 'if case was changed update line
            var iStart = SendMessage( hCTL , EM_LINEINDEX , g_SQCtx.iRow , 0 )
            RichEdit_Replace( hCtl , iStart , iStart+iSz-1 , sText )
         end if
      end if
   end if   
   
   g_SQCtx.iRow = iRow : g_SQCtx.iCol = iCol
   if g_CompletionEnable=0 orelse Menu.IsChecked(meCompletion_Enable)=0 then exit sub
      
   var iSz = SendMessage( hCtl , EM_GETLINE , iRow , cast(LRESULT,@t) )
         
   if iSz < 0 orelse iSz > 1023 then exit sub   
         
   var iWid = 80 : zRow[iSz-1]=0
   'printf( !"%i:%s\t%f\r",iSz,left(zRow+space(iWid-6),iWid-5),timer )   
   with g_SQCtx
      if ubound(.sTokenTxt) < 0 then redim .sTokenTxt(.iMaxTok-1)      
      .bChanged = 1 : .iCur = iCol 'instr( iCol+1 , zRow , " " )-1
      'if .iCur < 0 then .iCur = iSz-2
   end with
   sLastSearch = zRow
   
   Try()      
      #ifdef SearchIsInPanel
        HandleTokens( sLastSearch , g_SQCtx , true )
      #else
        HandleTokens( sLastSearch , g_SQCtx , false )
      #endif
      Catch()
         LogError( "Auto completion Crashed!!!" )
      EndCatch()
   EndTry()
   
end sub
function RichEdit_KeyPress( hCtl as HWND , iKey as long , iMod as long ) as long
  #ifndef SearchIsInPanel
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
  
  if g_SearchChanged<>0 andalso g_CompletionEnable then      
    Try()
       HandleTokens( sLastSearch , g_SQCtx )
       Catch()
          LogError( "Auto completion Crashed!!!" )
       EndCatch()
    EndTry()
  end if
  #endif   
  return 0
end function
sub RichEdit_IncDec( hCtl as HWND , bIsInc as boolean )
   'puts(hCtl & " " & bIsInc)
   dim as TEXTRANGE tRg = any
   SendMessageW( hCtl , EM_EXGETSEL , 0 , cast(LPARAM,@tRg.chrg) )
   var iSelLen = cint(tRg.chrg.cpmax-tRg.chrg.cpMin)   
   if cuint(iSelLen-1) >= 20 then exit sub   
   dim as wstring*32 wSel = any   
   tRg.lpstrText = cast(any ptr,@wSel)   
   SendMessageW( hCtl , EM_GETTEXTRANGE , 0 , cast(LPARAM,@tRg) )
   'puts("Sel: " & iSelLen & " '"+wSel+"'")
   for N as long = 0 to iSelLen-1      
      select case wSel[N]      
      case asc("0") to asc("9"): continue for
      case asc("-")            : if N then exit sub
      case else                : exit sub
      end select
   next N   
   var sSel = str(ValLng(wSel)+iif(bIsInc,1,-1))   
   var iMask = SendMessage( hCtl , EM_GETEVENTMASK   , 0 , 0 )                     
   SendMessage( hCtl , EM_SETEVENTMASK , 0 , iMask and (not ENM_SELCHANGE))
   SendMessage( hCTL , EM_EXSETSEL  , 0 , cast(LPARAM,@tRg.chrg) )   
   tRg.chrg.cpMax = tRg.chrg.cpMin+len(sSel)
   SendMessage( hCtl , EM_REPLACESEL , false , cast(LPARAM,strptr(sSel)) )
   SendMessage( hCtl , EM_EXSETSEL , 0 , cast(LPARAM,@tRg.chrg) )
   SendMessage( hCtl , EM_SETEVENTMASK , 0 , iMask)   
   SetFocus( hCtl )
end sub
sub RichEdit_Update( hCtl as HWND )   
   'dim as CHARFORMAT2A tFmt = type( sizeof(CHARFORMAT2A) , CFM_WEIGHT )   
   'SendMessage( hCtl , EM_GETCHARFORMAT , SCF_DEFAULT , cast(LPARAM,@tFmt) )
   g_iPrevTopRow = -1 ': g_iPrevRowCount = -1   
   RichEdit_TopRowChange( hCtl )   
end sub

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

sub DockGfxWindow( bForce as boolean = false )   
   static as boolean iOnce=false 
   if g_GfxHwnd=0 orelse IsIconic(g_GfxHwnd) orelse (bForce=false andalso IsWindowVisible(g_GfxHwnd)=0) then exit sub
   ''if IsWindowVisible(g_GfxHwnd)=0 then ShowWindow( g_GfxHwnd , SW_SHOW )
   dim as RECT RcWnd=any,RcGfx=any,RcCli=any,RcDesk
   GetWindowRect( GetDesktopWindow() , @RcDesk )
   GetWindowRect( g_GfxHwnd , @RcGfx )
   GetWindowRect( CTL(wcMain) ,@RcWnd )   
   var iYPos = RcWnd.top+((RcWnd.bottom-RcWnd.Top)-(RcGfx.bottom-RcGfx.top))\2   
   GetClientRect( CTL(wcMain) ,@RcCli )
   dim as POINT tPtRight = type(RcCli.Right-3,0)
   ClientToScreen( CTL(wcMain) , @tPtRight )   
   var hPlace = HWND_NOTOPMOST
   'if tPtRight.x >= (RcDesk.right-8) then 
   '   hPlace = HWND_TOPMOST : tPtRight.x -= (RcGfx.right - RcGfx.left)
   'end if
   RcDesk.right += 10 'This can be acquired with GetSystemMetrics?
   var GfxWid = (RcGfx.right - RcGfx.left)
   if (tPtRight.x+GfxWid) >= RcDesk.right then 
      hPlace = HWND_TOPMOST : tPtRight.x = RcDesk.right-GfxWid
   end if
   'gfx.tOldPt.x = -65537
   SetWindowPos( g_GfxHwnd , hPlace , tPtRight.x-4 ,iYPos , 0,0 , SWP_NOSIZE or SWP_NOACTIVATE or ((g_Dock3D=0 andalso iOnce) and SWP_NOMOVE) )
   'NotifySelChange( wcEdit ) ??Why this was here??
   iOnce = true
end sub   
sub ResizeMainWindow( bInit as boolean = false )            
  static as boolean bResize   
  if bResize then exit sub    
  'Calculate Client Area Size
  dim as RECT RcWnd=any,RcCli=any,RcDesk=any
  var hWnd = CTL(wcMain)
  if hWnd=0 orelse IsIconic(hWnd) orelse (bInit=0 andalso IsWindowVisible(hWnd)=0) then exit sub   
  bResize = true : GetClientRect(hWnd,@RcCli)
  GetWindowRect(hWnd,@RcWnd)
  'Window Rect is in SCREEN coordinate.... make right/bottom become WID/HEI
  if 1 then 'bInit then 'orelse (RcCli.right<>g_tCfg.lGuiWid) orelse (RcCli.bottom<>g_tCfg.lGuiHei) then
    with RcWnd      
      .right -= .left : .bottom -= .top                   'get window size
      .right -= RcCli.right : .bottom -= RcCli.bottom      'make it be difference from wnd/client
      .right += g_tCfg.lGuiWid : .bottom += g_tCfg.lGuiHei 'add back desired client area size
      GetClientRect(GetDesktopWindow(),@RcDesk)         
      dim as RECT RcGfx=any : GetWindowRect( g_GfxHwnd , @RcGfx )         
      var iAllWid = .right , iGfxHei = RcGfx.bottom-RcGfx.top
      'if using default settings then center the window
      if bInit andalso g_tCfg.lGuiX = clng(CW_USEDEFAULT) then
        if iGfxHei > .bottom then .bottom = iGfxHei
        iAllWid = .right + RcGfx.right-RcGfx.left         
        var iCenterX = (RcDesk.right-iAllWid)\2 , iCenterY = (RcDesk.bottom-.bottom)\2                 
        SetWindowPos(hwnd,null,iCenterX,iCenterY,.right,.bottom,SWP_NOZORDER or SWP_NOSENDCHANGING)
      else            
        SetWindowPos(hwnd,null,.left,.top,.right,.bottom,SWP_NOZORDER or SWP_NOSENDCHANGING)                     
      end if
      'puts("Wid: " & g_tCfg.lGuiWid & " Hei: " & g_tCfg.lGuiHei )
      'GetClientRect( hWnd , @RcCli )
      'puts("Wid?: " & RcCli.right & " Hei?: " & RcCli.bottom )
    end with   
  end if
  RcCli.right = g_tCfg.lGuiWid : RcCli.bottom = g_tCfg.lGuiHei
  
  'trigger a window maximizing if settings says so.
  if bInit andalso g_tCfg.bGuiMaximized then
    PostMessage( hWnd , WM_SYSCOMMAND , SC_MAXIMIZE,0 )
  end if
  
  'recalculate control sizes based on window size
  if g_hContainer then ShowWindow( g_hContainer , SW_HIDE )      
  var iModify = SendMessage( CTL(wcEdit) , EM_GETMODIFY , 0 , 0 )   
  ResizeLayout( hWnd , g_tMainCtx.tForm , RcCli.right , RcCli.bottom )   
  UpdateTabCloseButton() 
  SendMessage( CTL(wcEdit) , EM_SETMODIFY , iModify , 0 )
    
  if g_hSearch andalso g_hContainer then UpdateSearchWindowFont( g_tMainCtx.hFnt(wfStatus).HFONT )      
  MoveWindow( CTL(wcStatus) ,0,0 , 0,0 , TRUE )
  dim as long aWidths(2-1) = {RcCli.right*.85,-1}
  SendMessage( CTL(wcStatus) , SB_SETPARTS , 2 , cast(LPARAM,@aWidths(0)) )
  DockGfxWindow()   
  bResize=false   
  'puts("...")
end sub

static shared as any ptr OrgEditProc
function WndProcEdit ( hWnd as HWND, message as UINT, wParam as WPARAM, lParam as LPARAM ) as LRESULT   
  static as long iMod   
  
  if OrgEditProc=0 then return 0
  
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
    if wParam=VK_ESCAPE then 
       if OrgEditProc = 0 then return 0
       return CallWindowProc( OrgEditProc , hWnd , EM_SETSEL , -1 , 0 )
    end if
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
      if g_CompletionEnable then
        #ifdef SearchIsInPanel
          var iOldVis = g_SearchVis : g_SearchVis = SW_SHOW
        #endif
        var sFix = "" : SearchAddPartSuffix( sFix , g_SQCtx )
        #ifdef SearchIsInPanel
          g_SearchVis = iOldVis
        #endif
        'puts("'"+sFix+"'")
        if len(sFix) then
           for N as long = 0 to len(sFix)
              PostMessage( hWnd , WM_CHAR , sFix[N] , 0 )
           next N         
        end if
      end if
    case 3,24 'Ctrl-C / Ctrl-X
      if OrgEditProc=0 then return 0
      var lResu = CallWindowProc( OrgEditProc , hWnd , message , wParam, lParam )      
      GetClipboard() : return lResu
    end select      
  case WM_VSCROLL
    if OrgEditProc=0 then return 0
    var iResu = CallWindowProc( OrgEditProc , hWnd , message , wParam, lParam )
    g_iPrevRowCount = 0
    RichEdit_TopRowChange( hWnd )
    return iResu   
  case WM_CONTEXTMENU
   Edit_ContextMenu( hWnd , wParam , lParam )
   return 0
  end select
  if OrgEditProc=0 then return 0
  return CallWindowProc( OrgEditProc , hWnd , message , wParam, lParam )   
end function

static shared as any ptr OrgLinesProc
function WndProcLines ( hWnd as HWND, message as UINT, wParam as WPARAM, lParam as LPARAM ) as LRESULT
   select case message
   case WM_ERASEBKGND
      var hDC = cast(HDC,wParam)
      dim as POINT PT = any , PT0 = any
      var iCharIdx = Sendmessage( CTL(wcEdit) , EM_LINEINDEX  , g_iPrevTopRow , 0 )      
      SendMessage( hwnd , EM_POSFROMCHAR , cast(WPARAM,@PT0) , 0 )
      SendMessage( CTL(wcEdit) , EM_POSFROMCHAR , cast(WPARAM,@PT) , iCharIdx )            
      
      'dim as RECT tRC = any
      'GetClientRect( hwnd , @tRC )
      'tRc.top = tRc.bottom + (PT.y-PT0.y)
      'tRc.Bottom += PT.y-PT0.y
      'FillRect( hDC , @tRC , GetSysColorBrush(COLOR_BTNFACE) )
      
      SetViewportOrgEx( hDC , 0 , PT.y-PT0.y , NULL )
      'SetViewportExtEx( hDC , 0 , -(PT.y-PT0.y) , NULL )
      'printf(!"hdc=%p\n",hDC)   
      return 1
   case WM_PAINT            
      InvalidateRect( hWnd , NULL , true )
      ValidateRect( hWnd , @type<RECT>(0,-1000,1000,0) )
      dim as RECT tRc = any : GetWindowRect( CTL(wcEdit) , @tRc )
      ValidateRect( hWnd , @type<RECT>(0,tRc.bottom-tRc.top,1000,1000) )
      'dim as PAINTSTRUCT tPaint
      'BeginPaint( hWnd , @tPaint )      
      'CallWindowProc( OrgLinesProc , hWnd , WM_PRINTCLIENT , cast(WPARAM,tPaint.hDC), PRF_CLIENT )
      ''var iResu = CallWindowProc( OrgEditProc , hWnd , message , cast(WPARAM,tPaint.hDC), lParam )
      'EndPaint( hWnd , @tPaint )
      'return 0   
   end select
   if OrgLinesProc=0 then return 0
   return CallWindowProc( OrgLinesProc , hWnd , message , wParam, lParam )   
end function

static shared as any ptr OrgTabsProc
function WndProcTabs ( hWnd as HWND, message as UINT, wParam as WPARAM, lParam as LPARAM ) as LRESULT
  if message = WM_COMMAND then
    SendMessage( GetParent(hWnd) , message , wParam , lParam )
  end if
  return CallWindowProc( OrgTabsProc , hWnd ,  message , wParam , lparam )
end function

' *************** Procedure Function ****************
function WndProc ( hWnd as HWND, message as UINT, wParam as WPARAM, lParam as LPARAM ) as LRESULT
    
  var pCtx = (@g_tMainCtx)      
  #include "LSModules\Controls.bas"
  #include "LSModules\ControlsMacros.bas"  
  
  select case( message )
  #if 0
    case WM_CTLCOLORBTN  
       var hCtl = cast(HWND,lParam) : printf(!"btn=%X\n",hCtl)
       if hCtl = CTL(wcTabs) then puts("Tabs changed? (button)")
    case WM_CTLCOLORSCROLLBAR  
       var hCtl = cast(HWND,lParam) : printf(!"scroll=%X\n",hCtl)
       if hCtl = CTL(wcTabs) then puts("Tabs changed? (scroll)")
    case WM_CTLCOLORSTATIC  
       var hCtl = cast(HWND,lParam) : printf(!"static=%X\n",hCtl)
       if hCtl = CTL(wcTabs) then puts("Tabs changed? (static)")      
       'TabCtrl_GetItemRect(
  #endif   
  
  case WM_DRAWITEM   'item in a control is being drawn (owner draw)
    var wID = clng(wParam) , ptDrw = cast(LPDRAWITEMSTRUCT,lparam)
    select case wId
    case wcLines : Lines_Draw( CTL(wcEdit) , *ptDrw )
    end select
    return 0
  case WM_TIMER
    select case wParam
    case wcEdit*256         
       KillTimer( hWnd , wParam )
       RichEdit_Update( CTL(wcEdit) )
    case else      
       dim as Matrix4x4 tMat
       tMat = g_tIdentityMatrix
       static as double dBeg : if dBeg = 0 then dBeg = timer
       Matrix4x4RotateX( tMat , tMat , timer-dBeg )
       dim as zstring*256 zOutput = any
       with tMat
          sprintf(zOutput,!"1 %i %f %f %f %g %g %g %g %g %g %g %g %g %s\r\n",16,.fPosX,.fPosY,.fPosZ, _
             .m(0),.m(1),.m(2),.m(4),.m(5),.m(6),.m(8),.m(9),.m(10) , "3011.dat" )
       end with
       Viewer.LoadMemory( zOutput , "memory.ldr" )
    end select
  case WM_CTLCOLOREDIT
    var hDC = cast(HDC,wParam), hCtl = cast(HWND,lParam)
    select case hCtl
    case CTL(wcSearchEdit)
      if GetWindowTextLength(hCtl)=0 then
        SetTextColor( hDC , &hCCCCCC )
        TextOut( hDC , 0 , 0 , "Search..." , 9 )
        return cast(LRESULT,GetStockObject(NULL_BRUSH))
      end if
    end select
  case WM_NOTIFY     'notification from window/control
    var wID = cast(long,wParam) , pnmh = cptr(LPNMHDR,lParam)
    select case wID
    case wcSideSplit      
      if SendMessage( CTL(wcBtnSide) , BM_GETCHECK , 0 , 0 )=0 then 
        SendMessage( CTL(wcBtnSide) , BM_CLICK , 0,0 )
        SendMessage( pnmh->hwndFrom , WM_LBUTTONDOWN , 0,0 )
      end if
      var hWnd = CTL(wcMain)
      dim as long iX = pnmh->code
      dim as RECT RcCli=any : GetClientRect(hWnd,@RcCli)
      with g_tMainCtx.hCTL( wcSidePanel )
        var iWid = iX-.iX , iMinWid = g_tMainCtx.tForm.pCtl[wcButton].iH
        var iMaxWid = (RcCli.Right-.iX)-iMinWid
        if iWid < iMinWid then iWid = iMinWid
        if iWid > iMaxWid then iWid = iMaxWid
        .tW = _Pct( (iWid*100)/RcCli.Right )
      end with        
      ResizeLayout( hWnd , g_tMainCtx.tForm , RcCli.right , RcCli.bottom )      
    case wcOutSplit            
      if SendMessage( CTL(wcBtnMinOut) , BM_GETCHECK , 0 , 0 )=0 then 
        SendMessage( CTL(wcBtnMinOut) , BM_CLICK , 0,0 )
        SendMessage( pnmh->hwndFrom , WM_LBUTTONDOWN , 0,0 )
      end if
      var hWnd = CTL(wcMain)
      dim as long iY = pnmh->code        
      dim as RECT RcCli=any : GetClientRect(hWnd,@RcCli)
      'printf("%i ",iY)
      ''g_tMainCtx.hCTL( wID-1 ).tW = iif(iOpen, _Pct(20) , _Pct(0))     
      with g_tMainCtx.hCTL( wID-1 )
        var iHei = iY-.iY , iMinHei = g_tMainCtx.tForm.pCtl[wcButton].iH
        var iMaxHei = (RcCli.Bottom-.iY)-(iMinHei*2)
        if iHei < iMinHei then iHei = iMinHei
        if iHei > iMaxHei then iHei = iMaxHei
        .tH = _Pct( (iHei*100)/RcCli.Bottom )
      end with        
      ResizeLayout( hWnd , g_tMainCtx.tForm , RcCli.right , RcCli.bottom )
    case wcTabs
       select case pnmh->code
       case TCN_SELCHANGE
          var iIDX = TabCtrl_GetCurSel( CTL(wID) )            
          ChangeToTab( iIDX , true )
       end select
    case wcEdit
       select case pnmh->code                  
       case EN_SELCHANGE
          if g_bChangingFont then return 0
          with *cptr(SELCHANGE ptr,lParam)
             'static as CHARRANGE tPrev = type(-1,-2)
             'if memcmp( @.chrg , tPrev , sizeof(tPrev))CHARRANGE
             var iRow = SendMessage( CTL(wID) , EM_EXLINEFROMCHAR , 0 , .chrg.cpMax )
             var iCol = .chrg.cpMax - SendMessage( CTL(wID) , EM_LINEINDEX  , iRow , 0 )
             dim as zstring*64 zPart = any : sprintf(zPart,"%i : %i",iRow+1,iCol+1)
             'printf(!"(%s) > %i to %i    \r",,,.chrg.cpMin,.chrg.cpMax)
             SendMessage( CTL(wcStatus) , SB_SETTEXT , spCursor , cast(LPARAM,@zPart) ) 
             if cuint((.chrg.cpmax-.chrg.cpMin)-1) < 20 then
                EnableWindow( CTL(wcBtnInc) , true )
                EnableWindow( CTL(wcBtnDec) , true )
             else
                EnableWindow( CTL(wcBtnInc) , false )
                EnableWindow( CTL(wcBtnDec) , false )
             end if
             RichEdit_TopRowChange( CTL(wID) )
             RichEdit_SelChange( CTL(wID) , iRow , iCol )
          end with
       end select
    case wcSearchList
      puts("???")
    end select
    return 0
  case WM_COMMAND    'Event happened to a control (child window)
    var wNotifyCode = cint(HIWORD(wParam)), wID = LOWORD(wParam) , hwndCtl = cast(.HWND,lParam)      
    if hwndCtl=0 andalso wNotifyCode=0 then wNotifyCode = -1      
    if hwndCtl=0 andalso wNotifyCode=1 then wNotifyCode = -2
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
       g_CurItemID = 0 : g_hCurMenu = 0 : return 0
    case -2         'Accelerator
       ProcessAccelerator( wID )
       return 0
    case BN_CLICKED 'Clicked action for different buttons
       select case wID
       case wcBtnClose  : File_Close()
       case wcButton    : Button_Compile()
       case wcBtnDec    : RichEdit_IncDec( CTL(wcEdit) , false )
       case wcBtnInc    : RichEdit_IncDec( CTL(wcEdit) , true )
       case wcRadOutput : Output_SetMode()
       case wcRadQuery  : Output_SetMode()
       case wcBtnExec   : Output_QueryExecute()
       case wcBtnLoad   : Output_Load()
       case wcBtnSave   : Output_Save()
       case wcBtnMinOut : Output_ShowHide()
       case wcBtnSide   : Solution_ShowHide()
       end select
    case BN_DBLCLK  'double clicked in rapid fire buttons
      select case wID
      case wcBtnDec    : RichEdit_IncDec( CTL(wcEdit) , false )
      case wcBtnInc    : RichEdit_IncDec( CTL(wcEdit) , true )
      end select    
    end select      
    select case wID
    case wcEdit     'Main editor control actions
       select case wNotifyCode
       case EN_UPDATE
          static as double dLastUpdate
          if abs(timer-dLastUpdate) > .05 then
             RichEdit_Update( hwndCtl )
             dLastUpdate = timer
          else
             SetTimer( hwnd , wcEdit*256 , 100 , NULL )            
          end if            
       case EN_SETFOCUS               
          if g_CompletionEnable<>0 andalso g_hContainer<>0 then ShowWindow( g_hContainer , g_SearchVis   )               
       case EN_KILLFOCUS
          'printf(!"%p (%p) (%p)\n",GetFocus(),g_hContainer,CTL(wcEdit))
          'if GetForegroundWindow() <> g_hContainer then 
          var hFocus = GetFocus()
          if hFocus=0 orelse (hFocus <> g_hSearch andalso hFocus<>g_hContainer andalso hFocus <> CTL(wcEdit)) then
             if g_hContainer then ShowWindow( g_hContainer , SW_HIDE )
          end if
       case EN_VSCROLL
          RichEdit_TopRowChange( hwndCtl )
       end select
    case wcSearchEdit
      #ifdef SearchIsInPanel
        select case wNotifyCode 
        case EN_UPDATE
          dim as string sText
          scope
            dim as zstring*1024 zText = any : zText[0]=0
            GetWindowText( hwndCTL , @zText , 1023 )
            sText = zText
          end scope
          UpdateSearch(sText)
        end select
      #endif
    case wcSearchList      
      select case wNotifyCode 
      case LBN_SELCHANGE        
        UpdateStatusBarPartDescription()
      case LBN_DBLCLK
        var sPart = UpdateStatusBarPartDescription()
        sPart[len(sPart)]=asc(" ") 'send space as well
        SetFocus( CTL(wcEdit) )
        for N as long = 0 to len(sPart)
          SendMessage( CTL(wcEdit) , WM_CHAR , sPart[N] , 1 )
        next N        
      end select
    end select      
    return 0
  
  case WM_SIZE       'window is sizing/was sized
    'puts("Main Size")
    if wParam <> SIZE_MINIMIZED andalso wParam <> SIZE_MAXHIDE then 
       var lWid = clng(LOWORD(lParam)) , lHei = clng(HIWORD(lParam))
       if g_tCfg.lGuiWid <> lWid orelse g_tCfg.lGuiHei <> lHei then
          'puts("SIZE CHANGED!")
          g_tCfg.lGuiWid = lWid : g_tCfg.lGuiHei = lHei
          ResizeMainWindow() : UpdateTabCloseButton() 
       end if         
       return 0
    end if
  case WM_MOVE       'window is moving/was moved
    DockGfxWindow()
  case WM_ERASEBKGND    
    return 1  
  case WM_PAINT    
    dim as PAINTSTRUCT tPaint    
    BeginPaint( hWnd , @tPaint )        
    PostMessage( hwnd , WM_USER+4 , 0 , 0 )    
    EndPaint( hWnd , @tPaint )    
    return 0
  case WM_USER+1 'gfx resized
    SetEvent(g_hResizeEvent)
    DockGfxWindow()
    return 0
  case WM_USER+2 'gfx moved
    DockGfxWindow()
    return 0
  case WM_USER+3 'Resize Number border
    dim as single fMul = 1.9
    if g_ZoomNum andalso g_ZoomDiv then fMul = (fMul*g_ZoomNum)/g_zoomDiv      
    #define cLeftSide _RtN( wcSideSplit , 0 )
    SetControl( wcLines , cLeftSide , _TpN(wcSidePanel,0) , _pct(fMul*(g_RowDigits+1)) , _BtP(wcEdit,-3.5) , CTL(wcLines) )    
    ResizeMainWindow()      
    return 0
  case WM_USER+4 'late erase bkgnd
    UpdateWindow(hwnd)
    dim as RECT rc = any: GetClientRect( hwnd , @rc )    
    var hdc = GetDC(hwnd) , rgn = CreateRectRgnIndirect(@rc)
    var child = GetWindow(hwnd, GW_CHILD)
    while (child)
      dim as RECT cr = any
      if (IsWindowVisible(child)) then
        GetWindowRect(child, @cr)
        MapWindowPoints(NULL, hwnd, cast(POINT ptr,@cr), 2)
        var crgn = CreateRectRgnIndirect(@cr)
        CombineRgn(rgn, rgn, crgn, RGN_DIFF)
        DeleteObject(crgn)
      end if
      child = GetNextWindow(child, GW_HWNDNEXT)
    wend

    SelectClipRgn(hdc, rgn)
    FillRect( hDC , @rc , cast(HBRUSH,GetClassLong( hwnd , GCL_HBRBACKGROUND)) )
    SelectClipRgn(hdc, NULL)
    DeleteObject(rgn)
    ReleaseDC(hwnd, hdc)
    
    return 0
  case WM_USER+80 'InvalidateRect( hWnd , NULL , TRUE )
    dim as RECT RcCli=any : GetClientRect(hWnd,@RcCli)                
    ResizeLayout( hWnd , g_tMainCtx.tForm , RcCli.right , RcCli.bottom )
  case WM_MENUSELECT 'track newest menu handle/item/state
    var iID = cuint(LOWORD(wParam)) , fuFlags = cuint(HIWORD(wParam)) , hMenu = cast(HMENU,lParam) 
    if hMenu then g_CurItemID = iID : g_hCurMenu = hMenu            
    return 0
  case WM_ACTIVATE  'Activated/Deactivated
    static as boolean b_IgnoreActivation      
    if b_IgnoreActivation=false andalso AsBool(g_GfxHwnd) andalso g_Show3D then
       var fActive = LOWORD(wParam) , fMinimized = HIWORD(wParam) , hwndPrevious = cast(HWND,lParam)
       if fActive then            
          'puts("Main Activate")
          SetWindowPos( g_GfxHwnd , HWND_TOPMOST , 0,0,0,0 , SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE)
          DockGfxWindow()
          SetWindowPos( g_GfxHwnd , HWND_NOTOPMOST , 0,0,0,0 , SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_SHOWWINDOW)            
          'SetFocus( CTL(wcMain) )
       else
          'puts("main deactivate")
          if isIconic(g_GfxHwnd) = 0 then            
             if fMinimized andalso (GetKeyState(VK_SHIFT) shr 7) then                              
                ShowWindow( g_GfxHwnd , SW_HIDE )
             else
                SetWindowPos( g_GfxHwnd , HWND_NOTOPMOST , 0,0 , 0,0 , SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE )                  
                
             end if
          end if
       end if
    end if   
  #if 0
  case WM_ACTIVATEAPP
    var fActive = wParam
    'if GetForegroundWindow() <> g_hContainer then fActive = (GetFocus = CTL(wcEdit))
    if fActive then
       ShowWindow( g_hContainer , g_SearchVis )
    else
       ShowWindow( g_hContainer , SW_HIDE )
    end if
  #endif
  case WM_DROPFILES
    var hDrop = cast(HANDLE,wParam)
    if wParam=0 then return 0
    var iFiles = DragQueryFile( hDrop , &hFFFFFFFF , NULL , 0 )
    if iFiles > 9 then
      var iResu = MessageBox( hwnd , "You're opening " & iFiles & " files, want to continue?" , sAppName , MB_ICONINFORMATION or MB_TASKMODAL or MB_YESNO )
      if iResu = IDNO then iFiles=0
    end if
    for N as long = 0 to iFiles-1
      dim as zstring*65536 zFile = any
      if DragQueryFile( hDrop , N , zFile , 65535 ) then LoadScript( zFile )
    next N  
    DragFinish( hDrop )
    return 1
  case WM_ENTERMENULOOP , WM_ENTERSIZEMOVE  
   ShowWindow( g_hContainer , SW_HIDE )
  case WM_CREATE  'Window was created
    #include "LSModules\LSMainCreate.bas"          
    var sCurDir = curdir()+"\"
    for N as long = 1 to ubound(g_sOpenFiles)
       var sFile = g_sOpenFiles(N)
       if len(sFile)=0 then exit for
       for N as long = 0 to len(sFile)
          if sFile[N] = asc("/") then sFile[N] = asc("\")
       next N
       if FileExists(sCurDir+sFile) then 
          sFile = sCurDir + sFile
       elseif FileExists(sFile)=0 then
          var iResu = MessageBox( CTL(wcMain) , _
             !"File does not exist: \r\n\r\n" _
             !"'"+sFile+!"'\r\n\r\n" _
             !"Create it?", NULL , MB_ICONERROR or MB_YESNOCANCEL )
          if iResu = IDCANCEL then exit for
          if iResu = IDNO then continue for            
          sFile = ":"+sFile
       end if      
       'puts(sFile)
       var pzTemp = cptr(zstring ptr,malloc(65536))
       PathCanonicalizeA( pzTemp , sFile )
       LoadScript( *pzTemp )
       free(pzTemp)
    next N
    return 0
  case WM_CLOSE   'close button was clicked
    if File_Quit()=false then return 0      
    'puts("" & IsWindow( CTL(wcEdit) ) & " // " & IsWindow( CTL(wcLines) ))
    if OrgEditProc then          
       var pOrgProc = OrgEditProc : OrgEditProc = @DefWindowProc         
       SetWindowLongPtr( CTL(wcEdit) , GWLP_WNDPROC , cast(LONG_PTR,pOrgProc) )         
       if IsWindow(CTL(wcEdit)) then DestroyWindow( CTL(wcEdit) )         
    end if
    if OrgLinesProc then 
       var pOrgProc = OrgLinesProc : OrgLinesProc = @DefWindowProc
       SetWindowLongPtr( CTL(wcLines) , GWLP_WNDPROC , cast(LONG_PTR,pOrgProc) )
       if IsWindow(CTL(wcLines)) then DestroyWindow( CTL(wcLines) )
    end if
    PostQuitMessage(0) ' to quit
    return 0
  case WM_NCDESTROY 'Windows was closed/destroyed
    PostQuitMessage(0) ' to quit
  return 0 
  end select
  
  if message = g_FindRepMsg then return Edit_FindReplaceAction( *cptr(FINDREPLACE ptr,lParam) )
  
  ' *** if program reach here default predefined action will happen ***
  return DefWindowProc( hWnd, message, wParam, lParam )
    
end function

function SplitterWndProc( hWnd as HWND, message as UINT, wParam as WPARAM, lParam as LPARAM ) as LRESULT
  const waLocked = 0 , waHorizontal = 2 , waPosition = 4
  
  static as HCURSOR hHorz,hVert
  select case message
  case WM_SETCURSOR
    SetCursor( iif( GetWindowWord( hWnd , waHorizontal ) , hHorz , hVert ) )
  case WM_MOUSEMOVE
    if GetWindowWord( hWnd , waLocked ) then
      var hParent = GetParent( hWnd )
      dim as POINT myPT = type( cshort(LOWORD(lParam)) , cshort(HIWORD(lParam)) )
      MapWindowPoints( hWnd , hParent , @MyPT , 1 )      
      var iPos = iif( GetWindowWord( hWnd , waHorizontal ) , MyPT.x , MyPT.y )
      if GetWindowLong( hWnd , waPosition ) <> iPos then
        SetWindowLong( hWnd , waPosition , iPos )
        dim as NMHDR tHDR
        with tHDR
          .hwndFrom = hWnd
          .idFrom   = GetWindowLong( hWnd , GWL_ID )
          .code     = GetWindowLong( hWnd , waPosition )
        end with
        SendMessage( hParent , WM_NOTIFY , tHDR.idFrom , cast(LPARAM, @tHDR) )        
      end if
    end if
  case WM_SIZE
    _ContinueOnSize:
    dim as RECT tRC = any : GetClientRect( hWnd , @tRC )
    SetWindowWord( hWnd , waHorizontal , (tRC.bottom > tRC.right) )
  case WM_LBUTTONDOWN
    SetWindowWord( hWnd , waLocked , 1 )
    SetCapture( hWnd )    
  case WM_LBUTTONUP, WM_CAPTURECHANGED  
    _ContinueOnButtonUp:
    if GetWindowWord( hWnd , waLocked ) then 
      SetWindowWord( hWnd , waLocked , 0 )
      ReleaseCapture()
    end if
  case WM_CREATE
    if message = WM_CREATE then
      hHorz = LoadCursor( NULL , IDC_SIZEWE )
      hVert = LoadCursor( NULL , IDC_SIZENS )
    end if
    SetWindowWord( hWnd , waLocked , 0 )
    goto _ContinueOnSize  
  case WM_DESTROY
    'KillTimer( hWnd , 1 )
    DestroyCursor( hHorz ) : hHorz = 0
    DestroyCursor( hVert ) : hVert = 0
    goto _ContinueOnButtonUp
  end select
  
  return DefWindowProc( hWnd , message , wParam , lParam )
end function

' *********************************************************************
' *********************** SETUP MAIN WINDOW ***************************
' *********************************************************************
sub WinMain ()
   
   dim tMsg as MSG
   dim tcls as WNDCLASS
   dim as HWND hWnd
  
  '' Setup Splitter class
  with tcls
    .style = 0
    .lpfnWndProc   = @SplitterWndProc
    .cbClsExtra    = 0
    .cbWndExtra    = 8
    .hInstance     = g_AppInstance
    .hIcon         = NULL
    .hCursor       = NULL
    .hbrBackground = cast(HBRUSH,COLOR_3DSHADOW+1)
    .lpszMenuName  = NULL
    .lpszClassName = @"Splitter"
  end with
  
  '' Register the window class     
  if( RegisterClass( @tcls ) = FALSE ) then
  MessageBox( null, "Failed to register wcls!", sAppName, MB_ICONINFORMATION )
  exit sub
  end if
  
  '' Setup window class
  with tcls
    .style         = 0 'CS_HREDRAW or CS_VREDRAW
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
  
  var hMenu = CreateMainMenu()
  var hAcceleratos = CreateMainAccelerators()

  const cStyleEx = WS_EX_ACCEPTFILES or WS_EX_LAYERED 'or WS_EX_COMPOSITED
  const cStyle   = WS_TILEDWINDOW or WS_CLIPSIBLINGS 'or WS_MAXIMIZE or WS_CLIPCHILDREN
  
  hWnd = CreateWindowEx(cStyleEx,sAppName,sAppName, cStyle , _ 
  g_tCfg.lGuiX,g_tCfg.lGuiY,320,200,null,hMenu,g_AppInstance,0)   
  'SetClassLong( hwnd , GCL_HBRBACKGROUND , CLNG(GetSysColorBrush(COLOR_INFOBK)) )
  SetLayeredWindowAttributes( hwnd , GetSysColor(COLOR_INFOBK) , 252 , LWA_COLORKEY )
  
  
  '' Process windows messages
  ' *** all messages(events) will be read converted/dispatched here ***
  
  ShowWindow( hWnd , SW_SHOW )
  UpdateWindow( hWnd )
  
  PostMessage( hWnd , WM_USER+80 , 0,0 )  
  
  dim as HWND hOldFocus = cast(HWND,-1)
  while( GetMessage( @tMsg, NULL, 0, 0 ) <> FALSE )    
    if TranslateAccelerator( hWnd , hAcceleratos , @tMsg ) then continue while      
    if IsDialogMessage( GetActiveWindow() , @tMsg ) then continue while
    TranslateMessage( @tMsg )
    DispatchMessage( @tMsg )    
    ProcessMessage( tMsg )
    var hFocus = GetFocus()
    if hFocus <> hOldFocus then
       static as long iOnce = 0
       if hOldFocus=cast(HWND,-1) then SetForegroundWindow( hWnd )
       hOldFocus = hFocus
       if g_hContainer andalso g_hSearch then
          if hFocus=NULL orelse (hFocus <> g_hSearch andalso hFocus <> g_hContainer andalso hFocus <> CTL(wcEdit)) then
             ShowWindow( g_hContainer , SW_HIDE )
          end if
       end if
    end if
  wend 

  puts("Checking settings")
  if IsWindow( hWnd ) then
    dim as boolean bMaximized = (IsZoomed( hWnd )<>0)
    if bMaximized orelse (IsIconic(hWnd)<>0) then ShowWindow( hWnd , SW_SHOWNORMAL )
    dim as RECT tRcWnd , tRcCli
    GetWindowRect( hWnd , @tRcWnd ) : GetClientRect( hWnd , @tRcCli )
    if bMaximized <> g_tCfg.bGuiMaximized then 
       g_tCfg.bGuiMaximized = bMaximized 
    end if
    if tRcWnd.left <> g_tCfg.lGuiX orelse tRcWnd.top <> g_tCfg.lGuiY then
       g_tCfg.lGuiX = tRcWnd.left : g_tCfg.lGuiY = tRcWnd.top 
    end if
    if tRcCli.right <> g_tCfg.lGuiWid orelse tRcCli.bottom <> g_tCfg.lGuiHei then
       g_tCfg.lGuiWid = tRcCli.right : g_tCfg.lGuiHei = tRcCli.bottom  
    end if
    if IsZoomed(g_GfxHwnd) orelse IsIconic(g_GfxHwnd) then ShowWindow( g_GfxHwnd , SW_SHOWNORMAL )
    GetWindowRect( g_GfxHwnd , @tRcWnd ) : GetClientRect( g_GfxHwnd , @tRcCli )
    if tRcWnd.left <> g_tCfg.lGfxX orelse tRcWnd.top <> g_tCfg.lGfxY then
       g_tCfg.lGfxX = tRcWnd.left : g_tCfg.lGfxY = tRcWnd.top 
    end if
    if tRcCli.right <> g_tCfg.lGfxWid orelse tRcCli.bottom <> g_tCfg.lGfxHei then
       g_tCfg.lGfxWid = tRcCli.right : g_tCfg.lGfxHei = tRcCli.bottom
    end if
  end if   
  SaveSettings()   

end sub

function BeforeExit( dwCtrlType as DWORD ) as WINBOOL   
   GetClipboard() : system() : return 0 'never? :P
end function
SetConsoleCtrlHandler( @BeforeExit , TRUE )

if ParseCmdLine()=0 then 
   sAppName = "LegoScript"
   InitCommonControls()
   if LoadLibrary("Riched20.dll")=0 then
     MessageBox(null,"Failed To Load richedit component",null,MB_ICONERROR)
     end
   end if
   g_FindRepMsg = RegisterWindowMessage(FINDMSGSTRING)
   g_AppInstance = GetModuleHandle(null)  
   
   WinMain() '<- main function
end if

g_DoQuit = 1
puts("Waiting viewer thread")
if g_ViewerThread then ThreadWait( g_ViewerThread )
'TerminateProcess( GetCurrentProcess , 0 )

#if 0
   3865 BP10 #7 s69 = 3001p11 B1 y90 c1;
   B1 s1 = 3001p11 B2 #2 c5;
   B2 s1 = 3001p11 B3 #3 c6;
   B3 c5 = 3001p11 B4 #4 s1;
   B4 c1 = 4070 B5 #5 s2;
   003238a P1 #2 c1 = 003238b P2 #4 s1;
#endif
