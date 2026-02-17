#ifndef _u
  #define _u(_text) @wstr(_text)
#endif
function MsgBox cdecl ( pwText as wstring ptr , pwCaption as wstring ptr  = _u("Attention!") , iIcon as long = 0 , iButtons as long = 1 , pwBtn1 as wstring ptr = _u("ok") , pwBtn2 as wstring ptr = NULL , pwBtn3 as wstring ptr = NULL ) as long
  Dim tdc as TASKDIALOGCONFIG = type( sizeof(TASKDIALOGCONFIG) )
  Dim as long nButton = (iButtons and 7)
  
  if nButton < 0 then nButton = 0
  if nButton > 3 then nButton = 3
  
  '' Define the custom buttons
  Dim buttons(0 to 2) as TASKDIALOG_BUTTON
  for N as long = 0 to nButton-1    
    buttons(N).nButtonID = 101+N
    buttons(N).pszButtonText = (@pwBtn1)[N]
  next N  
  
  dim as HICON hQuest = LoadIcon(NULL, IDI_QUESTION)

  '' Setup the Config Structure
  with tdc    
    .hwndParent = GetDesktopWindow() 'CTL(wcMain))
    .dwFlags = TDF_ALLOW_DIALOG_CANCELLATION' or TDF_POSITION_RELATIVE_TO_WINDOW
    '.dwFlags or= TDF_SIZE_TO_CONTENT
    .pszWindowTitle = pwCaption : .pszMainInstruction = pwText
    .pszContent = NULL '@wstr("???") '@wstr("If you don't save, your work will be lost.")
    select case iIcon
    case MB_ICONWARNING     : .hMainIcon = cast(any ptr,TD_WARNING_ICON)
    case MB_ICONINFORMATION : .hMainIcon = cast(any ptr,TD_INFORMATION_ICON) 
    case MB_ICONERROR       : .hMainIcon = cast(any ptr,TD_ERROR_ICON)
    case MB_ICONQUESTION    : .hMainIcon = hQuest : .dwFlags or= TDF_USE_HICON_MAIN
    end select
    .cButtons = nButton : .pButtons = @buttons(0)
  end with
  
  TaskDialogIndirect(@tdc, @nButton, NULL, NULL)
  if hQuest then DestroyIcon( hQuest )
  
  if nButton >= 101 andalso nButton < (101+iButtons) then return nButton-100
  return -1  

End function

function GetControlText( iID as long ) as string
  var hwnd = CTL(iID)
  dim as string sText = space( GetWindowTextLength( hwnd ) )
  GetWindowText( hwnd , strptr(sText) , len(sText)+1 )
  return sText
end function

sub NotifySelChange( iID as long )   
   var hCTL = CTL( iID ), hParent = GetParent(hCTL)
   dim as SELCHANGE tSelChange           
   SendMessage( hCTL , EM_EXGETSEL , 0 , cast(LPARAM,@tSelChange.chrg) )
   tSelChange.seltyp = SendMessage( hCTL , EM_SELECTIONTYPE   , 0 , 0 )   
   with tSelChange.nmhdr
      .hwndFrom = hCTL : .idFrom = iID : .code = EN_SELCHANGE
   end with
   SendMessage( hParent , WM_NOTIFY , iID , cast(LPARAM,@tSelChange) )   
end sub
#if 0
sub Btn_Trigger( iID as long )
  if iID=0 then exit sub
  PostMessage( CTL(iID) , BM_CLICK , 0 , 0 )
end sub
#endif
function LoadFileIntoEditor( sFile as string , bCreate as boolean=false ) as boolean
   
   dim as string sScript   
   if bCreate=false andalso LoadScriptFile( sFile , sScript )=false then
      MessageBox( CTL(wcMain) , !"Failed to open:\n\n'"+sFile+"'" , NULL , MB_ICONERROR )
      return false
   end if   
      
   SetWindowText( CTL(wcEdit) , sScript ) : sScript=""
   g_CurrentFilePath = sFile
   SetWindowText( CTL(wcMain) , sAppName + " - " + sFile )
   'NotifySelChange( wcEdit )
   SetFocus( CTL(wcButton) )
   Sendmessage( CTL(wcEdit) , EM_SETMODIFY , 0,0 )
   return true
end function

const cCloseLen = 4

function GetTabName( iTab as long ) as string
   with g_tTabs(iTab)
      dim as zstring*64 zName = any : zName[0]=0
      dim as TC_ITEM tItem = type( TCIF_TEXT )
      tItem.pszText = @zName : tItem.cchTextMax = sizeof(zName)-1
      TabCtrl_GetItem( CTL(wcTabs) , g_iCurTab , @tItem )
      if iTab = g_iCurTab then
         return left(zName,len(zName)-cCloseLen)
      else
         return zName
      end if
   end with
end function
sub UpdateMainWindowCaption()
   with g_tTabs(g_iCurTab)
      if len(.sFilename) then 
         SetWindowText( CTL(wcMain) , sAppName + " - " + .sFilename )
      else
         dim as zstring*64 zName = any : zName[0]=0
         dim as TC_ITEM tItem = type( TCIF_TEXT )
         tItem.pszText = @zName : tItem.cchTextMax = sizeof(zName)-1
         TabCtrl_GetItem( CTL(wcTabs) , g_iCurTab , @tItem )
         zName = left(zName,len(zName)-cCloseLen)
         SetWindowText( CTL(wcMain) , sAppName + " - " +zName)
      end if
   end with
end sub
sub UpdateTabCloseButton() 
   dim as POINT tPt(1) = any
   dim as RECT tRc = any : GetClientRect( CTL(wcMain) , @tRc )
   TabCtrl_GetItemRect( CTL(wcTabs) , g_iCurTab , cptr(RECT ptr,@tPt(0)) )
   var hFont = cast(HFONT,SendMessage( CTL(wcTabs) , WM_GETFONT , 0,0 ))
   if hFont=0 then end
   var hDC = GetDC(0) , hOrgFont = SelectObject( hDC , hFont )      
   dim as SIZE tSz = any : GetTextExtentPoint32( hDC , @"        " , cCloseLen , @tSz )
   tPt(1).x += g_tMainCtx.hCTL( wcTabs ).iX
   with g_tMainCtx.hCTL( wcBtnClose )      
      .iX = tPt(1).x-.iW : .iW = tSz.cx : .iH = tSz.cy : .iY = ((tPt(1).y-tPt(0).y)-.iH)\2
      SetWindowPos( CTL(wcBtnClose) , 0 , .iX,.iY , .iW,.iH , SWP_NOZORDER or SWP_NOACTIVATE )
      InvalidateRect( CTL(wcBtnClose) , NULL , true )
   end with
   SelectObject( hDC , hOrgFont )
   ReleaseDC( NULL , hDC )
end sub
sub ChangeToTab( iNewTab as long , bForce as boolean = false )    
   if iNewTab < 0 orelse iNewTab >= g_iTabCount then puts("out of bounds tabs"): exit sub
   'var iCurTab = TabCtrl_GetCurSel( CTL(wcTabs) )   
   'if bForce=0 andalso iCurTab = iNewTab then exit sub
   with g_tTabs(iNewTab)                  
      var hWndOld = CTL(wcEdit) , hParent = GetParent(.hEdit)
      if hWndOld = .hEdit then UpdateTabCloseButton() : exit sub
      var iModifyOld = SendMessage( hWndOld , EM_GETMODIFY , 0 , 0 )
      var iModifyNew = SendMessage( .hEdit , EM_GETMODIFY , 0 , 0 )
      var hFont = g_tMainCtx.hFnt(g_tMainCtx.hCtl(wcEdit).bFont).hFont
      CTL(wcEdit) = .hEdit : g_iCurTab = iNewTab
      'swap control IDs (so that only one control have the current tab ID)
      SetWindowLong( hWndOld , GWL_ID , 0 ) : SetWindowLong( .hEdit  , GWL_ID , wcEdit )      
      dim as RECT tRC = any : GetWindowRect( hWndOld , @tRC )      
      ScreenToClient( hParent , cast(POINT ptr,@tRC)+0 )
      ScreenToClient( hParent , cast(POINT ptr,@tRC)+1 )
      g_bChangingFont = true      
      SendMessage( .hEdit , WM_SETFONT , cast(WPARAM,hFont) , false ) 'this causes SelChange and SetModify O.o
      g_bChangingFont = false
      SetWindowPos( .hEdit , 0 , tRC.left , tRc.top , tRc.right-tRc.left , tRc.Bottom-tRc.top , SWP_NOZORDER or SWP_SHOWWINDOW )
      ShowWindow( hWndOld , SW_HIDE )
      g_CurrentFilePath = .sFilename      
      TabCtrl_SetCurSel( CTL(wcTabs) , iNewTab )
      UpdateMainWindowCaption()
      'NotifySelChange( wcEdit )
      SetFocus( CTL(wcEdit) )
      UpdateTabCloseButton()
      SendMessage( hWndOld , EM_SETMODIFY , iModifyOld , 0 )
      SendMessage( .hEdit , EM_SETMODIFY , iModifyNew , 0 )
   end with   
   'puts("new tab: " & iNewTab & " Tabs: " & g_iTabCount & " ? " & TabCtrl_GetItemCount( CTL(wcTabs) ) )
   if g_iTabCount <> TabCtrl_GetItemCount( CTL(wcTabs) ) then puts("{{Tab count mismatch!!!}}")
end sub
function CloneHwnd( hWnd as HWND , iIncStyles as integer = 0 ) as HWND
   var wClass   = cast(zstring ptr , GetClassLong( hWnd , GCW_ATOM ) )
   var hInst    = cast(HINSTANCE, GetWindowLong(hWnd,GWL_HINSTANCE))
   var hParent  = cast(HWND     , GetWindowLong(hWnd,GWL_HWNDPARENT))
   var lStyle   = GetWindowLong(hWnd,GWL_STYLE)   
   var lStyleEx = GetWindowLong(hWnd,GWL_EXSTYLE)
   return CreateWindowEx( lStyleEx , wClass , NULL , lStyle or iIncStyles , 0,0,0,0 , hParent , 0 , hInst , NULL )
end function

#define ResetTabCount() GetNewTabName(true)
const sNoName = "Untitled"
function GetNewTabName(bReset as boolean=false) as string
   static as long iNum : iNum += 1         
   if g_iTabCount=1 then iNum=1
   if bReset then iNum=0 : return ""
   return iif( iNum=1 , sNoName , sNoName & iNum )
end function   
sub UpdateTabName( iTab as long )
   if cuint(iTab) >= g_iTabCount then exit sub   
   with g_tTabs(iTab)
      dim as string sFile
      if len(.sFilename) then
         sGetFilename( .sFilename , sFile )         
      else
         sFile = GetNewTabName()         
      end if
      sFile += space(cCloseLen)
      dim as TC_ITEM tItem = type( TCIF_TEXT , 0,0 , strptr(sFile) , 0,-1 , 0 ) 
      TabCtrl_SetItem( CTL(wcTabs) , iTab , @tItem )   
      if iTab = g_iCurTab then 
         UpdateTabCloseButton()
         UpdateMainWindowCaption()
      end if
      InvalidateRect( CTL(wcTabs) , null , true )
   end with   
end sub
function NewTab( sNewFile as string , iLinked as long = -1 , iReplaceTab as long = -1 ) as long   
   var iNewTab = g_iCurTab , sFile = sNewFile 'byval
   if iReplaceTab > -1 then iNewTab = iReplaceTab
   'puts("Cur tab = " & g_iCurTab)
   if iLinked < -1 then iLinked = -1 else if iLinked >= g_iTabCount then iLinked = -1
   'if the current tab is empty and it's not linked and ....
   'if we're not linking to tab then reuse same tab instead of creating a new one
   var bIsLinked = (g_tTabs(g_iCurTab).iLinked <> -1)
   var bHasText  = SendMessage( CTL(wcEdit) , EM_GETMODIFY , 0,0 )<>0
   var bHaveName = len(g_tTabs(g_iCurTab).sFilename)
   if iReplaceTab=-1 andalso (iLinked<>-1 orelse bIsLinked orelse bHaveName orelse bHasText) then      
      'puts("New tab")
      iNewTab = TabCtrl_GetItemCount( CTL(wcTabs) ) 'g_iTabCount 'create new TAB
      redim preserve g_tTabs(g_iTabCount) : g_iTabCount += 1
      if iLinked <> -1 then
         iNewTab = iLinked+1
         while iNewTab < (g_iTabCount-1) andalso g_tTabs(iNewTab).iLinked = iLinked
            iNewTab += 1
         wend         
         for N as long = 0 to (g_iTabCount-2)
            if g_tTabs(N).iLinked > iLinked then g_tTabs(N).iLinked += 1
         next N         
         for N as long = (g_iTabCount-1) to iLinked+1 step -1
            g_tTabs(N) = g_tTabs(N-1)
         next N
      end if         
      var cStyle = ES_MULTILINE or ES_WANTRETURN or WS_HSCROLL or WS_VSCROLL or ES_AUTOHSCROLL or ES_DISABLENOSCROLL or ES_NOHIDESEL
      var hWnd = CloneHwnd( CTL(wcEdit) , cStyle )
      SetWindowTheme( hWnd , "" , "" )
      g_tTabs( iNewTab ).hEdit = hWnd
      SendMessage( hWnd , EM_EXLIMITTEXT , 0 , 16*1024*1024 ) '16mb text limit
      SendMessage( hWnd , EM_SETEVENTMASK , 0 , ENM_CLIPFORMAT or ENM_SELCHANGE or ENM_KEYEVENTS ) ' or ENM_SCROLL )
      SendMessage( hWnd , EM_SETMODIFY , 0 , 0 )
      dim as TC_ITEM tItem = type( TCIF_TEXT , 0,0 , @"   " , 0,-1 , 0 )
      TabCtrl_InsertItem( CTL(wcTabs) , iNewTab , @tItem )
   else
      'puts("Same tab")
   end if
      
   with g_tTabs(iNewTab)
      .iLinked = iLinked
      if iLinked <> -1 then
         dim as zstring*384 zName = any
         dim as TC_ITEM tItem = type( TCIF_TEXT , 0,0 , @zName,384,-1 , 0 ) 
         TabCtrl_GetItem( CTL(wcTabs) , iLinked , @tItem )      
         zName = left(zName,len(zName)-cCloseLen)
         var iPosi = instrrev(zName,".") : if iPosi=0 then iPosi = len(zName)+1
         sFile = left(zName,iPosi-1)+"_1"+mid(zName,iPosi)
      elseif len(sFile) then      
         var iPos = instrrev(sFile,"\") , iPos2 = instrrev(sFile,"/")
         if iPos2 > iPos then iPos = iPos2         
         .sFilename = sFile
         sFile = mid(sFile,iPos+1)         
      else                              
         dim as zstring*64 zName = any : zName[0]=0
         dim as TC_ITEM tItem = type( TCIF_TEXT )
         tItem.pszText = @zName : tItem.cchTextMax = sizeof(zName)-1
         TabCtrl_GetItem( CTL(wcTabs) , iNewTab , @tItem )         
         #define WasNew (left(zName,len(sNoName))=sNoName andalso right(zName,cCloseLen) = space(cCloseLen))
         sFile = iif(WasNew,"",GetNewTabName())
         'puts("new name: "+sFile & " (" & iNewTab & ")") 
         .sFilename = ""               
      end if
      if len(sFile) then
         sFile += space(cCloseLen)
         dim as TC_ITEM tItem = type( TCIF_TEXT , 0,0 , strptr(sFile) , 0,-1 , 0 ) 
         TabCtrl_SetItem( CTL(wcTabs) , iNewTab , @tItem )
      end if
   end with
   InvalidateRect( CTL(wcTabs) , NULL , true )   
   return iNewTab
end function
sub LoadScript( sFile as string )   
   var sFileL = lcase(sFile)
   
   if right(sFileL,4)=".ldr" then
      if g_Show3D=0 then Menu.Trigger( meView_ToggleGW )
      Viewer.LoadFile(sFile)
      exit sub
   end if
   
   for N as long = 0 to g_iTabCount-1
      with g_tTabs(N)
         'puts "'"+lcase(.sFileName)+"' = '"+sFileL
         if lcase(.sFileName) = sFileL then
            ChangeToTab(N): exit sub
         end if
      end with
   next N      
   var bCreate = len(sFile) andalso sFile[0] = asc(":")
   if bCreate then sFile = mid(sFile,2)   
   ChangeToTab(NewTab( sFile ))
   LoadFileIntoEditor( sFile , bCreate )
end sub
sub ChangeToTabByFile( sFullPath as string , iLine as long = -1 )
   dim as long iTab = -1 'not found
   if len(sFullPath)=0 then exit sub 
   if sFullPath[0] = asc("*") then
      iTab = g_iCurTab
   else
      var sPathL = lcase(sFullPath)
      for N as long = 0 to g_iTabCount-1
         if lcase(g_tTabs(N).sFilename)=sPathL then iTab = N : exit for         
      next N
   end if
   if iTab = -1 then
      if FileExists( sFullPath ) then
         ChangeToTab(NewTab( sFullPath ))
         LoadFileIntoEditor( sFullPath )
         iTab = g_iCurTab
      end if
   else
      ChangeToTab(iTab)
   end if
   if iLine >= 0 then
      var iRow = SendMessage( CTL(wcEDIT) , EM_LINEINDEX , iLine , 0 )
      dim as CHARRANGE tRange = (iRow,iRow)
      SendMessage( CTL(wcEDIT) , EM_EXSETSEL , 0 , cast(LPARAM,@tRange) )
      SendMessage( CTL(wcEDIT) , EM_SCROLLCARET , 0,0 )
   end if
   
end sub

sub File_New()
   ChangeToTab( NewTab( "" ) )
end sub
sub File_Open()
         
   dim as OPENFILENAME tOpen
   var pzFile = cptr(zstring ptr,malloc(65536)) : (*pzFile)[0] = 0   
   do
      with tOpen
         .lStructSize = sizeof(tOpen)
         .hwndOwner = CTL(wcMain)
         .lpstrFilter = @ _
            !"Supported Files (LS LDR)\0*.ls;*.ldr\0" _
            !"LegoScript Files\0*.ls\0" _
            !"LDraw Files\0*.ldr\0" _
            !"All Files\0*.*\0\0"
         .nFilterIndex = 0 'Supported 
         .nFileExtension = 0
         .lpstrFile = pzFile
         .nMaxFile = 65536
         .lpstrInitialDir = NULL
         .lpstrTitle = NULL
         .lpstrDefExt = @"ls"
         .Flags = OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_NOCHANGEDIR or OFN_ALLOWMULTISELECT or OFN_EXPLORER
         if GetOpenFileName( @tOpen ) = 0 then exit do         
         if .nFileExtension = 0 then 'loading multiples
            var sPath = *.lpstrFile+"\", pzFile = .lpstrFile+.nFileOffset
            do
               var sFile = *pzFile : pzFile += len(sFile)+1
               if len(sFile)=0 then exit do               
               LoadScript(sPath+sFile)
            loop            
         else            
            LoadScript(*.lpstrFile)            
         end if
         exit do
      end with
   loop
   free(pzFile)
end sub
sub File_Save()
   if GetFileAttributes(g_CurrentFilePath)=&hFFFFFFFF then
      File_SaveAs() : exit sub
   end if
   var iMaxLen = GetWindowTextLength( CTL(wcEdit) )
   var sScript = space(iMaxLen)
   if GetWindowText( CTL(wcEdit) , strptr(sScript) , iMaxLen+1 )<>iMaxLen then 
      puts("Failed to retrieve text content...")
      exit sub  
   end if
   'print iMaxLen
   'print sScript
   var f = freefile()
   if open(g_CurrentFilePath for output as #f) then
      MessageBox( CTL(wcMain) , !"Failed to save:\n\n'"+g_CurrentFilePath+"'" , NULL , MB_ICONERROR )
      exit sub
   end if
   print #f, sScript;
   close #f
   g_tTabs(g_iCurTab).sFilename = g_CurrentFilePath
   UpdateTabName( g_iCurTab )
   UpdateMainWindowCaption()
   SendMessage( CTL(wcEdit) , EM_SETMODIFY , 0 , 0 )
end sub
sub File_SaveAs()
   dim as OPENFILENAME tOpen
   dim as zstring*32768 zFile = any : zFile[0]=0
   with tOpen
      .lStructSize = sizeof(tOpen)
      .hwndOwner = CTL(wcMain)
      .lpstrFilter = @!"LegoScript Files\0*.ls\0All Files\0*.*\0\0"
      .nFilterIndex = 0 '.ls
      .lpstrFile = @zFile
      .nMaxFile = 32767
      .lpstrInitialDir = NULL
      .lpstrTitle = NULL
      .Flags = OFN_PATHMUSTEXIST 'or OFN_NOCHANGEDIR
      .lpstrDefExt = @"ls"
      if GetSaveFileName( @tOpen ) = 0 then exit sub      
      print "["+*.lpstrFile+"]"
      var f = freefile()
      if open(*.lpstrFile for output as #f) then
         MessageBox( CTL(wcMain) , !"Failed to save:\n\n'"+*.lpstrFile+"'" , NULL , MB_ICONERROR )
         exit sub
      end if
      close #f
      g_CurrentFilePath = *.lpstrFile
      File_Save()
   end with
end sub
sub File_Exit()   
   SendMessage( CTL(wcMain) , WM_CLOSE , 0,0 )
end sub
sub File_Close()
      
   if Sendmessage( CTL(wcEdit) , EM_GETMODIFY , 0,0 ) then
      #define sMsg "This file was modified, what you want to do?"
      select case MsgBox( sMsg , _u("File->Open") , MB_ICONQUESTION , 3 or MB_DEFBUTTON1 , _u("Save") , _u("Don't Save") , _u("Cancel")  ) 
      case 1: File_Save()
      case 3: exit sub
      end select
   end if   
   
   if g_iTabCount = 1 then 
      puts("closing last tab?")
      ResetTabCount() : g_iCurTab=0
      var iNewTab = NewTab( "" ,, g_iCurTab ) : SetWindowText( CTL(wcEdit) , "" )
      'puts("iNewTab here: " & iNewTab)
      if g_iTabCount = 1 then ChangeToTab(iNewTab) 
      UpdateMainWindowCaption()
      exit sub
   end if
   
   var iNewTab = iif( g_iCurTab = g_iTabCount-1 , g_iCurTab-1 , g_iCurTab )
   var iChgTab = iif( g_iCurTab = g_iTabCount-1 , g_iCurTab-1 , g_iCurTab+1 )
   'puts( "iCurTab: " & g_iCurTab & " ChgTo: " & iChgTab & " WhichWillBe: " & iNewTab )
   var iCurTab = g_iCurTab 'real current tab, because the premature ChangeToTab will affect it
   ChangeToTab( iChgTab ) 'change to a new tab, BEFORE closing the tab
   'destroy tab
   SendMessage( g_tTabs(iCurTab).hEdit , EM_SETEVENTMASK , 0 , 0 )
   DestroyWindow( g_tTabs(iCurTab).hEdit )
   'move tabs after it and adjust links to the new tab
   for N as long = 0 to g_iTabCount-1
      if g_tTabs(N).iLinked > iCurTab then g_tTabs(N).iLinked -= 1
   next N
   for N as long = iCurTab+1 to g_iTabCount-1               
      g_tTabs(N-1) = g_tTabs(N)      
   next N
   'update tab control
   TabCtrl_DeleteItem( CTL(wcTabs) , iCurTab )
   InvalidateRect( CTL(wcTabs) , NULL , true )
   'can resize tab array now
   g_iTabCount -= 1 : Redim preserve g_tTabs(g_iTabCount)
   'and set current tab to the actual correct number
   iCurTab = iNewTab
   UpdateTabCloseButton()
   UpdateMainWindowCaption()
   
end sub
function File_Quit() as boolean   
   for N as long = g_iTabCount-1 to 0 step -1
      ChangeToTab( N )
      if SendMessage( CTL(wcEdit) , EM_GETMODIFY , 0,0 ) then         
         #define sMsg !"this file is modified, save it?"         
         select case MsgBox( sMsg , _u("File->Open") , MB_ICONQUESTION , 3 or MB_DEFBUTTON1 , _u("Save") , _u("Don't Save") , _u("Cancel")  )
         case 1 : File_Save()
         case 2 : Sendmessage( CTL(wcEdit) , EM_SETMODIFY , 0,0 ) : File_Close()
         case 3 : return FALSE
         end select
      else
         File_Close()
      end if
   next N   
   return true
end function

sub SetColoredOutput( sColoredText as string )
   dim as long iTag = instr( sColoredText , chr(2) )
   if iTag = 0 then iTag = len(sColoredText)+1
   SetWindowText( CTL(wcOutput) , left(sColoredText,iTag-1) )
   dim as CHARFORMAT tFmt = (sizeof(CHARFORMAT))
   while iTag < len(sColoredtext)
      var iC = sColoredText[iTag] : iTag += 2
      SendMessage( CTL(wcOutput) , EM_SETSEL , -1 , -1 )
      tFmt.dwMask = CFM_COLOR : tFmt.dwEffects = 0
      select case iC
      case 12:   tFmt.crTextColor = &h000080
      case 14:   tFmt.crTextColor = &h008080
      case else: tFmt.crTextColor = &hFF0000 : tFmt.dwEffects =  CFE_AUTOCOLOR
      end select      
      SendMessage( CTL(wcOutput) , EM_SETCHARFORMAT , SCF_SELECTION , cast(LPARAM,@tFmt) )
      var iNewTag = instr( iTag , sColoredText , chr(2) )
      if iNewTag = 0 then iNewTag = len(sColoredText)+1      
      var sText = mid(sColoredText,iTag,iNewTag-iTag)      
      SendMessage( CTL(wcOutput) , EM_REPLACESEL , FALSE , cast(LPARAM,strptr(sText)) )
      iTag = iNewTag
   wend
end sub 

sub Do_Compile( bDoLock as boolean = true )   
   SetWindowText( CTL(wcStatus) , "Building..." )   
   var iMaxLen = GetWindowTextLength( CTL(wcEdit) )
   var sScript = space(iMaxLen)
   if GetWindowText( CTL(wcEdit) , strptr(sScript) , iMaxLen+1 )<>iMaxLen then 
      puts("Failed to retrieve text content...")
      SetWindowText( CTL(wcStatus) , "Build failed." )
      exit sub  
   end if
   dim as string sOutput, sError, sFilePath = g_CurrentFilePath
   if len(sFilePath)=0 then sFilePath = "*"+GetTabName( g_iCurTab )
   sOutput = LegoScriptToLDraw( sScript , sError , sFilePath )   
   SetColoredOutput( iif(len(sError)=0,sOutput,sError) )   
   if len(sOutput) orelse len(sError)=0 then
      Viewer.LoadMemory( sOutput , GetTabName( g_iCurTab ) , bDoLock )
      #if 0
         if lcase(right(g_CurrentFilePath,3)) = ".ls" then
            Viewer.LoadMemory( sOutput , left(g_CurrentFilePath,len(g_CurrentFilePath)-3)+".ldr" , bDoLock )
         else
            Viewer.LoadMemory( sOutput , g_CurrentFilePath+".ldr" , bDoLock )
         end if
      #endif
   end if
   if len(sError) then SendMessage( CTL(wcRadOutput) , BM_CLICK , 0,0 )
   SetWindowText( CTL(wcStatus) , iif(len(sOutput),"Ready.",iif(len(sError),"Script error.","No output generated!")))
   SetFocus( CTL(wcEdit) )
end sub
sub Button_Compile()
   Try()
      Do_Compile()
      Catch()
         LogError( "Compilation Crashed!!!" )
      EndCatch()
   EndTry()
end sub
sub Output_SetMode()
   var iOutput = SendMessage( CTL(wcRadOutput) , BM_GETCHECK , 0 , 0 )
   EnableWindow( CTL(wcBtnExec) , iOutput=0 )
   EnableWindow( CTL(wcBtnLoad) , iOutput=0 )   
   ShowWindow( CTL(wcOutput) , iif(iOutput  ,SW_SHOWNA,SW_HIDE) )
   ShowWindow( CTL(wcQUery)  , iif(iOutput=0,SW_SHOWNA,SW_HIDE) )
   var hFocus = GetFocus()
   if hFocus = CTL(wcRadOutput) orelse hFocus = CTL(wcRadQuery) then
      InvalidateRect( iif( iOutput , CTL(wcRadQuery) , CTL(wcRadOutput ) ) , NULL , TRUE )
      SetFocus( iif(iOutput , CTL(wcOutput) , CTL(wcQuery)) )
   end if   
end sub
sub Output_QueryExecute()
   var iCurTab = g_iCurTab , iNewTab = 0
   'if the tab is linked then we process the linked tab and output on current tab
   if g_tTabs(iCurTab).iLinked <> -1 then       
      iNewTab = iCurTab : iCurTab = g_tTabs(iCurTab).iLinked
   else 'otherwise if the next tab is linked to this then we output on that next tab
      if iCurTab < (g_iTabCount-1) andalso g_tTabs(iCurTab+1).iLinked = iCurTab then
         iNewTab = iCurTab+1
      else 'and if the next tab is not linked to current then we create a new one linked to current
         iNewTab = NewTab( "" , iCurTab )
      end if
   end if
   'iCurTab = tab to process , iNewTab = tab to output
   var sQuery = space(1+SendMessage( CTL(wcQuery) , WM_GETTEXTLENGTH , 0,0 ))
   SendMessage( CTL(wcQuery) , WM_GETTEXT , len(sQuery)+1 , cast(LPARAM,strptr(sQuery)) )      
   puts("'"+sQuery+"'")   
   var sText = space(SendMessage( g_tTabs( iCurTab ).hEdit , WM_GETTEXTLENGTH , 0,0 ))
   SendMessage( g_tTabs( iCurTab ).hEdit , WM_GETTEXT , len(sText)+1 , cast(LPARAM,strptr(sText)) )
   SendMessage( g_tTabs(iNewTab).hEdit  , WM_SETTEXT , 0 , cast(LPARAM,strptr(sText)) )   
   ChangeToTab( iNewTab )
   
end sub
sub Output_Load()
   puts(__FUNCTION__)
end sub
sub Output_Save()
   puts(__FUNCTION__)
end sub
sub Output_ShowHide()  
  var iOpen = SendMessage( CTL(wcBtnMinOut) , BM_GETCHECK , 0 , 0 )
  g_tcfg.bShowOutput = iOpen<>0  
  static as byte bOnce = 0
  static as typeof(g_tMainCtx.hCTL( wcEdit ).tH) tPrevHei  
  if iOpen=0 orelse bOnce=0 then bOnce=1 : tPrevHei = g_tMainCtx.hCTL( wcEdit ).tH
  g_tMainCtx.hCTL( wcEdit ).tH = iif(iOpen , tPrevHei , _BottomE(-1) )   
  'g_tMainCtx.hCTL( wcBtnMinOut ).tX = iif(iOpen, _RtP(wcOutput,-4) , _RtP(wcOutput,-3))   
  for I as long = wcRadOutput to wcStatus-1
    if I = wcBtnMinOut then continue for
    ShowWindow( CTL(I) , iif(iOpen,SW_SHOWNA,SW_HIDE) )
  next I
  SetWindowText( CTL(wcBtnMinOut) , iif(iOpen,!"\x36",!"\x35") )
  var hWnd = CTL(wcMain)
  dim as RECT RcCli=any : GetClientRect(hWnd,@RcCli)      
  ResizeLayout( hWnd , g_tMainCtx.tForm , RcCli.right , RcCli.bottom )
  if GetFocus() = CTL(wcBtnMinOut) then
    var iOutput = SendMessage( CTL(wcRadOutput) , BM_GETCHECK , 0 , 0 )
    SetFocus( iif(iOpen , CTL(iif(iOutput,wcOutput,wcQuery)) , CTL(wcEdit)) )
  end if   
end sub
sub Output_ToggleOutput()
  var iToggledState = g_CurItemState and (not MFS_CHECKED)
  SendMessage( CTL(wcBtnMinOut) , BM_CLICK , 0,0 )
  if g_tCfg.bShowOutput then iToggledState or= MFS_CHECKED  
  Menu.MenuState( g_hCurMenu,g_CurItemID,iToggledState )  
end sub
sub Solution_ShowHide()
  var iOpen = SendMessage( CTL(wcBtnSide) , BM_GETCHECK , 0 , 0 )       
  g_tCfg.bShowSolutions = iOpen<>0
  static as typeof(g_tMainCtx.hCTL( wcSidePanel ).tW) tPrevWid
  static as byte bOnce = 0 : if bOnce=0 then bOnce=1 : tPrevWid = _pct(30)
  if iOpen=0 then tPrevWid = g_tMainCtx.hCTL( wcSidePanel ).tW
  g_tMainCtx.hCTL( wcSidePanel ).tW = iif(iOpen , tPrevWid , _Pct(0) )     
  
  for I as long = wcSidePanel to wcSideSplit-1
    if I = wcBtnMinOut then continue for
    ShowWindow( CTL(I) , iif(iOpen,SW_SHOWNA,SW_HIDE) )
  next I
  
  SetWindowText( CTL(wcBtnSide) , iif(iOpen,!"\x33",!"\x34") )
  var hWnd = CTL(wcMain)
  dim as RECT RcCli=any : GetClientRect(hWnd,@RcCli)      
  ResizeLayout( hWnd , g_tMainCtx.tForm , RcCli.right , RcCli.bottom )  
end sub
sub Code_ToggleSidePanel()
  var iToggledState = g_CurItemState and (not MFS_CHECKED)
  SendMessage( CTL(wcBtnSide) , BM_CLICK , 0,0 )
  if g_tCfg.bShowSolutions  then iToggledState or= MFS_CHECKED  
  Menu.MenuState( g_hCurMenu,g_CurItemID,iToggledState )  
end sub



static shared as FINDREPLACE g_tFindRep
static shared as long g_FindRepMsg
static shared as string g_sLastQuery,g_sLastReplace

function Edit_FindReplaceInit( bIsReplace as boolean ) as boolean
   EnableMenuItem( g_WndMenu , meEdit_Find    , MF_BYCOMMAND or MF_GRAYED )
   EnableMenuItem( g_WndMenu , meEdit_Replace , MF_BYCOMMAND or MF_GRAYED )
   with g_tFindRep
      if .lpstrFindWhat then return false
      .lStructSize = sizeof(g_tFindRep)
      if .hwndOwner=0 then .Flags = FR_DOWN
      .hwndOwner        = CTL(wcMain)
      .hInstance        = NULL      
      .lpstrFindWhat    = callocate(32768)
      .wFindWhatLen     = 32767
      .lpstrReplaceWith = iif(bIsReplace,callocate(32768),NULL)
      .wReplaceWithLen  = iif(bIsReplace,32767,0)
      if bIsReplace then *.lpstrReplaceWith = g_sLastReplace
      dim as WSTRING*32767 wTemp = any      
      if SendMessageW( CTL(wcEdit) , EM_GETSELTEXT , 0 , cast(LPARAM,@wTemp) ) then
         *.lpstrFindWhat = wTemp
      else
         *.lpstrFindWhat = g_sLastQuery      
      end if
   end with   
   return true
end function
function Edit_FindReplaceAction( tFindRep as FINDREPLACE ) as LRESULT   
   var hCtl = CTL(wcEdit)
   with tFindRep
      'printf(!"%p %p",@g_tFindRep,@tFindRep)
      if (.Flags and FR_DIALOGTERM) then
         if .lpstrFindWhat    then Deallocate(.lpstrFindWhat)    : .lpstrFindWhat    = NULL
         if .lpstrReplaceWith then Deallocate(.lpstrReplaceWith) : .lpstrReplaceWith = NULL
         EnableMenuItem( g_WndMenu , meEdit_Find    , MF_BYCOMMAND or MF_ENABLED )
         EnableMenuItem( g_WndMenu , meEdit_Replace , MF_BYCOMMAND or MF_ENABLED )
         .Flags and= (not FR_DIALOGTERM): return 0
      end if
      var bFlags = .Flags and ( FR_MATCHCASE or FR_WHOLEWORD or FR_DOWN )
      dim as FINDTEXTEXW tFindEx = any
      dim as CHARRANGE tRange = any
      SendMessage( hCtl , EM_EXGETSEL , 0 , cast(LPARAM,@tRange) )      
      'printf("{%i %i} ",tRange.cpMin,tRange.cpMax)
      dim as wstring*32767 wTemp = *.lpstrFindWhat
      tFindEx.lpstrText = @wTemp '.lpstrFindWhat
      
      var iMask = SendMessage( hCtl , EM_GETEVENTMASK   , 0 , 0 )                           
      SendMessage( hCtl , EM_SETEVENTMASK , 0 , iMask and (not ENM_SELCHANGE) )
      if (.Flags and FR_REPLACEALL) then SendMessage( hCtl , WM_SETREDRAW , false , 0 )
      
      dim as long lReplaced = 0, lReplaceLen = iif(.lpstrReplaceWith,strlen(.lpstrReplaceWith),0)
      if (.Flags and FR_REPLACE) then
         tFindEx.chrg = tRange
         if SendMessageW( hCtl , EM_FINDTEXTEX , bFlags , cast(LPARAM,@tFindEx) )<>-1 then
            if memcmp(@tFindEx.chrgText,@tRange,sizeof(tRange))=0 then
               SendMessage( hCtl , EM_REPLACESEL  , true , cast(LPARAM,.lpstrReplaceWith) )
               lReplaced += 1 : tRange.cpMax = tRange.cpMin+lReplaceLen
            end if
         end if
      end if
            
      do         
         tFindEx.chrg.cpMin = iif( ((bFlags and FR_DOWN)<>0) , tRange.cpMax , tRange.cpMin )
         tFindEx.chrg.cpMax = iif(bFlags and FR_DOWN , -1 , 0)              
                     
         'printf("<%i %i> ",tRange.cpMin,tRange.cpMax)
         'printf("{%i %i} ",tFindEx.chrg.cpMin,tFindEx.chrg.cpMax)
         var iResu = SendMessageW( hCtl , EM_FINDTEXTEX , bFlags , cast(LPARAM,@tFindEx) )
         if iResu <> -1 then
            'printf("[%i %i %i] ",iResu,tFindEx.chrgText.cpMin,tFindEx.chrgText.cpMax)
            'SetFocus( hCtl )
            SendMessage( hCtl , EM_EXSETSEL , 0 , cast(LPARAM,@tFindEx.chrgText) )
            if (.Flags and FR_REPLACEALL) then
               SendMessage( hCtl , EM_REPLACESEL  , true , cast(LPARAM,.lpstrReplaceWith) )
               lReplaced += 1 : tRange.cpMin = tFindEx.chrgText.cpMin 
               tRange.cpMax = tRange.cpMin+lReplaceLen : continue do
            end if               
         else
            if (.Flags and FR_REPLACEALL) then                
               SendMessage( hCtl , WM_SETREDRAW , true , 0 )
               if lReplaced then InvalidateRect( hCtl , NULL , true )
            end if
            if lReplaced=0 then
               MessageBox( CTL(wcMain) , _
                  iif( 1 , "No Results found" , "No More Results found" ) , _
                  iif(.lpstrReplaceWith , "Replace" , "Find" ) , MB_ICONWARNING _
               )
            else
               MessageBox( CTL(wcMain) , "Replaced " & lReplaced & " times", "Replace" , MB_ICONINFORMATION )            
            end if
         end if
         exit do
      loop
      
      if .lpstrFindWhat    then g_sLastQuery   = *.lpstrFindWhat
      if .lpstrReplaceWith then g_sLastReplace = *.lpstrReplaceWith
      
      SendMessage( hCtl , EM_SETEVENTMASK , 0 , iMask )
   end with
   return 1
end function

sub File_Import()
   puts(__FUNCTION__)
end sub
sub File_Export()
   puts(__FUNCTION__)
end sub

sub Edit_Undo()
   puts(__FUNCTION__)
end sub
sub Edit_Redo()
   puts(__FUNCTION__)
end sub
sub Edit_Find()   
   if Edit_FindReplaceInit( false )=false then exit sub
   var hWnd = FindText( @g_tFindRep )
   if hWnd=0 then 
      var lErr = GetLastError() , lExtErr = CommDlgExtendedError()
      printf(!"Failed: %X %X\n",lErr,lExtErr)      
      #define SErr(_N) if (lExtErr = _N) then printf(!"%s\n",#_N)      
      SErr(CDERR_FINDRESFAILURE)
      SErr(CDERR_MEMLOCKFAILURE)
      SErr(CDERR_INITIALIZATION)
      SErr(CDERR_NOHINSTANCE)
      SErr(CDERR_LOCKRESFAILURE)
      SErr(CDERR_NOHOOK) 
      SErr(CDERR_LOADRESFAILURE)
      SErr(CDERR_NOTEMPLATE)
      SErr(CDERR_LOADSTRFAILURE)
      SErr(CDERR_STRUCTSIZE)
      SErr(CDERR_MEMALLOCFAILURE)
      SErr(FRERR_BUFFERLENGTHZERO)
   end if
end sub
sub Edit_Replace()
   if Edit_FindReplaceInit( true )=false then exit sub
   if ReplaceText( @g_tFindRep ) = NULL then
      puts("Replace failed")
   end if
end sub
sub Edit_SelectAll()
   SendMessage( GetFocus() , EM_SETSEL , 0 , -1 )
end sub
sub Edit_Cut()
   SendMessage( GetFocus() , WM_CUT , 0,0 )
end sub
sub Edit_Copy()   
   SendMessage( GetFocus() , WM_COPY , 0,0 )
end sub
sub Edit_Paste()
   SendMessage( GetFocus() , WM_PASTE , 0,0 )
end sub
sub Edit_ContextMenu( hRichEdit as HWND , wParam as WPARAM , lParam as LPARAM)
  
  var hMenu = CreatePopupMenu()
        
  '// 1. Add standard items
  AppendMenu(hMenu, MF_STRING   , WM_UNDO , @"&Undo"      )
  AppendMenu(hMenu, MF_SEPARATOR,    0    , NULL          )
  AppendMenu(hMenu, MF_STRING   , WM_CUT  , @"Cu&t"       )
  AppendMenu(hMenu, MF_STRING   , WM_COPY , @"&Copy"      )
  AppendMenu(hMenu, MF_STRING   , WM_PASTE, @"&Paste"     )
  AppendMenu(hMenu, MF_STRING   , WM_CLEAR, @"&Delete"    )
  AppendMenu(hMenu, MF_SEPARATOR,    0    , NULL          )
  AppendMenu(hMenu, MF_STRING   ,   1001  , @"Select &All") '// Custom ID for Select All

  '// 2. Logic to enable/disable items based on selection/undo-stack
  if (SendMessage(hRichEdit, EM_CANUNDO, 0, 0)=0) then
    EnableMenuItem(hMenu, WM_UNDO, MF_BYCOMMAND or MF_GRAYED)
  end if

  '// 3. Display the menu
  var x = cshort(loword(lParam)) , y = cshort(hiword(lParam))
  
  '// TrackPopupMenu returns the ID of the clicked item
  var cmd = TrackPopupMenu(hMenu, TPM_LEFTALIGN or TPM_RIGHTBUTTON or TPM_RETURNCMD, x, y, 0, hRichEdit, NULL)
  
  '// 4. Send the command to the RichEdit
  if cmd=1001 then
    SendMessage(hRichEdit, EM_SETSEL, 0, -1)
  elseif cmd>0 then
    SendMessage(hRichEdit, cmd, 0, 0)
  end if

  DestroyMenu(hMenu)
end sub

sub Code_ClearOutput()
   SetWindowText( CTL(wcOutput) , "" )
end sub

sub Completion_Enable()
   var iToggledState = g_CurItemState xor MFS_CHECKED
   g_CompletionEnable = (iToggledState and MFS_CHECKED)<>0
   puts(__FUNCTION__ & ":" & iif(g_CompletionEnable,"Enabled","Disabled"))
   _Cfg(bCompletionEnable) = g_CompletionEnable
   g_SQCtx.iCur = -1
   Menu.MenuState( g_hCurMenu,g_CurItemID,iToggledState )   
   EnableMenuItem( g_hCurMenu , sbeCompletion_Filters , iif( iToggledState and MFS_CHECKED , MF_ENABLED , MF_GRAYED ) )
   if (iToggledState and MFS_CHECKED)=0 then ShowWindow( g_hContainer , SW_HIDE )
end sub
sub Completion_ClearFilters()
   puts(__FUNCTION__)
   g_FilterFlags = 0
   for N as long = meFilter_Variations to meFilter_Stickers
      Menu.MenuState( g_hCurMenu , N , g_CurItemState )
   next N
end sub
sub Completion_InvertFilters()
   puts(__FUNCTION__)
   for N as long = meFilter_Variations to meFilter_Stickers
      Menu.Trigger( N )
   next N
end sub
sub Completion_Toggle()   
   var iToggledState = g_CurItemState xor MFS_CHECKED
   Menu.MenuState( g_hCurMenu,g_CurItemID,iToggledState )   
   #define ChgFilter( _Name ) g_FilterFlags = iif( iToggledState and MFS_CHECKED , g_FilterFlags or _Name , g_FilterFlags and (not (_Name)) )
   select case g_CurItemID
   case meFilter_Variations  : ChgFilter( wIsHidden )   
   case meFilter_Donor       : ChgFilter( wIsDonor )
   case meFilter_Path        : ChgFilter( wIsPath )
   case meFilter_Printed     : ChgFilter( wIsPrinted )
   case meFilter_Shortcut    : ChgFilter( wIsShortcut )
   case meFilter_Stickered   : ChgFilter( wIsStickered )
   case meFilter_MultiColor  : ChgFilter( wIsMultiColor )
   case meFilter_PreColored  : ChgFilter( wIsPreColored )
   case meFilter_Template    : ChgFilter( wIsTemplate )
   case meFilter_Alias       : ChgFilter( wIsAlias )    
   case meFilter_Moulded     : ChgFilter( wIsMoulded )
   case meFilter_Helper      : ChgFilter( wIsHelper )
   case meFilter_Stickers    : ChgFilter( wIsSticker )
   end select
end sub

sub AutoFormat_Toggle()
  var iToggledState = g_CurItemState xor MFS_CHECKED
  Menu.MenuState( g_hCurMenu,g_CurItemID,iToggledState )   
  #define ChgFilter( _Name ) g_FilterFlags = iif( iToggledState and MFS_CHECKED , g_FilterFlags or _Name , g_FilterFlags and (not (_Name)) )
  select case g_CurItemID
    case meAutoFormat_Case : _Cfg( bAutoFmtCase ) = ((iToggledState and MFS_CHECKED)<>0)
  end select
end sub

sub View_ToggleGW()
   var iToggledState = g_CurItemState xor MFS_CHECKED
   g_Show3D = (iToggledState and MFS_CHECKED)<>0
   if g_GfxHwnd then      
      ShowWindowAsync( g_GfxHwnd , iif( g_Show3D , SW_SHOWNA , SW_HIDE ) )
      DockGfxWindow( true )
      if g_Show3D then         
         SetWindowPos( g_GfxHwnd , HWND_TOPMOST , 0,0,0,0 , SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE)
         SetWindowPos( g_GfxHwnd , HWND_NOTOPMOST , 0,0,0,0 , SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE)         
      end if
   end if   
   Menu.MenuState( g_hCurMenu,g_CurItemID, iToggledState )
   for N as long = meView_ShowCollision to meView_PrevBoxPart 'View.*
      EnableMenuItem( g_hCurMenu , N , iif( iToggledState and MFS_CHECKED , MF_ENABLED , MF_GRAYED ) )
   next N
end sub
sub View_ToggleGWDock()
   var iToggledState = g_CurItemState xor MFS_CHECKED
   g_Dock3D = (iToggledState and MFS_CHECKED)<>0
   if g_Dock3D andalso g_GfxHwnd<>0 then DockGfxWindow()
   Menu.MenuState( g_hCurMenu,g_CurItemID, iToggledState )   
end sub
sub View_ToggleKey()
   if IsWindow(g_GfxHwnd)=0 then exit sub
   dim vk as long , sft as byte
   
   select case g_CurItemID
   case meView_ShowCollision 
      Menu.MenuState( g_WndMenu,meView_ShowCollision, iif(Viewer.bShowCollision=0,MFS_CHECKED,0) )
      vk = VK_SPACE
   case else : puts("bad View_ToggleKey()"): exit sub
   end select
   
   if sft then SendMessage( g_GfxHwnd , WM_KEYDOWN , VK_SHIFT , 0 ) 'scShift )
   SendMessage( g_GfxHwnd , WM_KEYDOWN , vk , 0 )   
   SendMessage( g_GfxHwnd , WM_KEYUP  , vk , 0 )
   if sft then SendMessage( g_GfxHwnd , WM_KEYUP   , VK_SHIFT , 0 ) 'scShift )
end sub
sub View_Key()
   if IsWindow(g_GfxHwnd)=0 then exit sub
   dim vk as long , sft as byte
   select case g_CurItemID
   case meView_ResetCamera : vk = VK_DELETE   : sft = 1
   case meView_ResetView   : vk = VK_BACK     'Backspace
   case meView_NextPart    : vk = VK_ADD      '+
   case meView_PrevPart    : vk = VK_SUBTRACT '-
   case meView_ResetBox    : vk = VK_BACK     : sft = 1 'Shift BACKSPACE
   case meView_NextBoxPart : vk = VK_ADD      : sft = 1 'Shift +
   case meView_PrevBoxPart : vk = VK_SUBTRACT : sft = 1 'Shift -
   case else  : puts("bad View_key"): exit sub
   end select
   'var scShift =  (MapVirtualKey( VK_SHIFT , 0 ) shl 16)+1
   if sft then SendMessage( g_GfxHwnd , WM_KEYDOWN , VK_SHIFT , 0 ) 'scShift )
   SendMessage( g_GfxHwnd , WM_KEYDOWN , vk , 0 )   
   SendMessage( g_GfxHwnd , WM_KEYUP  , vk , 0 )
   if sft then SendMessage( g_GfxHwnd , WM_KEYUP   , VK_SHIFT , 0 ) 'scShift )
end sub
sub View_Toggle()
   if IsWindow(g_GfxHwnd)=0 then exit sub
   ' 40005
   var iToggledState = g_CurItemState xor MFS_CHECKED
   Menu.MenuState( g_hCurMenu,g_CurItemID,iToggledState )   
   SendMessage( g_GfxHwnd , WM_KEYDOWN , VK_TAB , 0 )   
   SendMessage( g_GfxHwnd , WM_KEYUP   , VK_TAB , 0 )
end sub

sub View_GfxQuality()
   if (g_CurItemState and MFS_CHECKED) then exit sub 'same
   Menu.MenuState( g_hCurMenu,meView_QualityLow   ,g_CurItemState or ((g_CurItemID=meView_QualityLow)    and MFS_CHECKED) )
   Menu.MenuState( g_hCurMenu,meView_QualityNormal,g_CurItemState or ((g_CurItemID=meView_QualityNormal) and MFS_CHECKED) )
   Menu.MenuState( g_hCurMenu,meView_QualityHigh  ,g_CurItemState or ((g_CurItemID=meView_QualityHigh)   and MFS_CHECKED) )
   select case g_CurItemID
   case meView_QualityLow   : g_LoadQuality = 1 : _cfg(lGfxModelQuality) = 1
   case meView_QualityNormal: g_LoadQuality = 2 : _cfg(lGfxModelQuality) = 2
   case meView_QualityHigh  : g_LoadQuality = 3 : _cfg(lGfxModelQuality) = 3
   end select     
   
   if viewer.g_pLoadedModel then
      mutexlock(Viewer.g_Mutex)
      for N as long = g_ModelCount-1 to 0 step -1
         FreeModel( g_tModels(N).pModel )
      next N
      g_sFilenames = chr(0) : g_sFilesToLoad = chr(0)   
      viewer.g_pLoadedModel = NULL
      viewer.g_LoadFile = abs(viewer.g_LoadFile)
      mutexunlock(Viewer.g_Mutex)
      'while viewer.g_pLoadedModel
      '   SleepEx(1,1)
      'wend 
   end if

end sub

sub Help_About()
   puts(__FUNCTION__)
end sub
