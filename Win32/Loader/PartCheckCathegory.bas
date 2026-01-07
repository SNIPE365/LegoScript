#define __Main
#define __Tester

#include "LoadLDR.bas"

#include "Include\Colours.bas"
#include "Modules\Clipboard.bas"

#include "Modules\InitGL.bas"
#include "Modules\Math3D.bas"
#include "Modules\Normals.bas"
#include "Modules\Matrix.bas"
#include "Modules\Model.bas"

var sPath = environ("userprofile")+"\Desktop\LDCAD\"

type PartCheck 
   pzName as zstring ptr   
end type

#define q(_n) ((_n)*1) 'duplicated male
#define d(_n) ((_n)*2) 'duplicated female

' @"77844" (does not have clutches at shadow library)
' @"3023old", @"3023old2" , @"3034old" ,  @"3035old" , @"3036old" (old parts)
' @"3030a" (rare old part... not found)

dim as zstring ptr aPlates(...) = { _
  @"3024", @"3023", @"3623", @"3710", @"78329", @"3666", @"3460", @"4477", _
  @"60479", @"3022", @"2420", @"3021", @"3020", @"3795", @"3034", @"3832", @"2445", @"91988", _
  @"4282", @"11212", @"3031", @"2639", @"3032", @"3035", @"3030", @"3029", _
  @"3958", @"3036", @"3033", @"3028", @"3456", @"3027", @"3026", @"41539", @"728", @"92438", @"91405" _
}

dim as long iErrorCount
static as zstring ptr pzCat(...) = { _
   @"None???" , @"Plate" , @"Brick" , @"Baseplate" , @"Slab", @"Other" _
}


#if 0
for N as long = 0 to ubound( aPlates )   
   var sFile = *aPlates(N)+".dat" , sModel = ""
   color 11 : print left(*aPlates(N)+space(18),18);: color 7
   if FindFile( sFile ) = 0 then color 14: puts("Part Not found"): continue for
   if LoadFile( sFile , sModel ) = 0 then
      print "Failed to load '"+sFile+"'" : continue for      
   end if
   var pModel = LoadModel( strptr(sModel) , sFile )
   if pModel = 0 then
      print "Failed to model '"+sFile+"'" : continue for      
   end if
   dim as PartSnap tSnap
   SnapModel( pModel , tSnap ) : pModel->pData = @tSnap
   var bCat = DetectPartCathegory( pModel )
   if bCat = pcPlate then color 10 else color 12 : iErrorCount += 1 
   
   if bCat > ubound(pzCat) then puts("Unknown") else puts(pzCat(bCat))   
next N
#endif

dim shared as string sError
sub ShowError() destructor
   print sError
   sleep
end sub

var f = freefile(), sFullpath = "", sFile = "", sModel = ""
open "ValidParts.txt" for input as #f
while not eof(f)
   line input #f, sFullPath : sFullPath = trim(sFullPath)
   if len(sFullPath)=0 then continue while
   sFile = mid( sFullPath , instrrev( sFullPath , "\" )+1 )   
   select case sFile       
   case "73200bpy1.dat" 
      continue while 'dependency not found
   case "11299.dat","23444.dat","2743.dat","32074.dat","32074c01.dat","32074c02.dat","32308.dat"      , _
      "35366.dat","42936.dat","44374.dat","45411.dat","4611.dat"
      continue while 'parsing error
   case "10128p01c01.dat","11301.dat","17114.dat","18897.dat","19079.dat","212.dat","3946.dat"        , _
      "21980.dat","21980c01.dat","23167.dat","246.dat","247.dat","2479.dat","247b.dat","24855c01.dat" , _
      "2537.dat","2538.dat","2538a.dat","2538b.dat","2539.dat","2580c01.dat","2618.dat","26913.dat"   , _
      "26913c01.dat","27168.dat","27255.dat","2850.dat","2850a.dat","2850b.dat","2855.dat"            , _
      "29110.dat","29124.dat","29125c01.dat","30047.dat","30389b.dat","30518.dat","4141498.dat"       , _
      "30621.dat","30642.dat","32061.dat","32276c01.dat","32276c02.dat","32495c01.dat","3475.dat"     , _
      "19071.dat","32577.dat","42511c07.dat","4256738.dat","32577.dat","42511c07.dat","291.dat"       , _
      "3475b.dat","39144.dat","3940.dat","3963.dat","40902.dat","4124174.dat","30619.dat","41751.dat" , _ 
      "41751p01.dat","41881.dat","41894c01.dat","4193528.dat","4229.dat","42511c01.dat","42511c02.dat", _
      "42511c03.dat","42511c04.dat","42511c05.dat","42511c06.dat",_"42511c07.dat","4256738.dat"       , _
      "4343c01.dat","4343c02.dat","43446.dat","43979.dat","4501575.dat","45407.dat","45705.dat"       , _
      "4616b.dat","47674c01.dat","47676.dat","47846.dat","47899c01.dat","47899c01d01.dat","41533.dat" , _
      "47899c01d02.dat","47899c01d03.dat","47899c03.dat","47899c04.dat","47974.dat","48147.dat"       , _
      "4844.dat","4844b.dat","4868.dat","4868a.dat","4868ad01.dat","4868ad02.dat","4868b.dat"         , _
      "49309.dat","49309p01.dat","52040.dat","52258p01c01.dat","53543.dat","54734.dat","58119.dat"    , _
      "58122.dat","58123.dat","58123p01.dat","58135c01.dat","58148c01.dat","58148p01c01.dat"          , _
      "58827.dat","59195.dat","6040.dat","61485c01.dat","6222.dat","6272.dat","63521.dat","43121.dat" , _
      "64227.dat","68325.dat","685p01c01.dat","73194c01.dat","73194c01d01.dat","73194c01d03.dat"      , _
      "73194c01d04.dat","73194c01d06.dat","73194c02.dat","73194c03.dat","73194c04.dat","73435.dat"    , _
      "73436.dat","74573.dat","74780-f1.dat","74780-f2.dat","74781-f1.dat","74781-f2.dat","75937.dat" , _
      "76048.dat","76113c01.dat","76424.dat","768.dat","883.dat","884.dat","919.dat","919c01.dat"     , _
      "92198c01.dat","92198p01c01.dat","92198p01c02.dat","92198p01c03.dat","92198p01c04.dat"          , _
      "92198p01c05.dat","92198p01c06.dat","92198p01c07.dat","92198p01c08.dat","92198p01c09.dat"       , _
      "92198p01c10.dat","92198p01c11.dat","92198p01c12.dat","92198p01c13.dat","92198p01c14.dat"       , _
      "92198p02c01.dat","92198p02c02.dat","92198p02c03.dat","92198p02c04.dat","92198p02c05.dat"       , _
      "92198p02c06.dat","92198p02c07.dat","92198p04c01.dat","92198p04c02.dat","92198p04c03.dat"       , _
      "92198p04c04.dat","92198p04c05.dat","92198p04c06.dat","92198p05c01.dat","92198p05c02.dat"       , _
      "92198p05c03.dat","92198p05c04.dat","92198p05c05.dat","92198p06c01.dat","92198p07c01.dat"       , _
      "92198p08c01.dat","92198p08c02.dat","92198p08c03.dat","92198p08c04.dat","92198p08c05.dat"       , _
      "92198p08c06.dat","92198p08c07.dat","92198p09c01.dat","92198p09c02.dat","92198p10c01.dat"       , _
      "92198p10c02.dat","92198p11c01.dat","92198p12c01.dat","92198p13c01.dat","92198p14c01.dat"       , _
      "92198p14c02.dat","92198p15c01.dat","92198p15c02.dat","92240c01.dat","92240p01c01.dat"          , _
      "92241p01c01.dat","92241p02c01.dat","92241p03c01.dat","92241p04c01.dat","92241p05c01.dat"       , _
      "92241p06c01.dat","92241p07c01.dat","92241p08c01.dat","92241p09c01.dat","92241p0ac01.dat"       , _
      "92241p0bc01.dat","92241p0cc01.dat","92241p0dc01.dat","92241p0ec01.dat","92241p0fc01.dat"       , _
      "92241p0gc01.dat","92241p11c01.dat","92241p12c01.dat","92241p13c01.dat","92241p14c01.dat"       , _
      "92241p15c01.dat","92241p16c01.dat","92241p17c01.dat","92241p18c01.dat","92241p19c01.dat"       , _
      "92241p20c01.dat","92241p21c01.dat","92241p22c01.dat","92241p23c01.dat","92243p01c01.dat"       , _
      "92243p02c01.dat","923.dat","92693c01-f1.dat","92693c01-f2.dat","92693c02.dat","92693c03.dat"   , _
      "92909.dat","95228.dat","956.dat","u334.dat","u608.dat","u9017.dat","u9210p01c01.dat"           , _
      "u9210p02c01.dat","u9210p03c01.dat","u9325.dat","u9325c01.dat","u9327.dat","u9327c01.dat"       , _
      "u9355.dat","u9356c01.dat","19071c01.dat","43446c01.dat","47899c01d01.dat","47899c01d02.dat"    , _
      "47899c01d03.dat","47899c01d04.dat","47899c01d05.dat","47899c03.dat","4868ad01.dat"             , _
      "4868ad02.dat","4868bd01.dat","49309p01.dat","52040.dat","52258p01c01.dat","58122.dat"          , _
      "6272.dat","73194c01d01.dat","73194c01d02.dat","73194c01d03.dat","73194c01d04.dat","4162235.dat", _
      "73194c01d05.dat","73194c01d06.dat","73194c03.dat","92198p17c01.dat","92240p02c01.dat"          , _
      "92241p0hc01.dat","92241p0ic01.dat","92241p0jc01.dat","92241p0kc01.dat","92241p0lc01.dat"       , _
      "92241p0mc01.dat","92241p0nc01.dat","92241p0oc01.dat","92241p0pc01.dat","92241p0qc01.dat"       , _
      "92241p0rc01.dat","92241p0sc01.dat","92241p0tc01.dat","92241p0uc01.dat","92241p0vc01.dat"
         continue while 'ignore due to warnings
   case else
      'continue while
   end select   
   var iLin = csrlin(), iCol = pos()
   if LoadFile( sFullPath , sModel ) = 0 then
      print "Failed to load '"+sFile+"'" : continue while
   end if
   var pModel = LoadModel( strptr(sModel) , sFile )
   if pModel = 0 then
      print "Failed to model '"+sFile+"'" : continue while
   end if
   dim as PartSnap tSnap
   SnapModel( pModel , tSnap ) : pModel->pData = @tSnap
   if iLin <> csrlin() orelse iCol <> pos() then sError += """"+sFile+""","
   'if iLin = csrlin() andalso iCol = pos() then sError += """"+sFile+""","
   var bCat = DetectPartCathegory( pModel )
   if bCat = pcSlab then 
      color 11 : print "'"+sFile+"'";tab(20); : color 10
   else 
      continue while
      color 14 : iErrorCount += 1
   end if
   sError += """"+sFile+""","
   if bCat > ubound(pzCat) then color 13: puts("Unknown") else puts(pzCat(bCat))   
wend
close #f

if iErrorCount then
   color 12: printf(!"Done... ERRORS: %i\n",iErrorCount)   
else
   color 10: puts(!"Done... OK!")   
end if
sleep: end iErrorCount

#error





   
   
