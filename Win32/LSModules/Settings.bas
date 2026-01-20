#define MenuTriggerIfTrue( _MenuID ) Menu.Trigger , (((_cfgVarName)<>0) and (_MenuID))
#define MenuTriggerIfFalse( _MenuID ) Menu.Trigger , (((_cfgVarName)=0) and (_MenuID))
#define MenuTriggerRadio( _BaseMenuID ) Menu.Trigger, ((_BaseMenuID)+(_cfgVarName))
#define ButtonTriggerIfTrue( _ID ) Btn_Trigger , (((_cfgVarName)<>0) and (_ID))
#define ButtonTriggerIfFalse( _ID ) Btn_Trigger , (((_cfgVarName)=0) and (_ID))
#macro ForEachSetting( _do )
  _do( lVersion          , "Config"    , ulong    , cSettingVersion     )
  _do( lGuiX             , "Window"    , long     , CW_USEDEFAULT       )
  _do( lGuiY             , "Window"    , long     , CW_USEDEFAULT       )
  _do( lGuiWid           , "Window"    , long     , 640                 )
  _do( lGuiHei           , "Window"    , long     , 480                 )
  _do( bGuiMaximized     , "Window"    , boolean  , false               )
  _do( bShowOutput       , "Window"    , boolean  , true                , MenuTriggerIfFalse(meCode_Output)      )
  _do( bShowSolutions    , "Window"    , boolean  , false               , MenuTriggerIfTrue(meCode_Panel)        )
  _do( lGfxModelQuality  , "Model"     , long     , ModelQuality_Normal , MenuTriggerRadio(meView_QualityLow-1)  )
  _do( bGfxEnable        , "GfxWindow" , boolean  , false               , MenuTriggerIfTrue(meView_ToggleGW)     )  
  _do( lGfxX             , "GfxWindow" , long     , 0                   )
  _do( lGfxY             , "GfxWindow" , long     , 0                   )
  _do( lGfxWid           , "GfxWindow" , long     , 640                 )
  _do( lGfxHei           , "GfxWindow" , long     , 480                 )
  _do( bGuiAttached      , "GfxWindow" , boolean  , true                , MenuTriggerIfTrue(meView_ToggleGWDock) )
  _do( bAutoFmtCase      , "Editor"    , boolean  , true                , MenuTriggerIfTrue(meAutoFormat_Case)   )
  _do( bCompletionEnable , "Editor"    , boolean  , true                , MenuTriggerIfTrue(meCompletion_Enable) )  
  _do( lChecksum         , "Config"    , ulong    , -cSettingVersion    )
  ForEachPathSetting( _do )  
#endmacro

#macro AddStructMember( _Varname , _Section , _VarType , _Default , _SetupFunction... )
  _Varname as _VarType
#endmacro

type LS_SettingsStruct
   ForEachSetting( AddStructMember )
end type

static shared as LS_SettingsStruct g_tCfg = any , g_tCfgBkp

'250814
const cSettingVersion = (251218 shl 12)+sizeof(g_tCfg)

#define _Cfg( _Var ) g_tCfg._var

sub DefaultSettings( iMinOff as long =0 , iMaxOff as long = offsetof(LS_SettingsStruct,lChecksum) )
  #macro InitializeStructMember( _Varname , _Section , _VarType , _Default , _SetupFunction... )
    if offsetof(LS_SettingsStruct,_VarName) >= iMinOff then
      if offsetof(LS_SettingsStruct,_VarName) <= iMaxOff then ._VarName = (_Default)
    end if
  #endmacro
  with g_tCfg  
    ForEachSetting( InitializeStructMember )
  end with  
end sub

function ReadLongSetting( sSetting as string ) as long : return valint(sSetting) : end function
function ReadULongSetting( sSetting as string ) as ulong : return valint(sSetting) : end function
function ReadStringSetting( sSetting as string ) as string : return sSetting : end function
function ReadBooleanSetting( sSetting as string ) as boolean
  select case trim(lcase(sSetting))
  case "true","yes" : return true
  case "false","no" : return false
  end select
  return valint(sSetting)<>0
end function

sub LoadSettings()
  dim tSettings as LS_SettingsStruct = g_tCfg
  
  #if 0
    var f = freefile()
    if open(exepath+"\LegoScript.cfg" for binary access read as #f) then 
      puts("Failed to load settings... restoring to default"): exit sub
    end if      
    get #f,,tSettings : close #f
  #endif
      
  #macro LoadSetting( _Varname , _Section , _VarType , _Default , _SetupFunction... )    
    'print _Section , mid(#_Varname,2), 
    cptr(integer ptr,@sSetting)[1] = GetPrivateProfileString( _Section , mid(#_Varname,2) , " " , strptr(sSetting) , 65535 , exepath+"\LegoScript.ini" )
    'print len(sSetting), 
    if len(sSetting) then ._VarName = Read##_VarType##Setting( sSetting ):g_tCfgBkp._VarName=._VarName else memset( @g_tCfgBkp._VarName , -1 , sizeof(._VarName) )
    'print ._VarName
  #endmacro
  
  var sSetting = space(65536)
  with tSettings
    ForEachSetting( LoadSetting )
  end with  
  sSetting = ""
  
  #define _set( _parm ) offsetof( LS_SettingsStruct , _parm ) , offsetof( LS_SettingsStruct , _parm )
  
  if tSettings.lVersion <> cSettingVersion then 
    puts("Different settings version... checking")
    var iOff = (tSettings.lVersion and &hFFF)
    if tSettings.lVersion > cSettingVersion orelse iOff > (sizeof(LS_SettingsStruct)) then
      puts( tSettings.lVersion & " // " & cSettingVersion & " // " & iOff & " // " & sizeof(LS_SettingsStruct) )
      puts("Newer or corrupted settings... restoring to default"): exit sub
    end if
    if *cptr(long ptr,cptr(ubyte ptr,@tSettings.lVersion)+iOff-sizeof(long)) <> culng(-tSettings.lVersion) then
      puts("Older version, corrupted settings... restoring to default"): exit sub
    end if
    puts("Older version, upgrading (exitting app will save as new settings version)")
    g_tCfg = tSettings 
    DefaultSettings( _set(lVersion) )  're-set version
    DefaultSettings( _set(lCheckSum) )
    DefaultSettings( iOff ) 'restore new settings
    g_tCfgBkp = tSettings : tSettings = g_tCfg
    memset( @g_tCfgBkp , -1 , sizeof(g_tCfgBkp) )
  elseif tSettings.lChecksum <> culng(-cSettingVersion) then 
    Puts("Bad settings... restoring"): exit sub
  end if
  
  g_tCfg = tSettings 
  puts("Settings Loaded")
  
end sub
sub SaveSettings()  
  #define CheckChanged( _Varname , _Section , _VarType , _Default , _SetupFunction... ) if ._VarName <> g_tCfgBkp._VarName then exit do
  do
    with g_tCfg    
      ForEachSetting( CheckChanged )    
    end with
    puts("settings didnt changed"): exit sub
  loop
  
  #if 0
    dim f as long = freefile()   
    if open(exepath+"\LegoScript.cfg" for binary access write as #f) then 
      puts("Failed to save settings"): exit sub 'getchar()
    end if
    put #f,,g_tCfg : close #f
  #endif
  
  #macro SaveSetting( _Varname , _Section , _VarType , _Default , _SetupFunction... )
    WritePrivateProfileString( _Section , mid(#_Varname,2) , "" & ._Varname , exepath+"\LegoScript.ini" )
  #endmacro
  with g_tCfg
    ForEachSetting( SaveSetting )
  end with
  
  g_tCfgBkp = g_tCfg  
  puts("Settings Saved")
  'sleep 2000 'getchar()
  
end sub

DefaultSettings()
LoadSettings()

scope
  #define CallSetupFunction( _Varname , _Function , _Parms... ) _Function( _Parms )
  #macro CheckSetupFunction( _Varname , _Section , _VarType , _Default , _SetupFunction... )
    #if len(#_SetupFunction)
      #define _cfgVarName ._VarName
      CallSetupFunction( _Varname , _SetupFunction )
      #undef _cfgVarName
    #endif
  #endmacro
  with g_tCfg  
    ForEachPathSetting( CheckSetupFunction )
  end with
end scope
