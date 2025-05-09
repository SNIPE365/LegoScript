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
function LoadFileIntoEditor( sFile as string ) as boolean
   var f = freefile(), iResu = open(sFile for binary access read as #f)
   if iResu orelse (lof(f) > (64*1024*1024)) then
      if iResu=0 then close(f)
      MessageBox( CTL(wcMain) , !"Failed to open:\n\n'"+sFile+"'" , NULL , MB_ICONERROR )
      return false
   end if   
   dim as string sData = space(lof(f)), sScript = space(lof(f)*3)   
   get #f,,sData : close #f
   
   dim as long iOut=0, iLen = len(sData)
   for iN as long = 0 to iLen
      dim as ubyte iChar = sData[iN]
      select case iChar
      case asc(";") 'implicit EOL
         sScript[iOut] = iChar
         do
            iN += 1 : if iN >= iLen then exit for
            iChar = sData[iN]
            select case iChar
            case 13,9,asc(" "),asc(";") 'ignore blanks
               rem ignore blanks
            case 10
               sScript[iOut+1] = 13 : iChar = 10: iOut += 2 : exit do            
            case else
               sScript[iOut+1] = 13 : sScript[iOut+2] = 10: iOut += 3 : exit do
            end select
         loop
      case 13 : continue for
      case 10 : sScript[iOut] = 10 : iOut += 1
      end select
      sScript[iOut] = iChar : iOut += 1
   next iN
   sScript = left(sScript,iOut)
   
   SetWindowText( CTL(wcEdit) , sScript ) : sScript=""
   g_CurrentFilePath = sFile
   SetWindowText( CTL(wcMain) , sAppName + " - " + sFile )
   NotifySelChange( wcEdit )
   SetFocus( CTL(wcButton) )
   return true
end function
sub ChangeToTab( iNewTab as long , bForce as boolean = false ) 
   if iNewTab < 0 orelse iNewTab >= g_iTabCount then exit sub
   'var iCurTab = TabCtrl_GetCurSel( CTL(wcTabs) )   
   'if bForce=0 andalso iCurTab = iNewTab then exit sub
   with g_tTabs(iNewTab)      
      var hWndOld = CTL(wcEdit) , hParent = GetParent(.hEdit)
      if hWndOld = .hEdit then exit sub
      var hFont = g_tMainCtx.hFnt(g_tMainCtx.hCtl(wcEdit).bFont).hFont
      CTL(wcEdit) = .hEdit : g_iCurTab = iNewTab
      'swap control IDs (so that only one control have the current tab ID)
      SetWindowLong( hWndOld , GWL_ID , 0 ) : SetWindowLong( .hEdit  , GWL_ID , wcEdit )
      dim as RECT tRC = any : GetWindowRect( hWndOld , @tRC )
      ScreenToClient( hParent , cast(POINT ptr,@tRC)+0 )
      ScreenToClient( hParent , cast(POINT ptr,@tRC)+1 )      
      SendMessage( .hEdit , WM_SETFONT , cast(WPARAM,hFont) , false )
      SetWindowPos( .hEdit , 0 , tRC.left , tRc.top , tRc.right-tRc.left , tRc.Bottom-tRc.top , SWP_NOZORDER or SWP_SHOWWINDOW )
      ShowWindow( hWndOld , SW_HIDE )
      g_CurrentFilePath = .sFilename
      if len(.sFilename) then 
         SetWindowText( CTL(wcMain) , sAppName + " - " + .sFilename )
      else
         SetWindowText( CTL(wcMain) , sAppName + " - Unnamed")
      end if
      TabCtrl_SetCurSel( CTL(wcTabs) , iNewTab )
      NotifySelChange( wcEdit )      
   end with
end sub
function CloneHwnd( hWnd as HWND ) as HWND
   var wClass   = cast(zstring ptr , GetClassLong( hWnd , GCW_ATOM ) )
   var hInst    = cast(HINSTANCE, GetWindowLong(hWnd,GWL_HINSTANCE))
   var hParent  = cast(HWND     , GetWindowLong(hWnd,GWL_HWNDPARENT))
   var lStyle   = GetWindowLong(hWnd,GWL_STYLE)
   var lStyleEx = GetWindowLong(hWnd,GWL_EXSTYLE)
   return CreateWindowEx( lStyleEx , wClass , NULL , lStyle , 0,0,0,0 , hParent , 0 , hInst , NULL )
end function

sub Do_Compile()   
   SetWindowText( CTL(wcStatus) , "Building..." )   
   var iMaxLen = GetWindowTextLength( CTL(wcEdit) )
   var sScript = space(iMaxLen)
   if GetWindowText( CTL(wcEdit) , strptr(sScript) , iMaxLen+1 )<>iMaxLen then 
      puts("Failed to retrieve text content...")
      SetWindowText( CTL(wcStatus) , "Build failed." )
      exit sub  
   end if
   dim as string sOutput, sError
   sOutput = LegoScriptToLDraw( sScript , sError )   
   SetWindowText( CTL(wcOutput) , iif(len(sError)=0,sOutput,sError) )   
   if len(sOutput) then
      if lcase(right(g_CurrentFilePath,3)) = ".ls" then
         Viewer.LoadMemory( sOutput , left(g_CurrentFilePath,len(g_CurrentFilePath)-3)+".ldr" )
      else
         Viewer.LoadMemory( sOutput , g_CurrentFilePath+".ldr" )
      end if
   end if
   SetWindowText( CTL(wcStatus) , iif(len(sOutput),"Ready.","Script error.") )
   
end sub
sub Button_Compile()
   Try()
      Do_Compile()
      Catch()
         LogError( "Compilation Crashed!!!" )
      EndCatch()
   EndTry()
end sub
'**************** Main Menu Layout **************

sub UpdateTabName( iTab as long )
   if cuint(iTab) >= g_iTabCount then exit sub   
   with g_tTabs(iTab)
      dim as string sFile = "Unnamed"
      if len(.sFilename) then
         var iPos = instrrev(.sFilename,"\") , iPos2 = instrrev(.sFilename,"/")
         if iPos2 > iPos then iPos = iPos2          
         sFile = mid(.sFilename,iPos+1)      
      end if
      dim as TC_ITEM tItem = type( TCIF_TEXT , 0,0 , strptr(sFile) , 0,-1 , 0 ) 
      TabCtrl_SetItem( CTL(wcTabs) , iTab , @tItem )   
      if iTab = g_iCurTab then
         if len(.sFilename) then 
            SetWindowText( CTL(wcMain) , sAppName + " - " + .sFilename )
         else
            SetWindowText( CTL(wcMain) , sAppName + " - Unnamed")
         end if
      end if
   end with   
end sub
function NewTab( sNewFile as string ) as long   
   var iNewTab = 0 , sFile = sNewFile 'byval
   if len(g_tTabs(g_iCurTab).sFilename) orelse GetWindowTextLength( CTL(wcEdit) )<>0 then
      iNewTab = g_iTabCount 'create new TAB
      redim preserve g_tTabs(g_iTabCount) : g_iTabCount += 1
      var hWnd = CloneHwnd( CTL(wcEdit) )
      g_tTabs( iNewTab ).hEdit = hWnd
      SendMessage( hWnd , EM_EXLIMITTEXT , 0 , 16*1024*1024 ) '16mb text limit
      SendMessage( hWnd , EM_SETEVENTMASK , 0 , ENM_SELCHANGE or ENM_KEYEVENTS or ENM_SCROLL )
      dim as TC_ITEM tItem = type( TCIF_TEXT , 0,0 , @" " , 0,-1 , 0 ) 
      TabCtrl_InsertItem( CTL(wcTabs) , iNewTab , @tItem )         
   end if
   
   with g_tTabs(iNewTab)
      if len(sFile) then      
         var iPos = instrrev(sFile,"\") , iPos2 = instrrev(sFile,"/")
         if iPos2 > iPos then iPos = iPos2
         .sFilename = sFile
         sFile = mid(sFile,iPos+1)
         dim as TC_ITEM tItem = type( TCIF_TEXT , 0,0 , strptr(sFile) , 0,-1 , 0 ) 
         TabCtrl_SetItem( CTL(wcTabs) , iNewTab , @tItem )      
      else
         sFile = "Unnamed"      
         .sFilename = ""      
         dim as TC_ITEM tItem = type( TCIF_TEXT , 0,0 , strptr(sFile) , 0,-1 , 0 ) 
         TabCtrl_SetItem( CTL(wcTabs) , iNewTab , @tItem )      
      end if
   end with
   return iNewTab
end function


sub File_New()
   ChangeToTab( NewTab( "" ) )
end sub
sub File_Open()
         
   dim as OPENFILENAME tOpen
   dim as zstring*32768 zFile = any : zFile[0]=0
   with tOpen
      .lStructSize = sizeof(tOpen)
      .hwndOwner = CTL(wcMain)
      .lpstrFilter = @ _
         !"LegoScript Files\0*.ls\0" _
         !"LDraw Files\0*.ldr\0" _
         !"All Files\0*.*\0\0"
      .nFilterIndex = 0 '.ls
      .lpstrFile = @zFile
      .nMaxFile = 32767
      .lpstrInitialDir = NULL
      .lpstrTitle = NULL
      .lpstrDefExt = @"ls"
      .Flags = OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_NOCHANGEDIR
      if GetOpenFileName( @tOpen ) = 0 then exit sub      
      print "["+*.lpstrFile+"]"
      var sFile = *.lpstrFile, sFileL = lcase(sFile)
      for N as long = 0 to g_iTabCount-1
         with g_tTabs(N)
            if lcase(.sFileName) = sFileL then
               ChangeToTab(N): exit sub
            end if
         end with
      next N      
      ChangeToTab(NewTab( sFile ))                  
      LoadFileIntoEditor( sFile )
   end with
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
      
   if GetWindowTextLength( CTL(wcEdit) ) then
      #define sMsg !"All unsaved data will be lost, continue?"
      if MessageBox( CTL(wcMain) , sMsg , "File->Open" , MB_ICONQUESTION or MB_YESNO ) <> IDYES then exit sub
   end if   
   
   if g_iTabCount = 1 then 
      var iNewTab = NewTab( "" ) : SetWindowText( CTL(wcEdit) , "" )
      if g_iTabCount = 1 then ChangeToTab(iNewTab) : exit sub
   end if
   
   var iNewTab = iif( g_iCurTab = g_iTabCount-1 , g_iCurTab , g_iCurTab+1 )
   var iCurTab = g_iCurTab
   ChangeToTab( iNewTab+(iNewTab=g_iCurTab) )
   SendMessage( g_tTabs(iCurTab).hEdit , EM_SETEVENTMASK , 0 , 0 )
   DestroyWindow( g_tTabs(iCurTab).hEdit )
   for N as long = iCurTab+1 to g_iTabCount-1
      g_tTabs(N-1) = g_tTabs(N)
   next N
   TabCtrl_DeleteItem( CTL(wcTabs) , iCurTab )
   g_iTabCount -= 1 : Redim preserve g_tTabs(g_iTabCount)
   g_iCurTab = iNewTab
   
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

sub Code_ClearOutput()
   SetWindowText( CTL(wcOutput) , "" )
end sub

sub Completion_Enable()
   puts(__FUNCTION__)
   var iToggledState = g_CurItemState xor MFS_CHECKED
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
sub View_ToggleGW()
   var iToggledState = g_CurItemState xor MFS_CHECKED
   g_Show3D = (iToggledState and MFS_CHECKED)<>0
   if g_GfxHwnd then      
      ShowWindow( g_GfxHwnd , iif( g_Show3D , SW_SHOWNA , SW_HIDE ) )
      if g_Show3D then
         SetWindowPos( g_GfxHwnd , HWND_TOPMOST , 0,0,0,0 , SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE)
         SetWindowPos( g_GfxHwnd , HWND_NOTOPMOST , 0,0,0,0 , SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE)
      end if
   end if   
   Menu.MenuState( g_hCurMenu,g_CurItemID, iToggledState )
   for N as long = meView_ResetView to meView_PrevBoxPart 'View.*
      EnableMenuItem( g_hCurMenu , N , iif( iToggledState and MFS_CHECKED , MF_ENABLED , MF_GRAYED ) )
   next N
end sub
sub View_ToggleGWDock()
   var iToggledState = g_CurItemState xor MFS_CHECKED
   g_Dock3D = (iToggledState and MFS_CHECKED)<>0
   if g_Dock3D andalso g_GfxHwnd then DockGfxWindow()
   Menu.MenuState( g_hCurMenu,g_CurItemID, iToggledState )   
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
sub Help_About()
   puts(__FUNCTION__)
end sub
