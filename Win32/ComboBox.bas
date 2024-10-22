#include "windows.bi"
#include "fbgfx.bi"
#include "fbthread.bi"

#define __Main

'kill exepath+"\PartCache.bin"
#include "Loader\PartSearch.bas"

'https://img.bricklink.com/ItemImage/PL/30473.png
'TODO: improve the tokenizer to keep track of the command token by token
'TODO: make the edit scroll as if it was editing a line
'TODO: (NEED MORE?) check if Brick or Plate? (what about others?)
'TODO: will primative aliases be included in the primative number combo box?

' donor parts (alt + d)
' path parts (alt + p)
' shortcut parts (alt + s)
' color parts (alt + c)
' template parts (alt + t)
' alias parts (alt + a)
' printed parts (alt + shift + p)
' stickered parts (alt + shift + s)
' multi-moulded (alt + m)
' stickers (ctrl+shift+s)

'BUG i cant find 3002.dat (Brick 2L x 3L x 1B) even if I hit all of the above 
' shortcut keys so therefore it does not auto-insert ' B' after the part ID.

dim shared as HWND g_hCon=any,g_hContainer=any  'console/container
dim shared as HWND g_hSearch=any,g_hStatus=any 'controls
dim shared as RECT g_rcCon = any , g_rcSearch
dim shared as POINT rcCursor 
dim shared as long g_ConWid,g_ConHei,g_FntWid,g_FntHei
dim shared as long g_SearchVis , g_SearchRowHei
dim shared as byte g_SearchChanged , g_DoFilterDump

#define g_FilterParts (g_FilterFlags and wIsHidden)
dim shared as long g_FilterFlags = wIsHidden , g_ReverseFilterFlags = 0

rem ------------------------- configuration -----------------------------
   #macro ForEachConfig( _Do )
     _Do( "MaxSearchParts"            , long , cfg_MaxSearchParts            , 50 )
     _Do( "SearchBoxRows"             , byte , cfg_SearchBoxRows             ,  5 )
     _Do( "SearchBoxColumns"          , byte , cfg_SearchBoxCols             ,  5 )
     _Do( "PrimAutoCompleteManual"    , byte , cfg_PrimAutoCompleteManual    ,  1 )
     _Do( "PrimAutoCompleteSelection" , byte , cfg_PrimAutoCompleteSelection ,  1 )
   #endmacro  
     
   #macro DeclareVariable( _UnusedName , _Type , _Variable , _Default )
      dim shared _Variable as _Type = _Default
   #endmacro
   ForEachConfig( DeclareVariable )
   #undef DeclareVariable
   
   const sConfigFilename = "LS_CLI.ini" , sConfigSection = "Config" 
   sub LoadConfig()
      var sConfigFile = exepath+"\"+sConfigFilename
      #macro ReadConfig( _Name , _UnusedType , _Variable , _Default )
         #if typeof(_Variable)=typeof(string)         
            scope
               dim as zstring*4096 zTemp = any
               GetPrivateProfileString(sConfigSection,_Name,_Default,zTemp,sizeof(zTemp),sConfigFile)
               _Variable = zTemp
            end scope
         #else         
            _Variable = GetPrivateProfileInt(sConfigSection,_Name,_Default,sConfigFile)
         #endif
      #endmacro   
      ForEachConfig( ReadConfig )
   end sub
   sub SaveConfig()
      var sConfigFile = exepath+"\"+sConfigFilename
      #macro WriteConfig( _Name , _UnusedType , _Variable , _UnusedDefault )      
         WritePrivateProfileString( sConfigSection , _Name , "" & _Variable , sConfigFile )
      #endmacro
      ForEachConfig( WriteConfig )
   end sub
   LoadConfig() ': SaveConfig()
rem ---------------------------------------------------------------------

function SearchContainerMessages( hWnd as HWND , iMsg as integer , wParam as WPARAM , lParam as LPARAM ) as LRESULT
   select case iMsg
   case WM_CLOSE
      return 0
   case WM_COMMAND
      var hWnd = cast(HWND,lParam)
      var wNotifyCode = HIWORD(wParam) 'notification code 
      select case hWnd
      case g_hSearch
         select case wNotifyCode
         case LBN_SELCHANGE
            g_SearchChanged = true
         end select
      end select
      return 0
   end select
   return DefWindowProc( hWnd , imsg , wParam , lParam)
end function
sub InitSearchWindow()
   g_hCon = GetConsoleWindow()
   var lWidHei = Width()
   g_ConWid = loword(lWidHei) : g_ConHei = hiword(lWidHei)
   GetClientRect(g_hCon,@g_rcCon)
   g_FntWid = g_rcCon.Right\g_ConWid
   g_FntHei = g_rcCon.Bottom\g_ConHei
   
   const SearchContainer = "SearchContainer"
   dim as WNDCLASSEX wx
   var hInstance = GetModuleHandle(0)
   with wx
      .cbSize = sizeof(WNDCLASSEX)
      .lpfnWndProc = cast(any ptr,@SearchContainerMessages)
      .hInstance = hInstance
      .lpszClassName = @SearchContainer
   end with   
   if RegisterClassEx(@wx)=0 then print "Failed to register Class": sleep: system

   const cMainStyle = WS_POPUPWINDOW
   const cStatusStyle = WS_POPUPWINDOW or SS_LEFT or WS_DISABLED or WS_VISIBLE
   const cMainStyleEx = WS_EX_LAYERED or WS_EX_TOPMOST
   const cStyle = WS_CHILD or WS_VISIBLE
   const cListBoxStyle = cStyle or WS_HSCROLL or LBS_MULTICOLUMN or LBS_NOTIFY or LBS_NOINTEGRALHEIGHT 'LBS_DISABLENOSCROLL
   const cTextStyle = cStyle or SS_LEFT ' or SS_SIMPLE
   
   dim as POINT tStatusPT = (0,g_rcCon.Bottom-24)
   ClientToScreen( g_hCon , @tStatusPT )
   g_hStatus = CreateWindowEx( cMainStyleEx , "edit" , NULL , cStatusStyle , tStatusPT.x,tStatusPT.y , g_rcCon.Right,24, g_hCon , NULL , hInstance , NULL)
   g_hContainer = CreateWindowEx( cMainStyleEx, SearchContainer, SearchContainer ,cMainStyle,0, 0, 0, 0,g_hCon , NULL, hInstance, NULL ) 'HWND_MESSAGE   
   g_hSearch = CreateWindowEx( 0 , "listbox" , NULL , cListBoxStyle , 0,0,300,100 , g_hContainer , NULL, hInstance, NULL )
   SetLayeredWindowAttributes( g_hContainer , 0 , 192 , LWA_ALPHA )
   SetLayeredWindowAttributes( g_hStatus , 0 , 192 , LWA_ALPHA )
   
   dim as RECT tRcItem = any
   SendMessage( g_hSearch , LB_ADDSTRING , 0 , cast(LPARAM,@"1") )
   SendMessage( g_hSearch , LB_ADDSTRING , 0 , cast(LPARAM,@"2") )
   SendMessage( g_hSearch , LB_GETITEMRECT , 1 , cast(LPARAM,@tRcItem) )
   SendMessage( g_hSearch , LB_RESETCONTENT , 0,0 )   
   g_SearchRowHei = tRcItem.top
   
   SetForegroundWindow( g_hCon )
      
end sub
sub ProcessMessages()
      
   static as POINT rcOldPt   
   dim as POINT rcPt = rcCursor
   ClientToScreen( g_hCon , @rCpt )
   if rcPt.x <> rcOldPt.x orelse rcPt.y <> rcOldPt.y then
      rcOldPt = rcPt 
      SetWindowPos( g_hContainer , NULL , rcPt.x , rcPt.y ,0,0, SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE )
      GetClientRect( g_hCon , @g_rcCon )
      dim as POINT tStatusPT = (0,g_rcCon.Bottom-24)      
      ClientToScreen( g_hCon , @tStatusPT )
      SetWindowPos( g_hStatus , NULL , tStatusPT.x,tStatusPT.y, g_rcCon.Right,24 , SWP_NOZORDER or SWP_NOACTIVATE )
   end if    
     
   dim as MSG tMsg
   while PeekMessage( @tMsg , NULL , 0,0 , PM_REMOVE )      
      TranslateMessage( @tMsg )      
      DispatchMessage( @tMsg )
      if tMsg.message = WM_LBUTTONDBLCLK then
         dim dwWritten as DWORD , tEvent as INPUT_RECORD 
         tEvent.EventType = KEY_EVENT
         with tEvent.Event.KeyEvent
            .bKeyDown = 1 : .wRepeatCount = 1
            .wVirtualKeyCode = VK_SPACE
            .wVirtualScanCode = fb.SC_SPACE
            .uChar.AsciiChar = asc(" ")
            .dwControlKeyState = 0
         end with            
         WriteConsoleInput( GetStdHandle(STD_INPUT_HANDLE) , @tEvent , 1 , @dwWritten )
         continue while
      end if         
      if tMsg.message = WM_KEYDOWN then
         if (tMsg.wParam = VK_SPACE orelse tMsg.wParam = VK_RETURN orelse tMsg.wParam = VK_BACK) then
            SetForegroundWindow( g_hCon ) 
            if tMsg.wParam = VK_SPACE orelse tMsg.wParam = VK_BACK then 
               dim dwWritten as DWORD , tEvent as INPUT_RECORD 
               tEvent.EventType = KEY_EVENT
               with tEvent.Event.KeyEvent
                  .bKeyDown = 1 : .wRepeatCount = 1
                  .wVirtualKeyCode = tMsg.wParam
                  .wVirtualScanCode = (tMsg.lParam shr 16) and 255
                  .uChar.AsciiChar = iif(tMsg.wParam=VK_BACK,8,asc(" "))
                  .dwControlKeyState = 0
               end with            
               WriteConsoleInput( GetStdHandle(STD_INPUT_HANDLE) , @tEvent , 1 , @dwWritten )
            end if
            continue while
         end if
      end if
   wend
end sub

type FilteredListDump
   #define DeclareStringPerFlag( _Name , _Bit ) as string sIs##_Name
   ForEachPartFlag( DeclareStringPerFlag )
   #undef StringPerFlag
end type

static shared as FilteredListDump tFilteredDump
static shared as long g_iFilteredCount

function GetPartDescription( iPart as long ) as string
   var pPart = PartStructFromIndex(iPart)   
   var sDesc = trim(pPart->zDesc), iPos=0      
   'if g_FilterParts then return sDesc
   while sDesc[iPos] = asc("~") 'process special command
      const sMoved = "moved to "
      var iMoved = instr(iPos+1,lcase(sDesc),sMoved)
      if iMoved then
         var iPart2 = SearchPart(mid(sDesc,iMoved+len(sMoved)))         
         if iPart2 then            
            pPart = PartStructFromIndex(iPart2)                  
            var iPos2 = len(sDesc)+2
            sDesc = left(sDesc,iPos)+mid(sDesc,iPos+2) & " > " & pPart->zDesc
            iPos = iPos2
            continue while
         end if
      end if
      exit while
   wend
   'print pPart->zName
   if pPart->iFolder=2 then return "[Unnoficial] "+sDesc
   return " "+sDesc
end function
function IsPartFiltered( pPart as SearchPartStruct ptr ) as boolean   
   if pPart=NULL then return true
   with *pPart
      if g_ReverseFilterFlags andalso (.wFlags and g_ReverseFilterFlags)=0 then return true
      if (.wFlags and g_FilterFlags) then return true      
      
      if g_FilterParts=false then return false   
      var sPart = pPart->zName
      var sPartID = left(sPart,instr(sPart,".")-1)
      var iLenID = len(sPartID)
      if iLenID < 3 then return false
      
      'filter if part ends with c## or s##
      if g_FilterParts then
         for N as long = -4 to -3
            select case sPartID[iLenID+N]
            case asc("c"),asc("p")
               for M as long = N+1 to -1
                 if IsDigit(sPartID[iLenID+M])=0 then continue for,for
               next M
               return true
            end select
         next N
      end if
   end with
   return false
   
end function
function UpdateSearch(sSearch as string) as long
   dim as long iPart = -1, iFound = 0
      
   SendMessage( g_hSearch , WM_SETREDRAW , false , 0 )
   SendMessage( g_hSearch , LB_RESETCONTENT , 0,0 )
   
   var hDC = GetDC(g_hSearch)
   var hFont = cast(HFONT , SendMessage( g_hSearch , WM_GETFONT , 0 , 0 ))
   var iBigWid = 0, iCharWid = 0
   SelectObject( hDC , hFont )
   
   dim as SIZE tSize
   g_iFilteredCount = 0
   for N as long = 0 to (1 shl 24) 'cfg_MaxSearchParts-1      
      iPart = SearchPart(sSearch,iPart)
      if iPart<0 then exit for
      var pPart = PartStructFromIndex(iPart)         
      var sName = pPart->zName
      if IsPartFiltered(pPart) then 
         if g_DoFilterDump then
            #macro AddToFlagListDump( _Name , _Bit ) 
               if ((pPart->wFlags and g_FilterFlags) and wIs##_Name) then tFilteredDump.sIs##_Name &= !"\n" & sName
            #endmacro        
            ForEachPartFlag( AddToFlagListDump )
         end if
         g_iFilteredCount += 1 : continue for
      end if      
      var sDesc = GetPartDescription(iPart)
      'sDesc[0]=asc("~")
      if g_FilterParts andalso (sDesc[0]=asc("=") orelse sDesc[0]=asc("_")) then g_iFilteredCount += 1 : continue for
      if N >= cfg_MaxSearchParts then continue for
      if SendMessage( g_hSearch , LB_FINDSTRING , 0 , cast(LPARAM,strptr(sName)) ) <> LB_ERR then         
         sName = "Unoff\"+sName
      end if
      GetTextExtentPoint32( hDC , sName , len(sName) , @tSize )
      if iCharWid=0 then iCharWid = tSize.CX\len(sName)
      if tSize.CX >  iBigWid then iBigWid = tSize.CX      
      var iIdx = SendMessage( g_hSearch , LB_ADDSTRING , 0 , cast(LPARAM,strptr(sName)) )
      SendMessage( g_hSearch , LB_SETITEMDATA  , iIdx , iPart )      
      if iFound=0 then SetWindowText( g_hStatus , " " & sDesc )
      iFound += 1
      
   next    
      
   'change search list size to accomodate the number of entries found (max 4,3)
   var iRows = iif(iFound>cfg_SearchBoxRows,cfg_SearchBoxRows,iFound)
   var iCols = (iFound+(cfg_SearchBoxRows-1))\cfg_SearchBoxRows
   var iScrollHei = iif( iCols>(cfg_SearchBoxCols-1)  , GetSystemMetrics(SM_CYVTHUMB)+2 , 0 )
   if iCols > (cfg_SearchBoxCols-1) then iCols = (cfg_SearchBoxCols-1)
   if iScrollHei then 'force enable/disable scroll to prevent control calculating wrong
      SetWindowLong( g_hSearch , GWL_STYLE , GetWindowLong( g_hSearch ,GWL_STYLE) or WS_HSCROLL )
   else
      SetWindowLong( g_hSearch , GWL_STYLE , GetWindowLong( g_hSearch ,GWL_STYLE) and (not WS_HSCROLL) )
   end if
   SetWindowPos( g_hSearch , NULL , 0,0 , (iBigWid+iCharWid)*iCols , iRows*g_SearchRowHei+iScrollHei , SWP_NOMOVE or SWP_NOZORDER or SWP_NOACTIVATE ) 
   dim as POINT rCpt = rcCursor
   ClientToScreen( g_hCon , @rCpt )
   GetWindowRect( g_hSearch , @g_rcSearch )
   g_rcSearch.right -= g_rcSearch.left : g_rcSearch.bottom -= g_rcSearch.top   
   SetWindowPos( g_hContainer , NULL , rcPt.x , rcPt.y , g_rcSearch.right , g_rcSearch.bottom , SWP_NOZORDER or SWP_NOACTIVATE )      
   
   SendMessage( g_hSearch , WM_SETREDRAW , true , 0 )
   if iFound then
      SendMessage( g_hSearch , LB_SETCOLUMNWIDTH , iBigWid+iCharWid , 0 )
      var sStemp = sSearch+".dat"
      var iIdx = SendMessage( g_hSearch , LB_FINDSTRINGEXACT , 0 , cast(lparam,strptr(sStemp)) )
      if iIDX <> LB_ERR then SendMessage( g_hSearch , LB_SETCURSEL , iIdx , iIdx )
   end if   
   'InvalidateRect( g_hSearch , NULL , TRUE )
   return iFound
end function
sub ShowDumpTextFile( Dummy as any ptr )
   var sDumpFile = exepath()+"\FilteredParts.txt"
   shell sDumpFile
end sub
sub DumpFilteredParts( sSearch as string )
   if len(sSearch)<2 then exit sub   
   g_DoFilterDump = 1 : UpdateSearch(sSearch) : g_DoFilterDump = 0
   var sDumpFile = exepath()+"\FilteredParts.txt"
   var f = freefile()
   if open(sDumpFile for output as #f) then exit sub 'failed to open for write
   with tFilteredDump
      #macro DumpFlagList( _Name , _Bit ) 
         if len(.sIs##_Name) then
            print #f, "[" #_Name "]";.sIs##_Name
            .sIs##_Name = ""
         end if
      #endmacro
      ForEachPartFlag( DumpFlagList )
   end with
   close #f
   ThreadDetach(ThreadCreate( @ShowDumpTextFile , NULL ))
end sub

function QueryText( sTextOrg as string ) as long   
   dim as long ConWid = width(), ConHei = hiword(ConWid)   
   ConWid = loword(ConWid)
   
   dim as string sText = sTextOrg , sToken = "" , sStatusText = ""
   dim as long iLin=csrlin(),iCol=pos(),iViewWid=ConWid-iCol
   dim as long iStart=0,iCur=len(sText)
   dim as byte bChanged=1,bReCalcTokens=true,iTokCnt=any,iCurTok=any,iMaxTok=8
   dim as long iTokStart=1,iTokEnd=1,iPrevLen=len(sText)
   redim as string sTokenTxt(iMaxTok-1)
      
   var hPrevFore = GetForegroundWindow()   
         
   do
      var sKey = inkey()
      if len(sKey)=0 then 
         var hForeground = GetForegroundWindow()         
         if hForeground <> hPrevFore then
            #if 0 'debug for Window change...
               scope
                  dim as zstring*256 wintit=any, wincls=any
                  GetWindowText(hForeground,wintit,256)
                  GetClassName(hForeground,wincls,256)
                  dim as DWORD dwPid
                  GetWindowThreadProcessID( hForeground , @dwPid )
                  SetWindowText( GetConsoleWindow() , "Fore:Pid=" & dwPid & "/" & GetCurrentProcessID & " '" & wintit & "(" & wincls & ")"  )
               end scope
               sleep 250
            #endif
            if hForeground = g_hCon orelse hForeground = g_hContainer then
               ShowWindow( g_hContainer , g_SearchVis   )
               ShowWindow( g_hStatus    , SW_SHOWNA   )
            else
               if hPrevFore = g_hCon orelse hPrevFore = g_hContainer then
                  ShowWindow( g_hContainer , SW_HIDE )
                  ShowWindow( g_hStatus    , SW_HIDE )
               end if
            end if
            hPrevFore = hForeground
         end if
         'split tokens and count
         static as string sCaption
         if bChanged orelse bReCalcTokens then
            bReCalcTokens=false
            dim as long I = 1,iStart=0
            iTokCnt = 0 : iCurTok = 0            
            do
               while asc(sText,I)=32 : I+= 1 : wend
               iStart = I      
               while asc(sText,I)<>32 andalso asc(sText,I)<>0 : I+= 1 : wend
               if I <> iStart then
                  if (iCur+1)>=iStart andalso iCur<=I then iCurTok = iTokCnt
                  sTokenTxt(iTokCnt) = mid(sText,iStart,I-iStart)
                  iTokCnt += 1
                  if iTokCnt = iMaxTok then 
                     iMaxTok += 8 : redim preserve sTokenTxt(iMaxTok-1)
                  end if
               end if
            loop while asc(sText,I)
            
            'chk tokens
            sCaption = iCur & " > Tokens: " & iTokCnt & "(" & iCurTok & ") " & iTokStart & "-" & iTokEnd & " {"
            for I=0 to iTokCnt-1
               if I then sCaption += ","
               if I=iCurTok then
                 sCaption += "['"+sTokenTxt(I)+"']"
               else
                  sCaption += "'"+sTokenTxt(I)+"'"
               end if
            next I            
            
         end if
            
         if g_SearchChanged then 'if search selection changed update everything else
            g_SearchChanged = false
            var iSel   = SendMessage( g_hSearch , LB_GETCURSEL , 0 , 0 )
            var iPart = SendMessage( g_hSearch , LB_GETITEMDATA , iSel , 0 )
            var pPart = PartStructFromIndex(iPart), sPart = pPart->zName
            sPart = left(sPart,instrrev(sPart,".")-1)
            SetWindowText( g_hStatus , GetPartDescription(iPart) )
            sText = left(sText,iTokStart-1)+sPart+mid(sText,iTokEnd+1)
            iCur = (iTokStart-1)+len(sPart)
            if bChanged=0 then bChanged=-1 'changed but don't need to research
         end if
         if bChanged then            
            
            'update the screen
            var iExtra = iPrevLen-len(sText)
            if iExtra < 1 then iExtra = 0
            iPrevLen = len(sText)
            locate iLin,iCol: print mid(sText+space(iExtra),iStart+1,iViewWid)
            locate iLin,iCol+iCur-iStart
            
            'grab current token
            iTokStart = instrrev(sText," ",iCur)+1
            iTokEnd   = instr(iCur+1,sText," ")-1
            if iTokEnd <= 0 then iTokEnd = len(sText)
            sToken = mid(sText,iTokStart,(iTokEnd-iTokStart)+1)
            'SetWindowText( GetConsoleWindow() , iTokStart & "," & iTokEnd & " '"+sToken+"'")
            
            if bChanged=1 then
               g_SearchVis = iif( len(sToken)>1 andalso UpdateSearch(sToken) , SW_SHOWNA , SW_HIDE )
               ShowWindow( g_hContainer , g_SearchVis )               
               if g_SearchVis = SW_HIDE then SetWindowText( g_hStatus , sStatusText )
               rcCursor.x = pos()*g_FntWid : rcCursor.y = csrlin()*g_FntHei
            end if
            
            bChanged=0
                        
            var sFilters = " Filters:"
            if g_FilterFlags andalso IsWindowVisible(g_hContainer) then
               #define ListFilteredFlags( _Name , _Bit ) if g_FilterFlags and wIs##_Name then sFilters += " " #_Name
               ForEachPartFlag( ListFilteredFlags )
            end if
            if sFilters=" Filters:" then sFilters="" else sFilters += "(" & g_iFilteredCount & " filtered)"
            SetWindowText( GetConsoleWindow() , sCaption+"}"+sFilters)
            
         end if
         
         sleep 10,1 : ProcessMessages() : continue do
      end if
      dim as long iKey = sKey[0]
      if iKey=255 then iKey = -sKey[1]      
      #define _alt(_K)  (-fb.SC_##_K)
      #define _ctrl(_K) (1+asc(#_K)-asc("A"))
      #define _shift (GetKeyState(VK_SHIFT) shr 1)      
      select case iKey      
      case 8             'backspace - remove character from left
         if iCur>0 then 
            'if sText[iCur-1]=32 then bReCalcTokens=true 'recalc every space
            sText = left(sText,iCur-1)+mid(sText,iCur+1)
            iCur -= 1 : bChanged = 1
         end if
      case -fb.SC_DELETE 'delete    - remove character from right
         if iCur<len(sText) then
            'if sText[iCur]=32 then bReCalcTokens=true 'recalc every space
            sText = left(sText,iCur)+mid(sText,iCur+2)
            bChanged = 1
         end if
      case 9,-15         'tab        - auto complete (-15 = shift+tab)
         if len(sToken)>1 then
            var iCount = SendMessage( g_hSearch , LB_GETCOUNT , 0 , 0 )
            var iSel   = SendMessage( g_hSearch , LB_GETCURSEL , 0 , 0 )
            var iSelOrg = iSel
            if iSel = LB_ERR then iSel=0 else iSel = (iSel+iCount+iif(iKey=9,1,-1)) mod iCount
            SendMessage( g_hSearch , LB_SETCURSEL , iSel , 0 )
            g_SearchChanged = true
         end if
      case 13            'enter      - finish editing
         sTextOrg = sText : return 1
      case 27            'escape     - cancels editing
         return 0
      case _alt(D)       'alt+D      - toggle filtering for Donor parts
         g_FilterFlags xor= wIsDonor    : bChanged = 1
      case _alt(P)       'alt+P      - toggle filtering for Path/Printed parts
         g_FilterFlags xor= iif(_shift,wIsPrinted,wIsPath)          : bChanged = 1
      case _alt(S)       'alt+S      - toggle filtering for Shortcut/Stickered parts
         g_FilterFlags xor= iif(_shift,wIsStickered,wIsShortcut)    : bChanged = 1
      case _alt(C)       'alt+C      - toggle filtering for MultiColored/PreColored parts
         g_FilterFlags xor= iif(_shift,wIsPreColored,wIsMultiColor) : bChanged = 1
      case _alt(T)       'alt+T      - toggle filtering for template parts
         g_FilterFlags xor= wIsTemplate : bChanged = 1
      case _alt(A)       'alt+A      - toggle filtering for alias parts
         g_FilterFlags xor= wIsAlias    : bChanged = 1
      case _alt(M)       'alt+M      - toggle filtering for multi-moulded parts
         g_FilterFlags xor= wIsMoulded  : bChanged = 1         
      case _alt(H)       'alt+H      - toggle filtering for helper parts
         g_FilterFlags xor= wIsHelper   : bChanged = 1         
      case _alt(F)       'alt+F      - toggle part filtering
         g_FilterFlags xor= wIsHidden   : bChanged = 1      
      case _ctrl(S)      'ctrl+S     - toggle filtering for sticker parts
         g_FilterFlags xor= wIsSticker  : bChanged = 1      
      case _ctrl(F)      'ctrl+F     - clear all filters
         g_FilterFlags=0 : bChanged = 1
      case _ctrl(D)      'ctrl+D     - dump ???? / filtered names
         if _shift then 'filtered names
            DumpFilteredParts(sToken)
         else ' ????
            rem
         end if         
      case -fb.SC_HOME   'home       - move cursor to start
         if iCur then iCur=0 : locate iLin,iCol+iCur-iStart : bChanged = 1
      case -fb.SC_END    'end        - move cursor to end
         if iCur<>len(sText) then iCur=len(sText) : locate iLin,iCol+iCur-iStart : bChanged = 1
      case -fb.SC_LEFT   'left       - move cursor to previous character
         if iCur>0 then 
            iCur -= 1 : locate iLin,iCol+iCur-iStart 
            if sText[iCur]=32 then bChanged = 1
         end if
      case -115          'ctrl+left  - move cursor to previous token
         if iCur>0 then
            if sText[iCur-1]=32 then
               do : iCur -= 1 : loop while iCur andalso sText[iCur]=32
            else
               do : iCur -= 1 : loop while iCur andalso sText[iCur]<>32
            end if               
            bChanged = 1
         end if
      case -fb.SC_RIGHT  'right      - move cursor to next character
         if iCur<len(sText) then 
            iCur += 1 : locate iLin,iCol+iCur-iStart 
            if sText[iCur]=32 then bChanged = 1
         end if
      case -116          'ctrl+right - move cursor to next token
         if iCur<len(sText) then
            if sText[iCur+1]=32 then
               do : iCur += 1 : loop while iCur<len(sText) andalso sText[iCur]=32
            else
               do : iCur += 1 : loop while iCur<len(sText) andalso sText[iCur]<>32
            end if               
            bChanged = 1
         end if
      case is < 32       'special    - ignore all other special keys
        SetWindowText( GetConsoleWindow() , "Special = " & iKey )
      case else          'printable  - add to the string
         ''if iKey<>32 andalso (len(sText)=0 orelse sText[iCur-1]=32) then bReCalcTokens=true 'recalc every space
         ''if iKey=32 then bRecalcTokens=true
         if iKey=32 then
            if g_SearchVis=SW_SHOWNA andalso iCur=iTokEnd then
               var iSel  = SendMessage( g_hSearch , LB_GETCURSEL , 0 , 0 )               
               if iSel <> LB_ERR then               
                  var iPart = SendMessage( g_hSearch , LB_GETITEMDATA , iSel , 0 )                  
                  var sDesc = GetPartDescription( iPart )
                  for N as long = 0 to len(sDesc)-1
                     select case sDesc[N]
                     case asc("0") to asc("9"),asc("A") to asc("Z"),asc("a") to asc("z"): exit for
                     end select
                     sDesc[N]=asc(" ")
                  next N                  
                  if instr(sDesc,"hinge")=0 then
                     if instr(sDesc," plate") then 
                        sKey += "P"                  
                     elseif instr(sDesc," brick") then
                        sKey += "B"
                     end if
                  end if
               end if
            end if
         end if
         sText = left(sText,iCur)+sKey+mid(sText,iCur+1) 
         iCur += len(sKey): if iCur>iViewWid then iStart = iViewWid-iCur         
         bChanged = 1
      end select
   loop
end function       

InitSearchWindow()

dim as string sText

QueryText(sText)
