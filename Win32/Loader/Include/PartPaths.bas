#ifndef __Main
  #error " Don't compile this one"
#endif  

#ifndef NULL
const NULL = 0
#endif

static shared as zstring ptr g_pzPaths(...) = { _
   NULL            , _   
   @"1:\unoff\p\48"  , _
   @"2:\unoff\p"     , _   
   @"3:\unoff\p\8"   , _
   @"0:\unoff\parts" , _   
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

static shared as long g_iExtraPathCount = 0
redim shared as string g_sExtraPathList()

static shared as string g_sPathList( ubound(g_pzPaths) )
static shared as byte g_bPathQuality( ubound(g_pzPaths) )
g_sPathList(0) = ".\" : g_bPathQuality( 0 ) = 0
scope
   var sPath = environ("userprofile")+"\Desktop\LDCAD\LDRAW"
   for N as long = 1 to ubound(g_pzPaths)
      g_bPathQuality( N ) = valint(*g_pzPaths(N))
      g_sPathList(N) = sPath + mid(*g_pzPaths(N),3)
   next N
end scope   
#undef g_pzPaths

dim shared as zstring ptr g_pzShadowPaths(...) = { _
   NULL      , _
   @"\parts" , _
   @"\p"     , _
   @"\parts\s" _
}

dim shared as string g_sShadowPathList( ubound(g_pzShadowPaths) )
scope
   var sPath = environ("userprofile")+"\Desktop\LDCAD\shadow\offlib"
   for N as long = 1 to ubound(g_pzShadowPaths)
      g_sShadowPathList(N) = sPath + *g_pzShadowPaths(N)
   next N
end scope   

#undef g_pzShadowPaths