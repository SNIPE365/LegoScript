#ifndef NULL
const NULL = 0
#endif

dim shared as zstring ptr g_pzPaths(...) = { _
   NULL            , _
   @"\parts"       , _
   @"\unoff\parts" , _      
   @"\p\48"        , _
   @"\p"           , _
   @"\p\8"         , _   
   @"\unoff\p\8"   , _
   @"\unoff\p"     , _   
   @"\unoff\p\48"    _
}
   '@"\parts\s", _
   '@"\unoff\parts\s", _
   '@"\parts\s\p", _
   '@"\unoff\parts\s\p", _
rem ------------------------------   

dim shared as string g_sPathList( ubound(g_pzPaths) )
scope
   var sPath = environ("userprofile")+"\Desktop\LDCAD\LDRAW"
   for N as long = 1 to ubound(g_pzPaths)
      g_sPathList(N) = sPath + *g_pzPaths(N)
   next N
end scope   
#undef g_pzPaths

dim shared as zstring ptr g_pzShadowPaths(...) = { _
   NULL      , _
   @"\parts" , _
   @"\p"       _
}

dim shared as string g_sShadowPathList( ubound(g_pzShadowPaths) )
scope
   var sPath = environ("userprofile")+"\Desktop\LDCAD\shadow\offlib\shadow"
   for N as long = 1 to ubound(g_pzShadowPaths)
      g_sShadowPathList(N) = sPath + *g_pzShadowPaths(N)
   next N
end scope   

#undef g_pzShadowPaths