#define MenuTriggerIfTrue( _MenuID ) Menu.Trigger , ((._VarName<>0) and meAutoFormat_Case)
#macro ForEachSetting( _do )
  _do( lVersion          , ulong    , cSettingVersion  )
  _do( lGuiX             , long     , CW_USEDEFAULT    )
  _do( lGuiY             , long     , CW_USEDEFAULT    )
  _do( lGuiWid           , long     , 640              )
  _do( lGuiHei           , long     , 480              )
  _do( bGuiMaximized     , boolean  , false            )
  _do( lGfxX             , long     , 0                )
  _do( lGfxY             , long     , 0                )
  _do( lGfxWid           , long     , 640              )
  _do( lGfxHei           , long     , 480              )
  _do( bGuiAttached      , boolean  , true             )    
  _do( bAutoFmtCase      , boolean  , true             , Menu.Trigger , ((_cfgVarName<>0) and meAutoFormat_Case) )
  _do( bCompletionEnable , boolean  , true             , Menu.Trigger , ((_cfgVarName<>0) and meCompletion_Enable) )
  _do( lChecksum     , ulong    , -cSettingVersion )  
#endmacro

#macro AddStructMember( _Varname , _VarType , _Default , _SetupFunction... )
  _Varname as _VarType
#endmacro

type LS_SettingsStruct
   ForEachSetting( AddStructMember )
end type

static shared as LS_SettingsStruct g_tCfg = any , g_tCfgBkp

'250814
const cSettingVersion = (251216 shl 12)+sizeof(g_tCfg)

#define _Cfg( _Var ) g_tCfg._var

sub DefaultSettings( iMinOff as long =0 , iMaxOff as long = offsetof(LS_SettingsStruct,lChecksum) )
  #macro InitializeStructMember( _Varname , _VarType , _Default , _SetupFunction... )
    if offsetof(LS_SettingsStruct,_VarName) >= iMinOff then
      if offsetof(LS_SettingsStruct,_VarName) <= iMaxOff then ._VarName = (_Default)
    end if
  #endmacro
  with g_tCfg  
    ForEachSetting( InitializeStructMember )
  end with  
end sub

sub LoadSettings()
  dim tSettings as LS_SettingsStruct = any , f as long = freefile()   
  if open(exepath+"\LegoScript.cfg" for binary access read as #f) then 
    puts("Failed to load settings... restoring to default"): exit sub
  end if
  get #f,,tSettings : close #f
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
    DefaultSettings( , 0 )  're-set version
    DefaultSettings( iOff ) 'restore new settings
    g_tCfgBkp = tSettings : g_tCfgBkp.lVersion=0    
  elseif tSettings.lChecksum <> culng(-cSettingVersion) then 
    Puts("Bad settings... restoring"): exit sub
  end if
  g_tCfg = tSettings : g_tCfgBkp = tSettings  
  puts("Settings Loaded")   
end sub
sub SaveSettings()  
  #define CheckChanged( _Varname , _VarType , _Default , _SetupFunction... ) if ._VarName <> g_tCfgBkp._VarName then exit do
  do
    with g_tCfg    
      ForEachSetting( CheckChanged )    
    end with
    puts("settings didnt changed"): sleep 1000,1 : exit sub
  loop
  
  dim f as long = freefile()   
  if open(exepath+"\LegoScript.cfg" for binary access write as #f) then 
    puts("Failed to save settings"): exit sub 'getchar()
  end if
  put #f,,g_tCfg : g_tCfgBkp = g_tCfg : close #f
  puts("Settings Saved")
  'getchar()
end sub

DefaultSettings()
LoadSettings()