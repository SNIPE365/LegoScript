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
   tSnaps as PartSnap
end type

'lStudCnt     as long
'lClutchCnt   as long
'lAliasCnt    as long 
'lAxleCnt     as long
'lAxleHoleCnt as long
'lBarCnt      as long
'lBarHoleCnt  as long
'lPinCnt      as long
'lPinHoleCnt  as long   


#define q(_n) ((_n)*1) 'duplicated male
#define d(_n) ((_n)*2) 'duplicated female

'   (@"3626cp0p.dat",(   0   ,   0    ,   0   ,  0   ,   0   ,  0  ,  0   ,  0  ,  0  )) _
dim as PartCheck tCheckList(...) = { _
_   '    name      ,  Stud  , Clutch , Alias , Axle , AxleH , Bar , BarH , Pin , PinH
   (@"3023.dat"    ,(   2   ,   2    ,   0   ,  0   ,   0   ,  1  ,  0   ,  0  ,  0  )), _
   (@"3626cp0p.dat",(   2   ,   1    ,   0   ,  0   ,   0   ,  0  ,  1   ,  0  ,  1  )), _
   (@"4274.dat"    ,( 1+q(1),   0    ,   0   ,  0   ,   0   ,  0  ,  2   ,  1  ,  0  )), _ 'careful duplication pin/stud
   (@"3749.dat"    ,(   0   ,   0    ,   0   , q(1) ,   0   ,  0  ,  0   ,  1  ,  0  )), _ 'missing barhole
   (@"18651.dat"   ,(   0   ,   0    ,   0   , q(1) ,   0   ,  0  ,  1   ,  1  ,  0  )), _
   (@"3024.dat"    ,(   1   ,  d(1)  ,   0   ,  0   ,   0   ,  0  ,  0   ,  0  ,  0  )), _
   (@"3044a.dat"   ,(   0   ,   2    ,   0   ,  0   ,   0   ,  0  ,  0   ,  0  ,  0  )), _
   (@"18654.dat"   ,(   0   ,   2    ,   0   ,  0   ,   0   ,  0  ,  0   ,  0  ,  1  )), _   
   _ '(@"32006.dat"   ,(   0   ,   5    ,   0   ,  0   ,   4   ,  0  ,  0   ,  0  ,  2  )), _ 'cool :D
   _ '(@"4589.dat"    ,(   1   ,   1    ,   0   ,  0   ,   2   ,  0  ,  1   ,  0  ,  0  )), _ 'bigger stud that we're ignoring 
   (@"87994.dat"   ,(   0   ,   0    ,   0   ,  0   ,   0   ,  1  ,  0   ,  0  ,  0  )), _
   (@"3461.dat"    ,(   8   ,   1    ,   0   ,  0   ,   0   ,  4  ,  0   ,  0  ,  1  )), _  'fat clutch/pinhole
   (@"967.dat"     ,(  32   ,  53    ,   0   ,  0   ,   0   ,  0  ,  0   ,  1  ,  0  )), _
   (@"3001.dat"    ,(   8   ,  11    ,   0   ,  0   ,   0   ,  0  ,  0   ,  0  ,  0  )), _
   _ ''(@"3002.dat"    ,(   6   ,   8    ,   0   ,  0   ,   0   ,  0  ,  0   ,  0  ,  0  )), _ 'same case as 3001? comment it out?
   (@"3007.dat"    ,(  16   ,  23    ,   0   ,  0   ,   0   ,  0  ,  0   ,  0  ,  0  )), _
   (@"4070.dat"    ,(   2   ,   2    ,   0   ,  0   ,   0   ,  0  ,  2   ,  0  ,  0  )), _
   (@"78329.dat"   ,(   5   ,   5    ,   0   ,  0   ,   0   ,  4  ,  0   ,  0  ,  0  )), _
   _ '(@"2711.dat"    ,(   2   ,   6    ,   0   ,  0   ,   2   ,  0  ,  2   ,  0  ,  4  )), _
   (@"32124.dat"   ,(   4   ,   4    ,   0   ,  0   ,   2   ,  2  ,  4   ,  0  ,  0  )), _
   (@"15588.dat"   ,(   3   ,   3    ,   0   ,  0   ,   0   ,  0  ,  0   ,  0  ,  0  )), _   
   (@"18651.dat"   ,(   0   ,   0    ,   0   ,  1   ,   0   ,  0  ,  1   ,  1  ,  0  )), _
   (@"35459.dat"   ,(   3   ,   0    ,   0   ,  0   ,   0   ,  0  ,  4   ,  0  ,  0  )), _
   (@"32530.dat"   ,(   0   ,   6    ,   0   ,  0   ,   0   ,  0  ,  0   ,  0  ,  2  )), _
   (@"3865.dat"    ,( 128   ,   0    ,   0   ,  0   ,   0   ,  0  ,  0   ,  0  ,  0  )), _
   (@"4588.dat"    ,(   1   ,   1    ,   0   ,  0   ,   0   ,  0  ,  2   ,  0  ,  0  )), _
   (@"3058.dat"    ,(  60   ,  84    ,   0   ,  0   ,   0   , 18  ,  0   ,  0  ,  0  )), _
   (@"3066.dat"    ,(   4   ,   8    ,   0   ,  0   ,   0   ,  0  ,  0   ,  0  ,  0  )), _  'slide clutch defined as 8 clutches
   (@"3127.dat"    ,(   2   ,   2    ,   0   ,  0   ,   0   ,  1  ,  0   ,  0  ,  0  )), _
   (@"3135.dat"    ,(   2   ,   8    ,   0   ,  0   ,   0   ,  0  ,  0   ,  0  ,  0  )), _
   (@"3136.dat"    ,(   6   ,   0    ,   0   ,  0   ,   0   ,  0  ,  4   ,  0  ,  0  )), _
   (@"3167.dat"    ,(   0   ,  10    ,   0   ,  0   ,   0   ,  0  ,  0   ,  0  ,  5  )) _
   _'    name      ,  Stud  , Clutch , Alias , Axle , AxleH , Bar , BarH , Pin , PinH   
}

for N as long = 0 to ubound( tCheckList )
   with tCheckList(N)
      var sFile = *.pzName , sModel = ""
      FindFile(sFile) : 'printf(!"Model: '%s'\n",sFile)
      color 11 : print left(*.pzName+space(18),18);: color 7
      if LoadFile( sFile , sModel ) = 0 then
         print "Failed to load '"+sFile+"'" : continue for      
      end if
      var pModel = LoadModel( strptr(sModel) , sFile )
      dim as PartSnap tSnap
      SnapModel( pModel , tSnap )
      var p = @.tSnaps
      with tSnap
         printf(!"Studs:%3i  Clutchs:%2i  Aliases:%2i  Axles:%2i  Axlehs:%2i  Bars:%2i  Barhs:%2i  Pins:%2i  Pinhs:%2i ", _
         .lStudCnt , .lClutchCnt , .lAliasCnt , .lAxleCnt , .lAxleHoleCnt ,.lBarCnt , .lBarHoleCnt , .lPinCnt , .lPinHoleCnt )
         #define CheckMember( _Name ) if .l##_Name##Cnt <> p->l##_Name##Cnt then color 12: iError += 1 : print !"\n" #_Name " Mismatch. Wanted: " & p->l##_Name##Cnt & "  Got: " & .l##_Name##Cnt;: color 7
         var iError = 0
         CheckMember( Stud )
         CheckMember( Clutch )
         'CheckMember( Alias )
         CheckMember( Axle )
         CheckMember( AxleHole )
         CheckMember( Bar )
         CheckMember( BarHole )
         CheckMember( Pin )
         CheckMember( PinHole )         
         if iError=0 then 
            color 10 : print " OK" : color 7
         else 
            color 4
            printf(!"\n%i Error(s) in Model: '%s'\n",iError,sFile)
            color 7
         end if
      end with

   end with
next N

print "Done"
sleep





   
   
