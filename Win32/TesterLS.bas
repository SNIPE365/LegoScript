#define __Main "LegoScript"
#define __NoRender
#define __Standalone

'#define __DebugShadowLoad

#include "windows.bi"
#include "crt.bi"
#include "fbgfx.bi"

#if __FB_DEBUG__
  #include once "MyTDT\Exceptions.bas"
  StartExceptions()
#endif

#define errorf(_Parms...) fprintf(stderr,_Parms)

#include once "Loader\Modules\Matrix.bas"
#include once "Loader\LoadLDR.bas"
#include once "LSModules\Settings.bas"
#include once "Loader\Include\Colours.bas"
#include once "Loader\Modules\Clipboard.bas"
#include once "Loader\Modules\Math3D.bas"
'#include "Loader\Modules\Normals.bas"
#include once "Loader\Modules\Model.bas"

#define DbgBuild(_s)
#define Dbg_Printf  rem
#define Dbg_Puts rem   
#include once "LSModules\LS2LDR.bas"
#undef DbgBuild
#undef Dbg_Printf
#undef Dbg_puts

var sScript = !"3001 B1 s1 = NULL;" , sErrWarn = ""
var sLDR = LegoScriptToLDraw( sScript , sErrWarn )
if len(sLDR) then
  print sLDR
  var pModel = LoadModel( strptr(sLDR) , "main.ldr" )
  print pModel
end if

sleep





