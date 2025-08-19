#define __Main "ViewModel.bas"
'#define __Tester

'#define DebugShadow
'#define DebugShadowConnectors

'#define ColorizePrimatives
'#define RenderOptionals


'#ifndef __NoRender

#include "LoadLDR.bas"

#include "Include\Colours.bas"
#include "Modules\Clipboard.bas"

#include "Modules\InitGL.bas"
#include "Modules\Math3D.bas"
#include "Modules\Normals.bas"
#include "Modules\Matrix.bas"
#include "Modules\Model.bas"


' TODO: load extra info from STUDIO.io collision files parse 9 as "special bounding" boxes
' TODO: we need now the full polygon collision to detect better if the bounding boxes collide
' TODO: change the collision bounding boxes, to line markers that extend outside the model
' TODO: handle the case where viewing a part file instead of a model file (as subparts shouldnt be checked for collision)
' TODO: models with submodels shouldnt ignore the collision when it's a submodel (need to detect when?)
' TODO: (20/03/2025) fix invalid matrices back to identity ones

'https://www.melkert.net/LDCad/tech/meta

'TODO: check shadow library format, Load and parse them??
   'Continue parsing of shadow library (must include files)
   'parse the named parameters of each type of snap information
   'seems that only cylindrical ones will be important for now
   'Male being stud... Female being clutches (detect aliases? to account for others?)   

'TODO: !! check matrix orientation multiplication !!!

'TODO: add studs from the DAT file (in SizeModel function)
'TODO: rename SizeModel function to GetModelInfo (to calculate size,studs,clutches,etc...)
'TODO: list studs/clutches/axles, their positions and normal vectors
'TODO: can we match studs/clutches/axles from sub primatives? (only studs and aliases?)
'TODO: Length of shadow must be multiplied by matrix (Y=mat[4]), and duplicates must be ignored!

'???? Should All PinHoles add also an AxleHole? ???? (as they add a clutch)

'--------------------------------  NOTES: ------------------------------------
'STUDS     are normally defined on it's own (each stud have an included shadow entry)
'CLUTCHES  are normally defined on the main part shadow library (using GRIDS)
'ALIASES   "ID='aStud'" must be "F" designations wtihout using grids... or by subpart name?? (we are researching this)
'PINHOLES  ID='connhole'" must be "F" , Slide=true? (any clutch with slide?)
'BARHOLES  must be "F" , Slide=false , [caps=None](hollow otherwise semi-hollow) , sec=R 4

'barhole hollow
'<[gender=F] [caps=none] [secs=R 4 12] [pos=0 8 0]>
'barhole semi-hollow
'<[gender=F] [caps=one] [secs=R 4 4] [pos=0 -4 0] [ori=-1 0 0 0 -1 0 0 0 1] [grid=C 2 1 40 0]>
'stud2a (used on the semi-hollow/hollow
'[ID=studO] [gender=M] [caps=one] [secs=R 6 4]>

'---- for aliases ---

'stud3 (studs or aliases? used on "2431.dat"
'<[id=stud3] [gender=M] [caps=one] [secs=R 4 4] [scale=YOnly]>

'-----------------------------------------------------------------------------

var sPath = environ("userprofile")+"\Desktop\LDCAD\"
dim as string sFile
'pinhole
'{SNAP_CYL} - <[id=connhole] [gender=F] [caps=none] [secs=R 8 2   R 6 16   R 8 2] [center=true] [slide=true]>
'not pinhole
'{SNAP_CYL} - <[gender=F] [caps=none] [secs=R 6 6   A 6 6   R 4 16] [slide=true] [pos=0 24 0]>

'3044a 'Regx for good files = ^1.*\.dat
scope 
   'sFile = "3023.dat"
   'sFile = "3626cp0p.dat"
   'sFile = "65826.dat" 'no shadow pin?
   'sFile = "4274.dat" 'Duplicated Stud (bigger lock compressible cylinder)?? (still wrong stud count?) [!bad orientation?]
   'sFile = "3749.dat" 'axle+pin (duplicated axles) (no barhole!!) [!bad center?]
   'sFile = "18651.dat" 'axle+pin (duplicated axles) (the only one of this class with barhole) [!bad orientation?]
   'sFile = "3024.dat" 'duplicated clutches (CHECK: unknown male)
   'sFile = "18654.dat" 'pinhole (hollow pin = 2 clutches)
   'sFile = "32006.dat" 'pinholes+axlehole+clutch (duplicated axlehole both sides???????)
   'sFile = "4589.dat" ' axlehole with clutch (bigger hollow stud?) (duplicated axlehole both sides?????) [!bad orientation?]
   'sFile = "87994.dat" 'bar
   'sFile = "3461.dat" 'have a (king)fat pinhole (maybe add a fat clutch/pinhole class?)
   'sFile = "967.dat"  'have a (king)pin [??bad center??]
   'sFile = "3011.dat" 'duplo (extra clutches)
   'sFile = "3001.dat" 'clutches as aliases?
   'sFile = "3044a.dat" 'square clutches in a grid can slide? (or need hardcoded slide?) 
   
   'sFile = "4070.dat" '[!bad center]
   'sFile = "11203.dat" 'inverted tile '[!bad centering! (good test)] {?} '[grid centering?]
   'sFile = "32124.dat" '(axle holes) [!outside! female round] '[grid centering?]
   'sFile = "2711.dat" '(grid pinhole!! duplicated clutches (2711+steerend) [!outside! female round] '[!bad orientation]
   
   'sFile = "78329.dat"
   'sFile = "axlehole.dat"
   'sFile = "steerend.dat"
   'sFile = sPath+"\LDraw\parts\17715.dat" (removed??)
   'sFile = "15588.dat" 'alias of 48092 (need extra aliases clutches?)
   'sFile = "48092.dat"
   'sFile = "stud.dat"
   'sFile = "18651.dat" '(big axle that could have one extra virtual axle?) [!bad orientation!]
   ''sFile = "3703.dat" '(included shadow over a grid... TODO: implement!) (SNAP_INCL)
   ''sFile = "3003.dat" 'Shadow: SNAP_INCL
   ''sFile = "3004.dat" 'Shadow: SNAP_INCL (name ref? duplicated clutches? (ignore?) TODO!)
   'sFile = "4531.dat" 'Shadow: SNAP_* (hinges, TODO: later implement)
   'sFile = "3673.dat" 'Shadow: SNAP_CLEAR (extra pin, missing barhole?) [!good orientation?!]
   'sFile = "3002.dat" 'same class of piece as 3001.dat
   'sFile = "3022.dat" 'same class of piece as 3001.dat
   'sFile = "2431.dat" 'tile
   'sFile = "35459.dat" 'tile
   'sFile = "32530.dat" 'OK 6 clutches , 2 pinholes
   'sFile = "3865.dat" 'baseplate
   
   'sFile = "168315a.dat" 'sticker
   'sFile = "3001s01.dat" 'subpart of 3001.dat
   'sFile = "connhole.dat" 'subpart
   'sFile = "t01i3261.dat" 'subpart
   'sFile = "connect.dat" 'subpart
   'sFile = "axle.dat" 'subpart
   'sFile = "C:\Users\greg\Desktop\LDCAD\examples\5510.mpd"
end scope
scope
   'sFile = sPath+"\LDraw\parts\3001.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3002.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3003.dat"     'FINE (duplicated clutches from two subparts)
   'sFile = sPath+"\LDraw\parts\3004.dat"     'FINE (duplicated clutches
   'sFile = sPath+"\LDraw\parts\3005.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3006.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3007.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3008.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3009.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3010.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3011.dat"     'THE 59 LOOKS A LITTLE SUS BUT WHEN I TESTED I LDACAD IT SEEMS FINE
   'sFile = sPath+"\LDraw\parts\3018.dat"     'FINE (huge stud/clutch)
   'sFile = sPath+"\LDraw\parts\3020.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3021.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3022.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3023.dat"     'FINE plate
   'sFile = sPath+"\LDraw\parts\3026.dat"     'FINE (144 studs 259 clutches)
   'sFile = sPath+"\LDraw\parts\3027.dat"     'FINE plate
   'sFile = sPath+"\LDraw\parts\3030.dat"     'FINE plate
   'sFile = sPath+"\LDraw\parts\3031.dat"     'FINE plate
   'sFile = sPath+"\LDraw\parts\3032.dat"     'FINE plate
   'sFile = sPath+"\LDraw\parts\3033.dat"     'FINE plate
   'sFile = sPath+"\LDraw\parts\3034.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3035.dat"     'FINE plate
   'sFile = sPath+"\LDraw\parts\3036.dat"     'FINE plate
   'sFile = sPath+"\LDraw\parts\3037.dat"     'FINE (missing shadow for the clutch holes?)
   'sFile = sPath+"\LDraw\parts\3038.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3039.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\18654.dat"    'should be 20x20x20 but maybe it has a slightly thinner diameter compared to a 1x1 round brick
   'sFile = sPath+"\LDraw\parts\3062bp02.dat" 'FINE (A caps?)
   'sFile = sPath+"\LDraw\parts\4588.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3040.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3041.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3042.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3043.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3044.dat"     'FINE (special clutch) [!Center! mismatch]
   'sFile = sPath+"\LDraw\parts\3045.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3046.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3048.dat"      'FINE (special clutch) (TODO: (ignore) male grid of square clutches????)
   'sFile = sPath+"\LDraw\parts\3049.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3058.dat"     'FINE (combination of aliases) [!Center?! mismatch]
   'sFile = sPath+"\LDraw\parts\3062.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3063.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3065.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3066.dat"     'FINE (slide clutch defined as 8 clutches)
   'sFile = sPath+"\LDraw\parts\3067.dat"     'FINE (slide clutch)
   'sFile = sPath+"\LDraw\parts\3068.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3069.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3070.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3082.dat"     'THIS APPEARS TO BE WRONG, IT LOOKS LIKE ITS 2 LDU thick by 39 LDU tall including the nub and 32 LDU WIDE 
   'sFile = sPath+"\LDraw\parts\3109.dat"     'FINE (subpart? shadow does not account holes)
   'sFile = sPath+"\LDraw\parts\3110.dat"     '(subpart) this appears to be 20 LDU tall by 32 LDU wide by 72 LDU long
   'sFile = sPath+"\LDraw\parts\3111.dat"     '(no shadow) actually right :) (need further review on the subparts of this)
   'sFile = sPath+"\LDraw\parts\3112.dat"     '(no shadow) actually right :) (need further review on the subparts of this)
   'sFile = sPath+"\LDraw\parts\3127.dat"     '(size? mega wrong :D)
   'sFile = sPath+"\LDraw\parts\3130.dat"     'FINE (miss many shadow info)
   'sFile = sPath+"\LDraw\parts\3131.dat"     'FINE (miss many shadow info)
   'sFile = sPath+"\LDraw\parts\3134.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3135.dat"     '45 LDU not 100 LDU [!center! mismatch]
   'sFile = sPath+"\LDraw\parts\3136.dat"      'cool, fine (different size studs?)
   'sFile = sPath+"\LDraw\parts\3137.dat"     'FINE (check shadow?)
   'sFile = sPath+"\LDraw\parts\3139.dat"     'FINE (no shadow info)
   'sFile = sPath+"\LDraw\parts\3144.dat"     'damn this is actaully right (male grid (to be ignored?), two caps)
   'sFile = sPath+"\LDraw\parts\3145.dat"     '(TODO: 3 sided connections, missing some?) I cant move that finley in ldcad but 122.96 LDU looks correct as well as 69.28
   'sFile = sPath+"\LDraw\parts\3148.dat"     'FINE (TODO: hinge)
   'sFile = sPath+"\LDraw\parts\3149.dat"     'FINE (TODO: hinges)
   'sFile = sPath+"\LDraw\parts\3160.dat"     'width and depdth is fine, heigh seems kinda insaneley precise.
   'sFile = sPath+"\LDraw\parts\3161.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3167.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3176.dat"     'FINE (resume checking from here)
   'sFile = sPath+"\LDraw\parts\3190.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3191.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3192.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3193.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3194.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3195.dat"     'FINE
   'sFile = sPath+"\LDraw\parts\3200.dat"     'part doesn't exist but stop here (so at 3200)
    
   'sFile = sPath+"\LDraw\parts\3461.dat"     'height should be 20 not 24, width and depth is fine (24 both on part/subparts)
end scope
scope
   'sFile = sPath+"\LDraw\p\stud4.dat"
   'sFile = sPath+"\LDraw\p\4-4edge.dat"
   
   'sFile = sPath+"LDraw\models\car.ldr"
   'sFile = sPath+"\examples\5580.mpd"
   'sFile = exePath+"\..\Collision.ldr"
   
   'sFile = sPath+"LDraw\digital-bricks.de parts not in LDRAW\12892.dat"
   
   'crashing due to fallback additions
   '#include "CrashTest.bi"
   'sFile = sPath+"LDraw\models\pyramid.ldr"
   'sFile = sPath+"\examples\8891-towTruck.mpd"
   'sFile = "C:\Users\greg\Desktop\LDCAD\examples\5510.mpd"
   'sFile = "C:\Users\greg\Desktop\LDCAD\examples\cube10x10x10.ldr"
   sFile = "3001.dat" 
   'sFile = "3958.dat"
end scope
scope 
   #if 0
   "77844.dat" 'failed to detect as plate
   "122.dat","122c01.dat","122c01.dat","122c02.dat" 'not enough shadow data to discard as slab
   "24326.dat" 'recessed, so not a slab
   "15587.dat" '?????   
   "15625.dat" "18870.dat" 'probabily slab
   #endif
   'sFile = "2356.dat" '"4070.dat"
   '"2441.dat","2612.dat","2628.dat","2629.dat","27261.dat","2726c01.dat","2726c02.dat","274.dat","289.dat","30036.dat","30042.dat","30065.dat","30157b.dat","30234.dat","30303.dat","30303pa0.dat","30527c01.dat","30527c02.dat","30527c03.dat","32739.dat","33088.dat","33121.dat","33122.dat","33286.dat","35327.dat","35473.dat","36840.dat","37720a.dat","3788.dat","3960.dat","3960p01.dat","3960p02.dat","3960p03.dat","3960p04.dat","3960p05.dat","3960p06.dat","3960p07.dat","3960p08.dat","3960p09.dat","3960p0a.dat","3960p0b.dat","3960p0c.dat","3960p0d.dat","3960p0e.dat","3960p0f.dat","3960p0g.dat","3960p0h.dat","3960p0i.dat","3960pa0.dat","3960pa1.dat","3960pb0.dat","3960pb1.dat","3960pb2.dat","3960pb3.dat","3960pb4.dat","3960pb5.dat","3960pb9.dat","3960pbc.dat","3960pf1.dat","3960pf2.dat","3960ph0.dat","3960pm0.dat","3960ps1.dat","3960ps2.dat","3960ps3.dat","3960ps4.dat","3960ps5.dat","3960ps6.dat","3960ps7.dat","3960ps8.dat","3960psb.dat","3960psc.dat","3960pse.dat","3960pv1.dat","3960pv2.dat","3960pv3.dat","3960pv4.dat","3960px1.dat","3960px2.dat","3960px3.dat","39611.dat","40687.dat","4093.dat","4093a.dat","4093ad01.dat","4093b.dat","4093c.dat","41680.dat","41855.dat","4211.dat","4212a.dat","42409.dat","4270181.dat","4285.dat","4285a.dat","4285b.dat","43898.dat","43898p01.dat","43898p02.dat","43898pa1.dat","43898pa2.dat","43898ps1.dat","43898ps2.dat","43898px1.dat","43898px2.dat","44375.dat","44375a.dat","44375aps1.dat","44375aps2.dat","44375aps3.dat","44375b.dat","44375bp01.dat","44375bp03.dat","44375bpa0.dat","44375bps0.dat","44375bps1.dat","44375bps2.dat","44375p01.dat","44375p02.dat","4488.dat","44882.dat","45677.dat","45677d01.dat","45677ds1.dat","45729.dat","4590.dat","4616992.dat","47456.dat","47457.dat","4750.dat","4771a.dat","50949.dat","52031.dat","52031d01.dat","52031d02.dat","52031d03.dat","52031d50.dat","52031d51.dat","52037.dat","5306.dat","54093.dat","56640.dat","56641.dat","58124c01.dat","58124c02.dat","60212.dat","63082.dat","64570.dat","65138.dat","6584.dat","6625c01.dat","66789.dat","66790.dat","66792.dat","71752.dat","72132.dat","73832.dat","74166.dat","79743.dat","85975.dat","87609.dat","90001.dat","90001p01.dat","91049.dat","92088.dat","92338-f2.dat","92339.dat","92340.dat","93541.dat","98263.dat","98281.dat","98383.dat","99206.dat","99780.dat","20952p02.dat","2612.dat","2628.dat","2629.dat","30157b.dat","30303.dat","30303pa0.dat","3263.dat","33088.dat","3960p0g.dat","3960p0h.dat","3960ph0.dat","3960ps9.dat","40687.dat","4093ad01.dat","43898p03.dat","43898p04.dat","44375bp02.dat","44375bp03.dat","44375bp04.dat","44375bp05.dat","44375bp06.dat","44375bp07.dat","44375bps2.dat","45677d02.dat","45677d03.dat","45677d04.dat","45677d05.dat","45677d06.dat","45677ds1.dat","45677dy0.dat","47456.dat","52031d01.dat","52031d03.dat","52031d04.dat","52031d05.dat","5306.dat","65138.dat","65468d.dat","71752.dat","72132.dat","73832.dat","74166.dat","79743.dat","89681.dat","90001c01.dat","90001c01p01.dat","90001p01.dat","92338-f2.dat","93541.dat","99206.dat","u9541.dat",   
end scope

dim as string sModel
dim as DATFile ptr pModel

#if 0 '1 = Load File , 0 = Load From clipboard
   if len(sFile)=0 then sFile=command(1)
   if instr(sFile,"\")=0 andalso instr(sFile,"/")=0 then FindFile(sFile)
   printf(!"Model: '%s'\n",sFile)
   if LoadFile( sFile , sModel ) = 0 then
      print "Failed to load '"+sFile+"'"
      sleep : system
   end if
   pModel = LoadModel( strptr(sModel) , sFile )
#else
   sModel = command(1)
   var sEndsExt = lcase(right(sModel,4))
   var IsFilename = (instr(sModel,chr(10))=0) andalso ((sEndsExt=".dat") orelse (sEndsExt=".ldr"))
   if IsFilename then
      print "loading from '"+sModel+"'"
      if FileExists(sModel)=0 then FindFile(sModel)      
      if LoadFile( sModel , sModel ) = 0 then
         print "Failed to load '"+sModel+"'"
         sleep : system
      end if   
   else
      if instr(sModel,".dat")  then
         print "loading from cmdline"
         for N as long = 0 to len(sModel)
            if sModel[N]=13 then sModel[N]=32
         next N
      else
         print "loading from clipboard"
         sModel = GetClipboard() 
         if instr(sModel,".dat") then
            for N as long = 0 to len(sModel)
               if sModel[N]=13 then sModel[N]=32
            next N
         else 'if there isnt a model in the clipboard, then load this:
            'sModel = _    
            '"1 2 0.000000 0.000000 0.000000 1 0 0 0 1 0 0 0 1 4070.dat" EOL _
            ' ------------------------------------------------------
            'sModel = _ 'all of lines belo should end with EOL _
            '   "1 4 0 0 0 1 0 0 0 1 0 0 0 1 30068.dat"    EOL _
            '   "1 1 0 -10 0 1 0 0 0 1 0 0 0 1 18654.dat"  EOL _
            ' ------------------------------------------------------
            'sModel = _
            '   "1 0 0.000000 0.000000 0.000000 1 0 0 0 1 0 0 0 1 3958.dat"       EOL _
            '   "1 16 -50.000000 -24.000000 50.000000 1 0 0 0 1 0 0 0 1 3005.dat" EOL _
            ' ------------------------------------------------------
            sModel = _
               "1 2 0.000000 0.000000 0.000000 1 0 0 0 1 0 0 0 1 3001.dat"      EOL _
               "1 0 -60.000000 -24.000000 20.000000 1 0 0 0 1 0 0 0 1 3001.dat"  EOL _
            
         end if
      end if            
   end if
   pModel = LoadModel( strptr(sModel) , "CopyPaste.ldr" )
   
#endif

InitOpenGL()

'glPolygonMode( GL_FRONT_AND_BACK, GL_LINE )

dim as single fRotationX = 120 , fRotationY = 20
dim as single fPositionX , fPositionY , fPositionZ , fZoom = -3
dim as long iWheel , iPrevWheel
dim as long g_DrawCount = pModel->iPartCount , g_CurDraw = -1

var iModel   = glGenLists( 1 )
glNewList( iModel ,  GL_COMPILE ) 'GL_COMPILE_AND_EXECUTE
RenderModel( pModel , false )
glEndList()
var iBorders = glGenLists( 2 )
glNewList( iBorders ,  GL_COMPILE )
RenderModel( pModel , true )
glEndList()
glNewList( iBorders+1 ,  GL_COMPILE )
RenderModel( pModel , true , , -2 )
glEndList()


dim as single xMid,yMid,zMid , g_zFar
dim as PartSize tSz
dim as long g_PartCount , g_CurPart = -1

SizeModel( pModel , tSz , , g_PartCount )
with tSz
   xMid = (.xMin+.xMax)/2
   yMid = (.yMin+.yMax)/2
   zMid = (.zMin+.zMax)/2
   if abs(xMid-.xMin) > g_zFar then g_zFar = abs(xMid-.xMin)  
   if abs(yMid-.yMin) > g_zFar then g_zFar = abs(yMid-.yMin)  
   if abs(zMid-.zMin) > g_zFar then g_zFar = abs(zMid-.zMin)  
   if abs(xMid-.xMax) > g_zFar then g_zFar = abs(xMid-.xMax)  
   if abs(yMid-.yMax) > g_zFar then g_zFar = abs(yMid-.yMax)  
   if abs(zMid-.zMax) > g_zFar then g_zFar = abs(zMid-.zMax)  
   
   printf(!"X %f > %f (%g ldu)\n",.xMin,.xMax,(.xMax-.xMin))
   printf(!"Y %f > %f (%g ldu)\n",.yMin,.yMax,(.yMax-.yMin))
   printf(!"Z %f > %f (%g ldu)\n",.zMin,.zMax,(.zMax-.zMin))
   printf(!"Lines: %i - Optis: %i - Trigs: %i - Quads: %i - Verts: %i\n", _
      g_TotalLines , g_TotalOptis , g_TotalTrigs , g_TotalQuads , _
      g_TotalLines*2+g_TotalOptis*2+g_TotalTrigs*3+g_TotalQuads*4 _
   )
   
end with

redim as PartCollisionBox atCollision()
CheckCollisionModel( pModel , atCollision() )
printf(!"Parts: %i , Collisions: %i \n",g_PartCount,ubound(atCollision)\2)

#ifdef DebugShadowConnectors
   dim as PartSnap tSnap
   SnapModel( pModel , tSnap )
   with tSnap
      printf(!"Studs=%i Clutchs=%i Aliases=%i Axles=%i Axlehs=%i Bars=%i Barhs=%i Pins=%i Pinhs=%i\n", _
      .lStudCnt , .lClutchCnt , .lAliasCnt , .lAxleCnt , .lAxleHoleCnt ,.lBarCnt , .lBarHoleCnt , .lPinCnt , .lPinHoleCnt )
      puts("---------- stud ----------")
      for N as long = 0 to .lStudCnt-1
         with .pStud[N]
            printf(!"#%i %g %g %g\n",N+1,.fPX,.fPY,.fPZ)
         end with
      next N
      puts("--------- clutch ---------")
      for N as long = 0 to .lClutchCnt-1
         with .pClutch[N]
            printf(!"#%i %g %g %g\n",N+1,.fPX,.fPY,.fPZ)
         end with
      next N
   end with
#endif

'do : sleep 50 : flip : loop

'puts("")
'puts("3001 B1 s7 = 3001 B2 c1;")
'puts("1 0 40 -24 -20 1 0 0 0 1 0 0 0 1 3001.dat")
'puts("1 0 0 0 0 1 0 0 0 1 0 0 0 1 3001.dat")

dim as double dRot = timer
dim as boolean bBoundingBox
dim as boolean bLeftPressed,bRightPressed,bWheelPressed
dim as long iFps

'DrawLimitsCube( .xMin-1,.xMax+1 , .yMin-1,.yMax+1 , .zMin-1,.zMax+1 )
with tSz   
   
   'puts(".xMin=" & .xMin & " .xMax=" & .xMax)
   'puts(".yMin=" & .yMin & " .yMax=" & .yMax)
   'puts(".zMin=" & .zMin & " .zMax=" & .zMax)
   
   fPositionX = ((.xMax+.xMin)\-2) '-.xMin
   fPositionY = (.yMax+.yMin)\2
   'printf(!"\nzmin=%f zmax=%f\n",.zMin,.zMax)
   fPositionZ = (.zMax-.zMin) 'abs(.zMax)-abs(.zMin)
   'fPositionZ = abs(iif(abs(.zMin)>abs(.zMax),.zMin,.zMax))
   fPositionZ = sqr(fPositionZ)*-40
end with

dim as PartSnap tSnapID

do
   glClear GL_COLOR_BUFFER_BIT OR GL_DEPTH_BUFFER_BIT      
   glLoadIdentity()   
   glScalef(1/-20, 1.0/-20, 1/20 )
   
   static as long OldDraw = -1
   if g_CurDraw <> -1 andalso OldDraw <> g_CurDraw then
      SnapModel( pModel , tSnapID , g_CurDraw )
      SortSnap( tSnapID )
   end if
      
   '// Set light position (0, 0, 0)
   dim as GLfloat lightPos(...) = {0,0,0, 1.0f}'; // (x, y, z, w), w=1 for positional light
   glLightfv(GL_LIGHT0, GL_POSITION, @lightPos(0))
         
   'g_zFar
   glTranslatef( -fPositionX , fPositionY , fPositionZ*(fZoom+4) ) '80*fZoom ) '/-5)
   'glTranslatef( 0 , 0 , -80*(fZoom+4) )
         
   glRotatef fRotationY , -1.0 , 0.0 , 0
   glRotatef fRotationX , 0   , -1.0 , 0
         
   glPushMatrix()
   with tSz
      'glTranslatef( (.xMin+.xMax)/-2  , (.yMin+.yMax)/-2 , (.zMin+.zMax)/-2 )
   end with
      
   glDisable( GL_LIGHTING )
   glEnable( GL_DEPTH_TEST )
   
   g_fNX=-.95 : g_fNY=.95
      
   if g_CurDraw < 0 then
      glCallList(	iModel )   
   else
      RenderModel( pModel , false , , g_CurDraw )      
   end if
   glCallList(	iBorders-(g_CurDraw>=0) )   

   glEnable( GL_LIGHTING )
   
   #ifdef DebugShadow
   dim as PartSnap tSnap
   static as byte bOnce   
   'if bOnce=0 then
      'SnapModel( pModel , tSnap , 2 )
      'bOnce=1
   'else
      SnapModel( pModel , tSnap , true )
   'end if
   #endif

   #if 0
      glEnable( GL_POLYGON_STIPPLE )
      
      'SnapModel( pModel , tSnap )
      
      #if 0 
         glPushMatrix()
         glTranslatef( 10 , -2f , 0 ) '/-5)
         glRotatef( 90 , 1,0,0 )
         glScalef( 2 , 2 , (4.0/6.0) ) 'square
         'glScalef( 8f/7f , 8f/7f , (4.0/6.0)*(5f/7f) ) 'cylinder
         glPolygonStipple(	cptr(glbyte ptr,@MaleStipple(0)) )   
         glColor3f( 0 , 1 , 0 )
         'glutSolidSphere( 6 , 18 , 7 ) 'male round (.5,.5,N\2)
         glutSolidCube(6) 'male square (1,1,N)
         glPopMatrix()
      #endif
      #if 0
         glPushMatrix()
         glTranslatef( 10 , -2f , 0 )
         
         glRotatef( 90 , 1,0,0 )
         glRotatef( 45 , 0,0,1 ) 'square
         glScalef( 1 , 1 , 4 )      
         
         glPolygonStipple(	cptr(glbyte ptr,@FeMaleStipple(0)) )
         glColor3f( 1 , 0 , 0 )   
         glutSolidTorus( 0.5 , 6 , 18 , 4  ) 'female "square" (.5,.5,N*8)
         'glutSolidTorus( 0.5 , 6 , 18 , 18 ) 'female round? (.5,.5,N*8)
         glPopMatrix()
      #endif
      
      glDisable( GL_POLYGON_STIPPLE )
   #endif
   
   glDepthMask (GL_FALSE)
   if bBoundingBox then
      glColor4f(0,1,0,.25)
      with tSz
         DrawLimitsCube( .xMin-1,.xMax+1 , .yMin-1,.yMax+1 , .zMin-1,.zMax+1 )      
      end with
   end if
   
   var iCollisions = ubound(atCollision)
   if iCollisions andalso instr(sFile,".dat")=0 then
      glEnable( GL_POLYGON_STIPPLE )      
      static as ulong aStipple(32-1)
      dim as long iMove = (timer*8) and 7
      for iY as long = 0 to 31         
         var iN = iif(iY and 1,&h1414141414141414ll,&h4141414141414141ll)         
         aStipple(iY) = iN shr ((iY+iMove) and 7)
      next iY
      glPolygonStipple(	cptr(glbyte ptr,@aStipple(0)) )
      if (iMove and 2) then glColor4f(1,0,0,1) else glColor4f(0,0,0,1)
      for I as long = 0 to iCollisions-1   
         with atCollision(I)
            DrawLimitsCube( .xMin-1,.xMax+1 , .yMin-1,.yMax+1 , .zMin-1,.zMax+1 )
         end with
      next I
      glDisable( GL_POLYGON_STIPPLE )      
   end if
   glDepthMask (GL_TRUE)
   
   glPopMatrix()
   
   'glDisable( GL_DEPTH_TEST )
   
   #macro DrawConnectorName( _YOff )      
      var sText = "" & N+1
      #if 0     
         glPushMatrix()
         glTranslatef( .fpX , .fPY , .fPZ )
         glRotatef fRotationX  , 0   , 1.0 , 0 : glRotatef fRotationY  , 1.0 , 0.0 , 0            
         glRotatef 90  , 1.0 , 0 , 0 : glRotatef 180  , 0 , 0 , 1.0
         glDrawText( sText , 0,0,0 , 8/len(sText),8 , true )
         glPopMatrix()
      #else
         glDrawText( sText , .fPX,.fPY+(_YOff),.fPZ , 8/len(sText),8 , true )
      #endif
   #endmacro

   if g_CurDraw <> -1 then      
      with tSnapID         
         glColor4f(0,1,0,1)         
         for N as long = 0 to .lStudCnt-1
            with .pStud[N]
               DrawConnectorName(-5)
            end with         
         next N                  
         glColor4f(1,0,0,1)
         for N as long = 0 to .lClutchCnt-1
            with .pClutch[N]
               DrawConnectorName(+5)
            end with
         next N
      end with
      OldDraw = g_CurDraw
   end if
   
   glClear GL_DEPTH_BUFFER_BIT
               
   #define DrawMarker( _X , _Y , _Z ) DrawLimitsCube( (_X)-2,(_X)+2 , (_Y)-2,(_Y)+2 , (_Z)-2,(_Z)+2 )      
   glColor4f(1,.5,.25,.66) : DrawMarker( 0,0,0 )
         
   
   'glColor4f(.25,.5,1,.66) : DrawMarker( -50,0,-50 )
   
            
   Dim e as fb.EVENT = any
   while (ScreenEvent(@e))
      Select Case e.type
      Case fb.EVENT_MOUSE_MOVE
         if bLeftPressed  then fRotationX += e.dx : fRotationY += e.dy
         if bRightPressed then fPositionX += e.dx*g_zFar/100 : fPositionY += e.dy*g_zFar/100
      case fb.EVENT_MOUSE_WHEEL
         iWheel = e.z-iPrevWheel
         fZoom = -3+(-iWheel/3)
      case fb.EVENT_MOUSE_BUTTON_PRESS
         if e.button = fb.BUTTON_MIDDLE then 
            iPrevWheel = iWheel
            fZoom = -3
         end if
         if e.button = fb.BUTTON_LEFT   then bLeftPressed  = true
         if e.button = fb.BUTTON_RIGHT  then bRightPressed = true
      case fb.EVENT_MOUSE_BUTTON_RELEASE
         if e.button = fb.BUTTON_LEFT   then bLeftPressed  = false
         if e.button = fb.BUTTON_RIGHT  then bRightPressed = false      
      case fb.EVENT_KEY_PRESS
         select case e.ascii
         case 8
            if bBoundingBox then
               g_CurPart = -1
               printf(!"g_CurPart = %i    \r",g_CurPart)
               dim as PartSize tSzTemp
               SizeModel( pModel , tSzTemp , g_CurPart )
               tSz = tSzTemp
            else
               g_CurDraw = -1
               printf(!"g_CurDraw = %i    \r",g_CurDraw)
            end if               
         case asc("="),asc("+")
            if bBoundingBox then
               g_CurPart = ((g_CurPart+2) mod (g_PartCount+1))-1
               printf(!"g_CurPart = %i    \r",g_CurPart)
               dim as PartSize tSzTemp
               SizeModel( pModel , tSzTemp , g_CurPart )
               tSz = tSzTemp
            else
               g_CurDraw = ((g_CurDraw+2) mod (g_DrawCount+1))-1
               printf(!"g_CurDraw = %i    \r",g_CurDraw)
            end if
         case asc("-"),asc("_")
            if bBoundingBox then
               g_CurPart = ((g_CurPart+g_PartCount+1) mod (g_PartCount+1))-1
               printf(!"g_CurPart = %i    \r",g_CurPart)
               dim as PartSize tSzTemp
               SizeModel( pModel , tSzTemp , g_CurPart )
               tSz = tSzTemp
            else
               g_CurDraw = ((g_CurDraw+g_DrawCount+1) mod (g_DrawCount+1))-1
               printf(!"g_CurDraw = %i    \r",g_CurDraw)
            end if               
         end select
         select case e.scancode
         case fb.SC_TAB
            bBoundingBox = not bBoundingBox
         end select
      case fb.EVENT_WINDOW_CLOSE
         exit do
      end select
   wend
               
   flip   
   static as double dFps : iFps += 1   
   if abs(timer-dFps)>1 then
      dFps = timer      
      'WindowTitle("Fps: " & cint(1/(timer-dRot)))
      WindowTitle("Fps: " & iFps): iFps = 0
      'if dFps=0 then dFps = (timer-dRot) else dFps = (dFps+(timer-dRot))/2
   else
      sleep 1
   end if
   
   'WindowTitle("Fps: " & cint(1/(timer-dRot)))
   
   'fRotation -= (timer-dRot)*30
   dRot = timer
   
loop until multikey(fb.SC_ESCAPE)
sleep


