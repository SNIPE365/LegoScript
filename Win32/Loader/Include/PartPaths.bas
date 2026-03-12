#ifndef __Main
  #error " Don't compile this one"
#endif  

#include once "win\Shlobj.bi"
#include once "dir.bi"
#include once "file.bi"

#ifndef NULL
const NULL = 0
#endif

static shared as long g_iExtraPathCount = 0
redim shared as string g_sExtraPathList()

const cUnnofficialPathIndex = 4
static shared as zstring ptr g_pzPaths(...) = { _
  NULL        , _   
  @"1:\p\48"  , _ '\unoff
  @"2:\p"     , _ '\unoff 
  @"3:\p\8"   , _ '\unoff
  @"0:\parts" , _ '\unoff '4
  @"1:\p\8"         , _   
  @"2:\p"           , _
  @"3:\p\48"        , _         
  @"0:\parts"        _
  }
  '@"\parts\s", _
  '@"\unoff\parts\s", _
  '@"\parts\s\p", _
  '@"\unoff\parts\s\p", _
rem ------------------------------   

static shared as string g_sPathList( ubound(g_pzPaths) )
static shared as byte g_bPathQuality( ubound(g_pzPaths) )
static shared as string g_sCfgFile , g_sPathLDRAW

function OpenFolder( sTitle as string , sInit as string , sOutput as string ) as boolean
  
  #if 0
    dim as OPENFILENAME tOpen
    var pzFile = cptr(zstring ptr,malloc(65536)) : *pzFile = sInit
    do
      with tOpen
        .lStructSize = sizeof(tOpen)
        .hwndOwner = GetForegroundWindow()
        .lpstrFilter = @ _
          !"All Folders\0*\0\0"
        .nFilterIndex = 0 'Supported 
        .nFileExtension = 0
        .lpstrFile = pzFile
        .nMaxFile = 65536
        .lpstrInitialDir = NULL
        .lpstrTitle = strptr(sTitle)
        .lpstrDefExt = NULL
        .Flags = OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_NOCHANGEDIR or OFN_EXPLORER or OFN_NOVALIDATE or OFN_DONTADDTORECENT
        if GetOpenFileName( @tOpen ) then function=true : sOutput = *.lpstrFile
        exit do
      end with
    loop
    free(pzFile)
  #else
    var pzFolder = cptr(zstring ptr,malloc(65536)) : *pzFolder = sInit
    dim as BROWSEINFOA tFolder
    with tFolder
      .hwndOwner      = GetForegroundWindow()
      .pidlRoot       = NULL
      .pszDisplayName = pzFolder
      .lpszTitle      = strptr(sTitle) 
      .ulFlags        = BIF_RETURNONLYFSDIRS or BIF_EDITBOX or BIF_VALIDATE or _
                        BIF_NONEWFOLDERBUTTON 'or BIF_NEWDIALOGSTYLE or BIF_USENEWUI
      var pResu = SHBrowseForFolderA( @tFolder ) 
      if presu then        
        SHGetPathFromIDListA( pResu , pzFolder )
        function=true : sOutput = *pzFolder
        CoTaskMemFree(pResu)
      end if
    end with
    free(pzFolder)    
  #endif
  print sOutput
    
end function

sub CheckPathLDRAW( byref sPath as string )        
  #define chk(_s) ((GetFileAttributes(sPath+_s) and (&h80000000 or FILE_ATTRIBUTE_DIRECTORY))=FILE_ATTRIBUTE_DIRECTORY)
  #define chkExist(_s) (GetFileAttributes(sPath+_s)<>&hFFFFFFFF)
  #define IsPath(_s) (mid(_s,2,2)=":\")
  'orelse left(_s,2)=".\")
  
  if IsPath(sPath)=0 then sPath = g_sCfgFile+"\"+sPath
  
  'puts(sPath & " || " & GetFileAttributes(sPath)) & " || " & FILE_ATTRIBUTE_DIRECTORY
  'puts(sPath+"\unoff" & " || " & GetFileAttributes(sPath+"\unoff"))
  'puts(sPath+"\p" & " || " & GetFileAttributes(sPath+"\p"))
  'puts(sPath+"\part" & " || " & GetFileAttributes(sPath+"\part"))
  do
    if IsPath(sPath) andalso chk("") andalso chkExist("\LDConfig.ldr") andalso chk("\p") andalso chk("\parts") then exit do
    if OpenFolder("Locate LDRAW folder","ldraw",sPath)=false then end
  loop
    
  g_sPathList(0) = ".\" : g_bPathQuality( 0 ) = 0    
  for N as long = 5 to 8 'official
    g_bPathQuality( N ) = valint(*g_pzPaths(N))
    g_sPathList(N) = sPath + mid(*g_pzPaths(N),3)
  next N  
  
  g_sPathLDRAW = sPath
  
end sub

sub CheckPathUNOFF( byref sPath as string )        
  #define chk(_s) ((GetFileAttributes(sPath+_s) and (&h80000000 or FILE_ATTRIBUTE_DIRECTORY))=FILE_ATTRIBUTE_DIRECTORY)
  #define chkExist(_s) (GetFileAttributes(sPath+_s)<>&hFFFFFFFF)
  #define IsPath(_s) (mid(_s,2,2)=":\")
  'orelse left(_s,2)=".\")
  
  if IsPath(sPath)=0 then sPath = g_sCfgFile+"\"+sPath
  
  'puts(sPath & " || " & GetFileAttributes(sPath)) & " || " & FILE_ATTRIBUTE_DIRECTORY
  'puts(sPath+"\unoff" & " || " & GetFileAttributes(sPath+"\unoff"))
  'puts(sPath+"\p" & " || " & GetFileAttributes(sPath+"\p"))
  'puts(sPath+"\part" & " || " & GetFileAttributes(sPath+"\part"))
  static as ubyte bOnce
  do
    if IsPath(sPath) andalso chk("") andalso (chk("\unoff")=0) andalso chk("\p") andalso chk("\parts") then exit do
    if bOnce=0 then bOnce=1 : sPath = g_sPathLDRAW+"\unoff" : continue do
    if OpenFolder("Locate UNOFFICIAL LDRAW folder","ldraw",sPath)=false then end    
  loop
    
  g_sPathList(0) = ".\" : g_bPathQuality( 0 ) = 0    
  for N as long = 1 to 4 'official
    g_bPathQuality( N ) = valint(*g_pzPaths(N))
    g_sPathList(N) = sPath + mid(*g_pzPaths(N),3)
  next N
  
end sub

#undef g_pzPaths

static shared as zstring ptr g_pzShadowPaths(...) = { _
  NULL      , _
  @"\parts" , _
  @"\p"     , _
  @"\parts\s" _
}
rem ----------------------------------------------

dim shared as string g_sShadowPathList( ubound(g_pzShadowPaths) )
sub CheckPathSHADOW( byref sPath as string )
  #define chk(_s) ((GetFileAttributes(sPath+_s) and (&h80000000 or FILE_ATTRIBUTE_DIRECTORY))=FILE_ATTRIBUTE_DIRECTORY)
  #define IsPath(_s) (mid(_s,2,2)=":\")
  'orelse left(_s,2)=".\")
  if IsPath(sPath)=0 then sPath = g_sCfgFile+"\"+sPath
  
  do
    if IsPath(sPath) andalso chk("") andalso chk("\offlib\p") andalso chk("\offlib\parts") then exit do
    if OpenFolder("Locate LDRAW Shadow folder","shadow",sPath)=false then end
  loop
  
  'var sPath = "G:\Jogos\LDCad-1-7-Beta-1-Win\shadow\offlib"
  for N as long = 1 to ubound(g_pzShadowPaths)
    g_sShadowPathList(N) = sPath + "\offlib" + *g_pzShadowPaths(N)
  next N
end sub
#undef g_pzShadowPaths

#macro ForEachPathSetting( _do )  
  _do( sPathLDRAW        , "Path"      , string   , ""                 , CheckPathLDRAW , _cfgVarName )
  _do( sPathUNOFF        , "Path"      , string   , ""                 , CheckPathUNOFF , _cfgVarName )
  _do( sPathSHADOW       , "Path"      , string   , ""                 , CheckPathSHADOW , _cfgVarName )
#endmacro
g_sCfgFile = exepath()

#if __Main <> "LegoScript" andalso __Main <> "LegoCAD"
  
  #define   AddMember( _Name , __Section ,  _Type , __Default , __InitFunc... ) _Name as _Type  
  #define InitDefault( _Name , __Section , __Type ,  _Default , __InitFunc... ) g_tCfg._Name = _Default
  type PathSettings
    ForEachPathSetting( AddMember )
  end type
  dim shared as PathSettings g_tCfg
  ForEachPathSetting( InitDefault )
  #undef AddMember
  #undef InitDefault
  
  scope    
    
    if FileExists(g_sCfgFile+"\LegoScript.ini")=0 then
      g_sCfgFile += "\.."
      if FileExists(g_sCfgFile+"\LegoScript.ini")=0 then
        MessageBox(null,"LegoScript.ini not found, please run 'legoscript.exe' to configure it",null,MB_ICONERROR or MB_SYSTEMMODAL)
        system 2
      end if
    end if
    
    dim tSettings as PathSettings = g_tCfg
    #define ReadStringSetting( _string ) _string      
    #define CallSetupFunction( _Varname , _Function , _Parms... ) _Function( _Parms )
    #macro LoadSetting( _Varname , _Section , _VarType , _Default , _SetupFunction... )    
      cptr(integer ptr,@sSetting)[1] = GetPrivateProfileString( _Section , mid(#_Varname,2) , " " , strptr(sSetting) , 65535 , g_sCfgFile+"\LegoScript.ini" )
      if len(sSetting) then ._VarName = Read##_VarType##Setting( sSetting )
      #define _cfgVarName ._Varname
      CallSetupFunction( _VarName , _SetupFunction )
      #undef _cfgVarName
    #endmacro
    
    var sSetting = space(65536)
    with tSettings
      ForEachPathSetting( LoadSetting )
    end with  
    sSetting = ""
    g_tCfg = tSettings
  end scope
    
#endif
