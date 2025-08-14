const cSettingVersion = 20250814

#macro ForEachSetting( _do )
  _do( lVersion      , long     , cSettingVersion  )
  _do( lGuiX         , long     , CW_USEDEFAULT    )
  _do( lGuiY         , long     , CW_USEDEFAULT    )
  _do( lGuiWid       , long     , 640              )
  _do( lGuiHei       , long     , 480              )
  _do( bGuiMaximized , boolean  , false            )
  _do( lGfxX         , long     , 0                )
  _do( lGfxY         , long     , 0                )
  _do( lGfxWid       , long     , 640              )
  _do( lGfxHei       , long     , 480              )
  _do( bGuiAttached  , boolean  , true             )
  _do( lChecksum     , long     , -cSettingVersion )
#endmacro

#macro AddStructMember( _Varname , _VarType , _Default )
  _Varname as _VarType = _Default
#endmacro

type LS_SettingsStruct
   ForEachSetting( AddStructMember )
end type
static shared as LS_SettingsStruct g_tCfg
static shared as boolean g_bSettingsChanged = true

sub LoadSettings()
   dim tSettings as LS_SettingsStruct = any , f as long = freefile()   
   if open(exepath+"\LegoScript.cfg" for binary access read as #f) then 
      puts("Failed to load settings... restoring to default"): exit sub
   end if
   get #f,,tSettings : close #f
   if tSettings.lVersion  <>  cSettingVersion then Puts("Bad settings... restoring"): exit sub
   if tSettings.lChecksum <> -cSettingVersion then Puts("Bad settings... restoring"): exit sub
   g_tCfg = tSettings
   g_bSettingsChanged = false
   puts("Settings Loaded")   
end sub
sub SaveSettings()
   if g_bSettingsChanged = false then puts("settings didnt changed"): exit sub
   dim f as long = freefile()   
   if open(exepath+"\LegoScript.cfg" for binary access write as #f) then 
      puts("Failed to save settings"): exit sub
   end if
   put #f,,g_tCfg
   close #f
   puts("Settings Saved")
end sub

LoadSettings()

   
