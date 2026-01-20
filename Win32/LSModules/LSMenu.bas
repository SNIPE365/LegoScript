'******************** Menu Handling Helper Functions **************
#macro ForEachMenuEntry( __Entry , __SubMenu , __EndSubMenu , __Separator )
   __SubMenu( "&File" )
     __Entry( meFile_New      , "&New"              , _Ctrl        , VK_N , @File_New    )
     __Entry( meFile_open     , "&Open"             , _Ctrl        , VK_O , @File_Open   )     
     __Entry( meFile_Save     , "&Save"             , _Ctrl        , VK_S , @File_Save   )     
     __Entry( meFile_SaveAs   , "Save &As"          , _Ctrl+_Shift , VK_S , @File_SaveAs )     
     __Entry( meFile_Close    , "&Close"            , _Ctrl        , VK_W , @File_Close  )
     __Separator()
      __Entry( meFile_Import  , "&Import"           , _Ctrl        , VK_I , @File_Import )
      __Entry( meFile_Export  , "&Export"           , _Ctrl+_Shift , VK_I , @File_Export )
     __Separator()
     __Entry( meFile_Exit     , "&Quit" !"\tAlt+F4" , _Ctrl        , VK_Q , @File_Exit   )
   __EndSubMenu()   
   __SubMenu( "&Edit" )            
      __Entry( meEdit_Undo    , "&Undo"  !"\tCtrl+Z" ,              ,      , @Edit_Undo )
      __Entry( meEdit_Redo    , "&Redo"              , _Ctrl+_Shift , VK_Z , @Edit_Redo )
      __Separator()
      __Entry( meEdit_Find    , "&Find"              , _Ctrl        , VK_F , @Edit_Find )
      __Entry( meEdit_Replace , "Rep&lace"           , _Ctrl        , VK_H , @Edit_Replace )
      __Separator()
      __Entry( meEdit_SelAll  , "&Select All"        , _Ctrl        , VK_A , @Edit_SelectAll  )
      __Separator()
      __Entry( meEdit_Cut     , "C&ut"   !"\tCtrl+X" ,              ,      , @Edit_Cut  )
      __Entry( meEdit_Copy    , "&Copy"  !"\tCtrl+C" ,              ,      , @Edit_Copy )      
      __Entry( meEdit_Paste   , "&Paste" !"\tCtrl+V" ,              ,      , @Edit_Paste)
      __Separator()
      __Entry( meCode_Build   , "&Build"             , 0            , VK_F6 , @Button_Compile )
      __Entry( meCode_Panel   , "Show Side &Panel"   , _Ctrl+_Shift , VK_P , @Code_ToggleSidePanel )
      __Entry( meCode_Output  , "Show &Output"       , _Ctrl+_Shift , VK_O , @Output_ToggleOutput , MFS_CHECKED )      
      __Entry( meCode_Clear   , "Cl&ear output"      , _Ctrl+_Shift , VK_B , @Code_ClearOutput )      
   __EndSubMenu()
   __SubMenu( "&Completion" )
      __Entry( meCompletion_Enable , "&Enable"   , _Ctrl , VK_E , @Completion_Enable )         
      __SubMenu( "&Filters" , sbeCompletion_Filters )
         __Entry( meCompletion_ClearFilters  , "C&lear"      , _Ctrl+_Shift , VK_C , @Completion_ClearFilters )
         __Entry( meCompletion_InvertFilters , "&Invert"     , _Ctrl+_Alt   , VK_I , @Completion_InvertFilters )
         __Separator()
         __Entry( meFilter_Variations    , "&Variations" , _Alt+_Shift  , VK_F , @Completion_Toggle )
         __Entry( meFilter_Donor         , "&Donor"      , _Alt         , VK_D , @Completion_Toggle )
         __Entry( meFilter_Path          , "&Path"       , _Alt         , VK_P , @Completion_Toggle )
         __Entry( meFilter_Printed       , "P&rinted"    , _Alt+_Shift  , VK_P , @Completion_Toggle )
         __Entry( meFilter_Shortcut      , "Shortcut"    , _Alt         , VK_S , @Completion_Toggle )
         __Entry( meFilter_Stickered     , "Stic&kered"  , _Alt         , VK_K , @Completion_Toggle )
         __Entry( meFilter_MultiColor    , "Multi&color" , _Alt         , VK_M , @Completion_Toggle )
         __Entry( meFilter_PreColored    , "Pre-c&olored", _Alt+_Shift  , VK_C , @Completion_Toggle )
         __Entry( meFilter_Template      , "&Template"   , _Alt         , VK_T , @Completion_Toggle )
         __Entry( meFilter_Alias         , "&Alias"      , _Alt         , VK_A , @Completion_Toggle )
         __Entry( meFilter_Moulded       , "&Moulded"    , _Alt+_Shift  , VK_M , @Completion_Toggle )
         __Entry( meFilter_Helper        , "&Helper"     , _Alt+_Shift  , VK_H , @Completion_Toggle )
         __Entry( meFilter_Stickers      , "&Stickers"   , _Alt         , VK_S , @Completion_Toggle )
      __EndSubMenu()
      __SubMenu( "&Auto format" , sbeCompletion_AutoFormat )       
        __Entry( meAutoFormat_Case , "&Auto casing"      , , , @AutoFormat_Toggle )
      __EndSubMenu()
   __EndSubMenu()
   __SubMenu( "&View" )
      __Entry( meView_ToggleGW     , "&Graphics Window"    , _Ctrl        , VK_G   , @View_ToggleGW ) ' , MFT_RADIOCHECK or MFS_CHECKED )      
      __Entry( meView_ToggleGWDock , "&Dock GW in Main"    , _Ctrl+_Shift , VK_L   , @View_ToggleGWDock )
      __Entry( meView_ResetCamera  , "&Reset Camera"       , _Ctrl+_Shift , VK_R   , @View_Key )
      __SubMenu( "Graphics &Quality" )
         __Entry( meView_QualityLow    , "&Low"    , _Ctrl+_Shift , VK_1   , @View_GfxQuality  , MFT_RADIOCHECK )
         __Entry( meView_QualityNormal , "&Normal" , _Ctrl+_Shift , VK_2   , @View_GfxQuality  , MFT_RADIOCHECK )
         __Entry( meView_QualityHigh   , "&High"   , _Ctrl+_Shift , VK_3   , @View_GfxQuality  , MFT_RADIOCHECK )
      __EndSubMenu()
      __Separator()
      __Entry( meView_ShowCollision, "&Show Collisions"    !"\tSPACE"     , , , @View_ToggleKey, MFS_GRAYED )
      __Separator()
      __Entry( meView_ResetView    , "Reset View parts"    !"\tBACKSPACE" , , , @View_Key      , MFS_GRAYED )
      __Entry( meView_NextPart     , "View &Next part"     !"\t+"         , , , @View_Key      , MFS_GRAYED )
      __Entry( meView_PrevPart     , "View &Previous part" !"\t-"         , , , @View_Key      , MFS_GRAYED )
      __Separator()   
      __Entry( meView_ShowBox      , "&Show bounding box"  !"\tTAB"       , , , @View_Toggle   , MFS_GRAYED )
      __Entry( meView_ResetBox     , "Reset bounding box"  !"\tShift BACKSPACE", , , @View_Key , MFS_GRAYED )
      __Entry( meView_NextBoxPart  , "Ne&xt part"          !"\tShift +"   , , , @View_Key      , MFS_GRAYED )
      __Entry( meView_PrevBoxPart  , "&Pre&vious part"     !"\tShift -"   , , , @View_Key      , MFS_GRAYED )
   __EndSubMenu()   
   __SubMenu( "&Help" )          
      __Entry( meHelp_About , "About" , , , @Help_About )
   __EndSubMenu()
#endmacro
#define _Shift FSHIFT
#define _Ctrl  FCONTROL
#define _Alt   FALT
#define Dummy()
#define EnumEntry( _Name , _p... ) _Name
#macro MayEnumEntry( _p... )
   #if len(#_p)
      EnumEntry(_p)
   #endif
#endmacro
#define MayEnumSubMenu( _s , _name... ) _name
   enum MenuEntries
      meFirst = 1000
      ForEachMenuEntry( MayEnumEntry , MayEnumSubMenu , Dummy , Dummy )
      meLast 
   end enum
#undef EnumEntry
#undef MayEnumEntry
#undef MayEnumSubMenu

'#define ViewerShowInfo
'#define DebugShadow

namespace Menu 
   function AddSubMenu( hMenu as any ptr , sText as string , iID as long = 0 ) as any ptr
      if IsMenu(hMenu)=0 then return NULL
      var hResult = CreatePopupMenu()
      'AppendMenu( hMenu , MF_POPUP or MF_STRING , cast(UINT_PTR,hResult) , sText )
      dim as MENUITEMINFOA tItem = type( sizeof(MENUITEMINFO) )
      with tItem
         .fMask = MIIM_SUBMENU or MIIM_ID or MIIM_STRING
         .hSubMenu = hResult : .wId = iID
         .dwTypeData = strptr(stext)
      end with
      InsertMenuItemA( hMenu , -1 , true , @tItem )      
      if hMenu=g_WndMenu andalso CTL(wcMain) then DrawMenuBar( CTL(wcMain) )
      return hResult
   end function
   function MenuAddEntry( hMenu as any ptr , iID as long = 0 , sText as string = "" , pEvent as any ptr = 0 , bState as long = 0 ) as long    
      if IsMenu(hMenu)=0 then return -1
      dim as MENUITEMINFOA tItem = type( sizeof(MENUITEMINFO) )    
      tItem.fMask      = MIIM_DATA or MIIM_ID or MIIM_STATE or MIIM_TYPE
      tItem.fType      = iif( len(sText) , iif( bState and MFT_RADIOCHECK , MFT_RADIOCHECK , MFT_STRING ) , MFT_SEPARATOR )
      tItem.fState     = bState and (not MFT_RADIOCHECK)
      tItem.wID        = iID
      tItem.dwItemData = cast(long_ptr,pEvent)
      if len(sText) then tItem.dwTypeData = strptr(sText) else tItem.dwTypeData = NULL
      InsertMenuItemA( hMenu , &hFFFFFFFF , true , @tItem )
      'DrawMenuBar( g_GfxWnd )
      return iID
   end function   
   'MFS_CHECKED , MFS_DEFAULT , MFS_DISABLED , MFS_ENABLED , MFS_GRAYED , MFS_HILITE , MFS_UNCHECKED , MFS_UNHILITE
   function MenuState( hMenu as any ptr , iID as long , bState as long = 0 ) as long
      if IsMenu(hMenu)=0 then return -1
      dim as MENUITEMINFO tItem = type( sizeof(MENUITEMINFO) , MIIM_STATE )      
      tItem.fState = bState
      SetMenuItemInfo( hMenu , iID , false , @tItem )
      return bState
   end function
   function MenuText( hMenu as any ptr , iID as long , sText as string ) as long
      if IsMenu(hMenu)=0 then return -1    
      dim as MENUITEMINFO tItem = type( sizeof(MENUITEMINFO) , MIIM_TYPE )          
      GetMenuItemInfo( hMenu , iID , false , @tItem )    
      tItem.dwTypeData = strptr(sText)
      SetMenuItemInfo( hMenu , iID , false , @tItem )
      return len(sText)
   end function   
   function IsChecked( iID as long ) as boolean
      return (GetMenuState( g_WndMenu , iID , MF_BYCOMMAND ) and MF_CHECKED )<>0
   end function
   sub Trigger( iID as ushort )
      SendMessage(CTL(wcMain),WM_MENUSELECT,iID,cast(LPARAM,g_WndMenu))      
      SendMessage( CTL(wcMain) , WM_COMMAND , iID , 0 )
   end sub
end namespace
