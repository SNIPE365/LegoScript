#define LDRAW_PATH "%userprofile%\Desktop\LDCAD\LDRAW"

#ifndef NULL
const NULL = 0
#endif

dim shared as zstring ptr g_pzPaths(...) = { _
   NULL, _
   @LDRAW_PATH "\parts", _
   @LDRAW_PATH "\unoff\parts", _   
   @LDRAW_PATH "\p", _
   @LDRAW_PATH "\p\48", _   
   @LDRAW_PATH "\unoff\p", _   
   @LDRAW_PATH "\unoff\p\48" _
}
   '@LDRAW_PATH "\parts\s", _
   '@LDRAW_PATH "\unoff\parts\s", _
   '@LDRAW_PATH "\parts\s\p", _
   '@LDRAW_PATH "\unoff\parts\s\p", _
rem ------------------------------   
dim shared as string g_sPathList( ubound(g_pzPaths) )
for N as long = 1 to ubound(g_pzPaths)
   g_sPathList(N) = *g_pzPaths(N)
next N