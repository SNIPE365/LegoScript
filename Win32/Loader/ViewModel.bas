#define __Main "ViewModel.bas" '-mavx
#cmdline "-gen gcc -fpu sse -O 3 -Wc '-O1 -march=native' -Wl '--large-address-aware'"

#include "windows.bi"

#if __FB_DEBUG__
  #include "MyTDT\Exceptions.bas"
  StartExceptions()
#endif

#include once "crt.bi"
#include once "vbcompat.bi"

'#define LoadFromSFile
'#define __Tester

'#define DebugShadow
'#define DebugShadowConnectors

'#define IgnoreStudSubparts
'#define ColorizePrimatives
'#define RenderOptionals //broken
'#define DebugLoading
'#define PrimitiveWarnings

#define UseFBO
#define UseVBO

'#ifndef __NoRender

declare function DropFilesHandler( hDrop as HANDLE ) as LRESULT

#include "Modules\Matrix.bas"
#include "LoadLDR.bas"

#include "Include\Colours.bas"
#include "Modules\Clipboard.bas"

#include "Modules\InitGL.bas"
#include "Modules\Math3D.bas"
#include "Modules\Normals.bas"
#include "Modules\Model.bas"

#include "win\mmsystem.bi"
TimeBeginPeriod(1)

#if 0
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
    
  'pinhole
  '{SNAP_CYL} - <[id=connhole] [gender=F] [caps=none] [secs=R 8 2   R 6 16   R 8 2] [center=true] [slide=true]>
  'not pinhole
  '{SNAP_CYL} - <[gender=F] [caps=none] [secs=R 6 6   A 6 6   R 4 16] [slide=true] [pos=0 24 0]>
  
  '3044a 'Regx for good files = ^1.*\.dat
#endif

var sPath = environ("userprofile")+"\Desktop\LDCAD\"
dim shared as string sFile

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
 'sFile = "G:\Jogos\LDCad-1-7-Beta-1-Win\examples\5510.mpd" '5521,5533,5540,5541,5542
 'sFile = "G:\Jogos\LDCad-1-7-Beta-1-Win\examples\5542.mpd" 
 'sFile = "G:\Jogos\LDCad-1-7-Beta-1-Win\examples\8851.mpd"
 'sFile = "G:\Jogos\LDCad-1-7-Beta-1-Win\LDraw\models\pyramid.ldr"
 'sFile = "G:\Jogos\LDCad-1-7-Beta-1-Win\LDraw\models\car.ldr"
 'sFile = "C:\Users\greg\Desktop\LDCAD\examples\cube10x10x10.ldr"
 'sFile = "C:\Users\greg\Desktop\LS\TLG_Map\TrainStationEntranceA.ldr"
 'sFile = "G:\Jogos\LegoScript-Main\examples\TLG_Map0\Build\Blocks\B1\Eldon Square.ldr"   
 'sFile = "G:\Jogos\LegoScript-Main\examples\TLG_Map\TestMap2.ldr"
 'sFile = "G:\Jogos\LegoScript-Main\examples\TLG_Map\Blocks\10190-1 Market Street.ldr"   
 'sFile = "G:\Jogos\LegoScript-Main\examples\TLG_Map\Blocks\10232 - Palace Cinema.mpd"
 'sFile = "G:\Jogos\LegoScript-Main\examples\TLG_Map\Blocks\10255 - Assembly Square.mpd"
 'sFile = "G:\Jogos\LegoScript-Main\examples\TLG_Map\Blocks\8418_mini_loader.mpd"
 'sFile = "G:\Jogos\LegoScript-main\examples\TLG_Map\Precolored\player\player.ldr"
 'sFile = "G:\Jogos\LegoScript\examples\10294 - Titanic.mpd"
 'sFile = "C:\Users\greg\Desktop\LS\TLG_Map\FileA.ldr"
 'sFile = "light.dat"
 'sFile = "3001.dat"
 'sFile = "60483.dat"
 'sFile = "G:\Jogos\LDCad-1-7-Beta-1-Win\ldraw\parts\s\60483s01.dat"
 'sFile = "F:\10294 - Titanic.mpd"
 'sFile = "4070.dat" '4070 , 87087 , 26604 , 47905 , 4733 , 30414
 'sFile = "G:\Jogos\LegoScript-main\examples\cube\cube.ldr"
 
  #if 0 ' >>> FOR TEXTURES >>>
    sFile = "39266p03.dat"
    0 !TEXMAP START PLANAR -50 0 10 50 0 10 -50 48 10 39266p02.png
    0 !: 4 16 50 0 -10 -50 0 -10 -50 48 -10 50 48 -10
    0 !TEXMAP FALLBACK
    4 16 50 0 -10 -50 0 -10 -50 48 -10 50 48 -10
  #endif
  
end scope
scope
   #if 0
     "77844.dat" 'failed to detect as plate
     "122.dat","122c01.dat","122c01.dat","122c02.dat" 'not enough shadow data to discard as slab
     "24326.dat" 'recessed, so not a slab
     "15587.dat" '?????   
     "15625.dat" "18870.dat" 'probabily slab
   #endif
   'sFile = "3819.dat"
   'sFile = "2356.dat" '"4070.dat"
   '"2441.dat","2612.dat","2628.dat","2629.dat","27261.dat","2726c01.dat","2726c02.dat","274.dat","289.dat","30036.dat","30042.dat","30065.dat","30157b.dat","30234.dat","30303.dat","30303pa0.dat","30527c01.dat","30527c02.dat","30527c03.dat","32739.dat","33088.dat","33121.dat","33122.dat","33286.dat","35327.dat","35473.dat","36840.dat","37720a.dat","3788.dat","3960.dat","3960p01.dat","3960p02.dat","3960p03.dat","3960p04.dat","3960p05.dat","3960p06.dat","3960p07.dat","3960p08.dat","3960p09.dat","3960p0a.dat","3960p0b.dat","3960p0c.dat","3960p0d.dat","3960p0e.dat","3960p0f.dat","3960p0g.dat","3960p0h.dat","3960p0i.dat","3960pa0.dat","3960pa1.dat","3960pb0.dat","3960pb1.dat","3960pb2.dat","3960pb3.dat","3960pb4.dat","3960pb5.dat","3960pb9.dat","3960pbc.dat","3960pf1.dat","3960pf2.dat","3960ph0.dat","3960pm0.dat","3960ps1.dat","3960ps2.dat","3960ps3.dat","3960ps4.dat","3960ps5.dat","3960ps6.dat","3960ps7.dat","3960ps8.dat","3960psb.dat","3960psc.dat","3960pse.dat","3960pv1.dat","3960pv2.dat","3960pv3.dat","3960pv4.dat","3960px1.dat","3960px2.dat","3960px3.dat","39611.dat","40687.dat","4093.dat","4093a.dat","4093ad01.dat","4093b.dat","4093c.dat","41680.dat","41855.dat","4211.dat","4212a.dat","42409.dat","4270181.dat","4285.dat","4285a.dat","4285b.dat","43898.dat","43898p01.dat","43898p02.dat","43898pa1.dat","43898pa2.dat","43898ps1.dat","43898ps2.dat","43898px1.dat","43898px2.dat","44375.dat","44375a.dat","44375aps1.dat","44375aps2.dat","44375aps3.dat","44375b.dat","44375bp01.dat","44375bp03.dat","44375bpa0.dat","44375bps0.dat","44375bps1.dat","44375bps2.dat","44375p01.dat","44375p02.dat","4488.dat","44882.dat","45677.dat","45677d01.dat","45677ds1.dat","45729.dat","4590.dat","4616992.dat","47456.dat","47457.dat","4750.dat","4771a.dat","50949.dat","52031.dat","52031d01.dat","52031d02.dat","52031d03.dat","52031d50.dat","52031d51.dat","52037.dat","5306.dat","54093.dat","56640.dat","56641.dat","58124c01.dat","58124c02.dat","60212.dat","63082.dat","64570.dat","65138.dat","6584.dat","6625c01.dat","66789.dat","66790.dat","66792.dat","71752.dat","72132.dat","73832.dat","74166.dat","79743.dat","85975.dat","87609.dat","90001.dat","90001p01.dat","91049.dat","92088.dat","92338-f2.dat","92339.dat","92340.dat","93541.dat","98263.dat","98281.dat","98383.dat","99206.dat","99780.dat","20952p02.dat","2612.dat","2628.dat","2629.dat","30157b.dat","30303.dat","30303pa0.dat","3263.dat","33088.dat","3960p0g.dat","3960p0h.dat","3960ph0.dat","3960ps9.dat","40687.dat","4093ad01.dat","43898p03.dat","43898p04.dat","44375bp02.dat","44375bp03.dat","44375bp04.dat","44375bp05.dat","44375bp06.dat","44375bp07.dat","44375bps2.dat","45677d02.dat","45677d03.dat","45677d04.dat","45677d05.dat","45677d06.dat","45677ds1.dat","45677dy0.dat","47456.dat","52031d01.dat","52031d03.dat","52031d04.dat","52031d05.dat","5306.dat","65138.dat","65468d.dat","71752.dat","72132.dat","73832.dat","74166.dat","79743.dat","89681.dat","90001c01.dat","90001c01p01.dat","90001p01.dat","92338-f2.dat","93541.dat","99206.dat","u9541.dat",   
end scope

dim as string sModel
dim shared as DATFile ptr g_pModel
dim shared as boolean bEditMode,bFileDropped

'///////////////////// free cam variables //////////////////
static shared as single g_fCameraX,g_fCameraY,g_fCameraZ
static shared as single g_fYaw = -190.0 , g_fPitch = 0.0 ' Start facing -Z (standard)
static shared as single g_fFrontX,g_fFrontY,g_fFrontZ,g_fRightX,g_fRightY,g_fRightZ
static shared as single g_fUpX=0.0 , g_fUpY=1.0 , g_fUpZ = 0.0 ' World Up

const cMovementSpeed = 2f , cLookSpeed = 4/20f , cWheelDivisor = 16
const cPI180 = atn(1)/45

function DropFilesHandler( hDrop as HANDLE ) as LRESULT
  dim as zstring*65536 zFile = any
  if DragQueryFile( hDrop , 0 , zFile , 65535 ) then
    sFile = zFile : bFileDropped = true
  end if
  DragFinish( hDrop )
  return TRUE
end function
sub UpdateCameraVectors()  
    
    dim as single fRadYaw = g_fYaw * cPI180 , fRadPitch = g_fPitch * cPI180

    ' Calculate Front Vector (D)
    g_fFrontX = cos(fRadYaw) * cos(fRadPitch)
    g_fFrontY = sin(fRadPitch)
    g_fFrontZ = sin(fRadYaw) * cos(fRadPitch)

    ' Note: You'd normally normalize Front, but since Yaw/Pitch angles are unit-sphere
    ' based, the vector is already normalized.

    ' Calculate Right Vector (R) using Cross Product (Front x World Up)
    ' Cross-product: (a2*b3 - a3*b2, a3*b1 - a1*b3, a1*b2 - a2*b1)
    ' a=Front, b=Up(0, 1, 0)
    g_fRightX = g_fFrontY * g_fUpZ - g_fFrontZ * g_fUpY  ' 0 - FrontZ * 1 = -FrontZ
    g_fRightY = g_fFrontZ * g_fUpX - g_fFrontX * g_fUpZ  ' 0 - 0 = 0
    g_fRightZ = g_fFrontX * g_fUpY - g_fFrontY * g_fUpX  ' FrontX * 1 - 0 = FrontX

    ' Normalize the Right vector (essential for consistent strafing speed)
    dim fLen as single = sqr(g_fRightX * g_fRightX + g_fRightY * g_fRightY + g_fRightZ * g_fRightZ)
    if fLen <> 0 then
        g_fRightX /= fLen
        ' RightY = 0 is fine
        g_fRightZ /= fLen
    end if
end sub

dim as boolean g_bFocus = true , g_bNeedUpdate = true , g_bLocked = false , g_bRotate = false
dim as boolean bMoveForward , bMoveBackward , bStrafeLeft , bStrafeRight , bMoveUp , bMoveDown
'///////////////////////////////////////////////////////////

dim shared as single fRotationX = 120 , fRotationY = 20 , fvRotationX , fvRotationY
dim shared as single fPositionX , fPositionY , fPositionZ , fZoom = -3
dim shared as long iWheel , iPrevWheel , g_CurDraw = -1
dim shared as byte g_Vsync=2, bBorderMode=1
dim shared as boolean bBoundingBox,bLighting=true,bCulling=true
dim shared as boolean bLeftPressed,bRightPressed,bWheelPressed
dim shared as hwnd hGfxWnd
dim shared as boolean g_FreeCam = false  
dim shared as long iOldCliWid , iOldCliHei, OldDraw = -2
dim shared as long g_iMouseX , g_iMouseY
dim shared as Matrix4x4 tCur=any, tProj=any, tMat=any
dim shared as PartSize g_tSz
dim shared as PartSnap tSnapID  

#ifdef UseVBO
  static shared as ModelDrawArrays g_tModelArrays
  static shared as GLuint iTriangleVBO=-1,iColorTriVBO=-1,iTrColTriVBO=-1,iBorderVBO=-1,iColorBrdVBO=-1,iCubemapVBO=-1
  static shared as GLuint iCubemapIdxVBO=-1, iBorderIdxVBO=-1, iTriangleIdxVBO=-1
  static shared as long g_uDrawParts , g_uDrawBoxes
#else
  static shared as long g_iModels , g_iBorders
#endif

'glDisable(GL_DITHER)

dim shared as glInt pickingFBO , pickingTexture , pickingDepthBuffer
Sub InitPickingFBO(w As Integer, h As Integer)
  
  If pickingTexture     <> 0 Then glDeleteTextures(1, @pickingTexture):pickingTexture=0
  If pickingDepthBuffer <> 0 Then glDeleteRenderbuffers(1, @pickingDepthBuffer):pickingDepthBuffer=0
  If pickingFBO         <> 0 Then glDeleteFramebuffers(1, @pickingFBO):pickingFBO=0
  
  '' 1. Create Framebuffer
  glGenFramebuffers(1, @pickingFBO)
  glBindFramebuffer(GL_FRAMEBUFFER, pickingFBO)

  '' 2. Create Texture (The color buffer)
  glGenTextures(1, @pickingTexture)
  glBindTexture(GL_TEXTURE_2D, pickingTexture)
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, w, h, 0, GL_RGB, GL_UNSIGNED_BYTE, 0)
  
  '' IMPORTANT: No filtering! We need exact pixels.
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)

  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, pickingTexture, 0)

  '' 3. Create Renderbuffer (The depth buffer)
  glGenRenderbuffers(1, @pickingDepthBuffer)
  glBindRenderbuffer(GL_RENDERBUFFER, pickingDepthBuffer)
  glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, w, h)
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, pickingDepthBuffer)

  '' 4. Verify
  If glCheckFramebufferStatus(GL_FRAMEBUFFER) <> GL_FRAMEBUFFER_COMPLETE Then
      Print "Error: Picking FBO not complete!"
  End If
  
  glBindFramebuffer(GL_FRAMEBUFFER, 0)   '' Unbind to return to normal rendering
  glBindTexture(GL_TEXTURE_2D, 0)        '' Unbind Texture
  glBindRenderbuffer(GL_RENDERBUFFER, 0) '' Unbind Renderbuffer
  
End Sub

#ifdef UseVBO
function PickPart(iMouseX as long , iMouseY as long) as long
  
  glPushAttrib(GL_ALL_ATTRIB_BITS)
  
  '' 1. Bind our off-screen FBO
  glBindFramebuffer(GL_FRAMEBUFFER, pickingFBO)
  
  '' 2. Clear it (Use White or Black as "No Object")
  glClearColor(1.0, 1.0, 1.0, 1.0) '' White = ID -1 (or max int)
  glClear(GL_COLOR_BUFFER_BIT Or GL_DEPTH_BUFFER_BIT)

  g_uDrawParts=0 : g_uDrawBoxes=0
  
  glDisable( GL_LIGHTING )  
  glEnable( GL_DEPTH_TEST ) 
  glDisable( GL_BLEND )
  
  'render whole model    
  dim as ulong uLastColor = 0
  with g_tModelArrays
    
    scope
      glEnableClientState(GL_VERTEX_ARRAY)
      'glEnableClientState(GL_NORMAL_ARRAY)
      glLoadMatrixf( @tCur.m(0) )
      glBindBuffer(GL_ARRAY_BUFFER, iCubemapVBO )
      #ifdef iCubemapIdxVBO            
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, iCubemapIdxVBO )
      #endif
      const cVtxSz = sizeof(VertexCubeMap)
      glVertexPointer(3, GL_FLOAT        , cVtxSz, cast(any ptr,offsetof(VertexCubeMap,tPos   )) )
      'glNormalPointer(   GL_FLOAT        , cVtxSz, cast(any ptr,offsetof(VertexCubeMap,tNormal)) )
    end scope
    
    var iStart = 0 , iEnd = .lPieceCount-1 , bDrawFixedColor = cbyte(0)
    var dwFixedColor = 1 'rgb(255,255,255)
    'if g_CurDraw >= 0 then iStart = g_CurDraw : iEnd = g_CurDraw
    
    #if 1
      for I as long = iStart to iEnd
        with .pPieces[I]
          if .pModel=0 then continue for
          MultMatrix4x4( .tMatView , tCur , .tMatrix )
          .bFlags=0 ': .bDisplay = 0          
        end with
      next I
      bDrawFixedColor = 1 : dwFixedColor = 1
    #else        
      for I as long = iStart to iEnd           
        with .pPieces[I]
          .bFlags=0 : '.bDisplay=0:.bSkipBorder=0:.bSkipBody=0
          if .pModel=0 then continue for
          MultMatrix4x4( .tMatView , tCur , .tMatrix )            
          dim as ulong uC = (((I shr 0) and 63) shl 2) + (((I shr 6) and 63) shl 10) + (((I shr 12) and 63) shl 18)
          glColor4ubv( cast(ubyte ptr,@uC) )
          #ifdef iCubemapIdxVBO
            glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_INT, cast(any ptr,I*36*sizeof(long)) )
          #else
            glDrawArrays( GL_TRIANGLES, I*36 , 36 )
          #endif
        end with
      next I
    #endif
    
        
    glDisableClientState(GL_NORMAL_ARRAY)
    glDisableClientState(GL_COLOR_ARRAY)
    
    if bDrawFixedColor then
      DrawPieces( Triangle , Triangle , GL_TRIANGLES , false )
      DrawPieces( ColorTri , ColorTri , GL_TRIANGLES , false )    
      DrawPieces( TransTri , TransTri , GL_TRIANGLES , false )
      DrawPieces( TrColTri , TrColTri , GL_TRIANGLES , false )
    end if
    
    glDisableClientState(GL_VERTEX_ARRAY)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
    glBindBuffer(GL_ARRAY_BUFFER, 0 )
    
  end with  
  
  var glY = gfx.g_iCliHei - iMouseY  
  dim as ulong uC 
  
  'dim as fb.image ptr pTemp = ImageCreate(gfx.g_iCliWid,gfx.g_iCliHei,-1,32)
  'pTemp->Pitch = pTemp->Width*pTemp->Bpp
  'glReadPixels( 0 , 0 , gfx.g_iCliWid , gfx.g_iCliHei , GL_RGBA, GL_UNSIGNED_BYTE, pTemp+1 )
  'bsave "click.bmp",pTemp
  'ImageDestroy(pTemp)
  
  glReadPixels(iMouseX, glY, 1, 1, GL_RGB, GL_UNSIGNED_BYTE, @uC)  
  glBindFramebuffer(GL_FRAMEBUFFER, 0)
  glPopAttrib()  
  
  if (uC and &hC0C0C0) = &hC0C0C0 then return -1
  'printf(!"%i %i (%ix%i) %i\n",iMouseX,iMouseY,gfx.g_iCliWid,gfx.g_iCliHei,uC)
  return ((uC shr 2) and 63) + (((uC shr 10) and 63) shl 6) + (((uC shr 18) and 63) shl 12)  
  
end function
sub DisplayFBO( iFBO as ulong )
  '' 1. Bind the FBO as the SOURCE
  glBindFramebuffer(GL_READ_FRAMEBUFFER, iFBO )
  '' 2. Bind the Screen (0) as the DRAW destination
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0)
  '' 3. Copy the pixels (Blit)
  '' Parameters: srcX1, srcY1, srcX2, srcY2, dstX1, dstY1, dstX2, dstY2, Mask, Filter
  var scrW = gfx.g_iCliWid , scrH = gfx.g_iCliHei
  glBlitFramebuffer(0, 0, scrW, scrH, 0, 0, scrW, scrH, GL_COLOR_BUFFER_BIT, GL_NEAREST)
  '' 4. Unbind
  glBindFramebuffer(GL_FRAMEBUFFER, 0)
end sub
#endif

sub RenderScenery()
  
  #ifdef UseVBO
  g_uDrawParts=0 : g_uDrawBoxes=0
  #endif
  
  'glDisable( GL_LIGHTING )
  glEnable( GL_DEPTH_TEST )
  
  #ifndef useVBO
    if g_CurDraw < 0 then
      glCallList(	g_iModels )
    else
      RenderModel( g_pModel , 0 , , g_CurDraw )
    end if
    if bBorderMode then
      glCallList(	g_iBorders-(g_CurDraw>=0) )
    end if
  #else    
    'render whole model    
    dim as ulong uLastColor = 0
    with g_tModelArrays
      
      scope
        glEnableClientState(GL_VERTEX_ARRAY)
        glEnableClientState(GL_NORMAL_ARRAY)
        'glColor4ub(255,255,255,255)
        glLoadMatrixf( @tCur.m(0) )
        glBindBuffer(GL_ARRAY_BUFFER, iCubemapVBO )
        #ifdef iCubemapIdxVBO            
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, iCubemapIdxVBO )
        #endif
        const cVtxSz = sizeof(VertexCubeMap)
        glVertexPointer(3, GL_FLOAT        , cVtxSz, cast(any ptr,offsetof(VertexCubeMap,tPos   )) )
        glNormalPointer(   GL_FLOAT        , cVtxSz, cast(any ptr,offsetof(VertexCubeMap,tNormal)) )
      end scope
      
      'glPushAttrib(GL_ENABLE_BIT)
      'glEnable( GL_CULL_FACE )
      
      var iStart = 0 , iEnd = .lPieceCount-1 , bDrawFixedColor = cbyte(0)
      var dwFixedColor = rgb(255,255,255)
      'if g_CurDraw >= 0 then iStart = g_CurDraw : iEnd = g_CurDraw
      
      glDisable( GL_BLEND )
      if g_CurDraw >= 0 then
        for I as long = iStart to iEnd
          with .pPieces[I]
            MultMatrix4x4( .tMatView , tCur , .tMatrix )
            .bFlags=0 : .bDisplay = 0          
          end with
        next I
        .pPieces[g_CurDraw].bDisplay=1 
      else         
        for I as long = iStart to iEnd           
          with .pPieces[I]
            .bFlags=0 : '.bDisplay=0:.bSkipBorder=0:.bSkipBody=0
            if .pModel=0 then continue for
            MultMatrix4x4( .tMatView , tCur , .tMatrix )
            'printf(!"Z = %1.1f Rad=%1.1f \r",.tMatView.fPosZ,.pModel->tSize.fRad)
            if .tMatView.fPosZ > (.pModel->tSize.fRad) then continue for            
            if .tMatView.fPosZ < -70 then                                   
              glColor4ubv( cast(ubyte ptr,@.lBaseColor) ) : g_uDrawBoxes += 1
              #ifdef iCubemapIdxVBO
                glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_INT, cast(any ptr,I*36*sizeof(long)) )
              #else
                glDrawArrays( GL_TRIANGLES, I*36 , 36 )
              #endif              
              continue for
            end if          
            if bCulling=0 then .bSkipBorder = 1
            'if .tMatView.fPosZ < -50 then .bSkipBorder=1
            .bDisplay=1 : g_uDrawParts += 1
          end with
        next I
      end if
      
      if g_CurDraw >= 0 then
        glDisable( GL_BLEND )
        iStart = g_CurDraw : iEnd = g_CurDraw
        DrawPieces( Triangle , Triangle , GL_TRIANGLES , false )
        DrawPieces( ColorTri , ColorTri , GL_TRIANGLES , true  )
        glEnable( GL_BLEND )
        if bBorderMode > 0 then           
          glDisableClientState(GL_NORMAL_ARRAY)
          #ifdef iBorderIdxVBO
            DrawPieces( Border   , Triangle , GL_LINES   , false )
          #else
            DrawPieces( Border   , Border , GL_LINES   , false )
          #endif
          DrawPieces( ColorBrd , ColorBrd , GL_LINES   , true  )
          glEnableClientState(GL_NORMAL_ARRAY)
        end if          
        DrawPieces( TransTri , TransTri , GL_TRIANGLES , false )
        DrawPieces( TrColTri , TrColTri , GL_TRIANGLES , true  )        
        bDrawFixedColor = 1 : uLastColor = 0
        iStart = 0 : iEnd = .lPieceCount-1
      end if
      
      'glPopAttrib()
      
      #if 1          
        DrawPieces( Triangle , Triangle , GL_TRIANGLES , false )
        DrawPieces( ColorTri , ColorTri , GL_TRIANGLES , true  )
        glEnable( GL_BLEND )
        if bBorderMode > 0 then           
          glDisableClientState(GL_NORMAL_ARRAY)
          #ifdef iBorderIdxVBO
            DrawPieces( Border   , Triangle , GL_LINES   , false )
          #else
            DrawPieces( Border   , Border , GL_LINES   , false )
          #endif
          DrawPieces( ColorBrd , ColorBrd , GL_LINES   , true  )
          glEnableClientState(GL_NORMAL_ARRAY)
        end if          
        DrawPieces( TransTri , TransTri , GL_TRIANGLES , false )
        DrawPieces( TrColTri , TrColTri , GL_TRIANGLES , true  )
      #endif
      
      glDisableClientState(GL_COLOR_ARRAY)
      glDisableClientState(GL_NORMAL_ARRAY)
      glDisableClientState(GL_VERTEX_ARRAY)
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
      glBindBuffer(GL_ARRAY_BUFFER, 0 )
      
    end with
    
  #endif
  
end sub
sub RenderOverlay()
  
  #ifdef UseVBO
  exit sub
  #endif  
  
  glPushAttrib(GL_ENABLE_BIT)
  glDisable( GL_CULL_FACE )
  'glDisable( GL_DEPTH_TEST )
  
  'glLoadMatrixf( @tCur.m(0) )
  
  dim as PartSnap tSnap
  #ifdef DebugShadow
    dim as PartSnap tSnap
    static as byte bOnce   
    'if bOnce=0 then
      'SnapModel( g_pModel , tSnap , 2 )
      'bOnce=1
    'else
      SnapModel( g_pModel , tSnap , true )
    'end if
  #endif      
  #if 0
    glEnable( GL_POLYGON_STIPPLE )        
    'SnapModel( g_pModel , tSnap )    
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
    #if 1
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
    with g_tSz
      DrawLimitsCube( .xMin-1,.xMax+1 , .yMin-1,.yMax+1 , .zMin-1,.zMax+1 )      
    end with
  end if      
  #if 0
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
  #endif
  glDepthMask (GL_TRUE)
  'glDisable( GL_DEPTH_TEST )
  #macro DrawConnectorName( _YOff )      
    var sText = "" & N+1
    if 1 then '.tOriMat.fScaleX then
       glPushMatrix()
       var fPX = .tPos.X , fPY = .tPos.Y , fPZ = .tPos.Z
       with .tOriMat
          dim as single fMatrix(15) = { _
             .m(0) , .m(3) , .m(6) , 0 , _ 'X scale ,    0?   ,   0?    , 0 
             .m(1) , .m(4) , .m(7) , 0 , _ '  0?    , Y Scale ,   0?    , 0 
             .m(2) , .m(5) , .m(8) , 0 , _ '  0?    ,    0?   , Z Scale , 0 
              fpX  ,  fPY  ,  fpZ  , 1  }  ' X Pos  ,  Y Pos  ,  Z Pos  , 1 
          glMultMatrixf( @fMatrix(0) )
          glTranslateF(0,_YOff,0)
       end with
       glDrawText( sText , 0,0,0 , 8/len(sText),8 , true )
       glPopMatrix()
    else         
       'glDrawText( sText , .tPos.X,.tPos.Y+(_YOff),.tPos.Z , 8/len(sText),8 , true )
    end if
  #endmacro
    
  if g_CurDraw <> -1 orelse bEditMode then      
    glPushMatrix()
    if g_CurDraw <> -1 then
       with g_pModel->tParts(g_CurDraw)._1
          dim as single fMatrix(15) = { _
             .fA , .fD , .fG , 0 , _ 'X scale ,    0?   ,   0?    , 0 
             .fB , .fE , .fH , 0 , _ '  0?    , Y Scale ,   0?    , 0 
             .fC , .fF , .fI , 0 , _ '  0?    ,    0?   , Z Scale , 0 
             .fX , .fY , .fZ , 1 }   ' X Pos  ,  Y Pos  ,  Z Pos  , 1 
          glMultMatrixf( @fMatrix(0) )
       end with
    end if
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
             DrawConnectorName(-1)
          end with
       next N
    end with
    OldDraw = g_CurDraw
    glPopMatrix()
  end if  
  
  'glClear GL_DEPTH_BUFFER_BIT                 
  #define DrawMarker( _X , _Y , _Z ) DrawLimitsCube( (_X)-2,(_X)+2 , (_Y)-2,(_Y)+2 , (_Z)-2,(_Z)+2 )
  'glColor4f(1,.5,.25,.66) : DrawMarker( 0,0,0 )
  'glColor4f(.25,.5,1,.66) : DrawMarker( -50,0,-50 )
  
  glPopAttrib()
  
  
end sub

do
  dim as double dLoadTime = timer
  g_TotalLoadFileTime = 0
  
  for N as long = g_ModelCount-1 to 0 step -1
    FreeModel( g_tModels(N).pModel )
  next N
  if g_pModel then FreeModel( g_pModel ): g_pModel=0
  
  g_sFilenames = chr(0) : g_sFilesToLoad = chr(0)
  
  #ifdef LoadFromSFile '1 = Load File , 0 = Load From clipboard
    if len(sFile)=0 then sFile=command(1)
    if instr(sFile,"\")=0 andalso instr(sFile,"/")=0 then FindFile(sFile)
    printf(!"Model: '%s'\n",sFile)
    if LoadFile( sFile , sModel ) = 0 then
       print "Failed to load '"+sFile+"'"
       sleep : system
    end if
    print sFile
    g_pModel = LoadModel( strptr(sModel) , sFile )
    var sEndsExt = lcase(right(sFile,4))      
  #else    
    if len(sFile)=0 then sModel = command(1) else sModel = sFile
    var sEndsExt = lcase(right(sModel,4)), sFilename = "Copy Paste.ldr"
    printf(!"[%s // %s]\n",sModel,sEndsExt)
    var IsFilename = (instr(sModel,chr(10))=0) andalso ((sEndsExt=".dat") orelse (sEndsExt=".ldr") orelse (sEndsExt=".mpd"))
    if IsFilename then      
       print "loading from '"+sModel+"'"
       if FileExists(sModel)=0 then FindFile(sModel)
       sFilename = sModel
       if LoadFile( sModel , sModel ) = 0 then
          print "Failed to load '"+sModel+"'"
          sleep : system
       end if   
    else
       if instr(sModel,".dat") then
          print "loading from cmdline"
          for N as long = 0 to len(sModel)
             if sModel[N]=13 then sModel[N]=32
          next N
       else
          print "loading from clipboard"
          sModel = "" 'GetClipboard() 
          if instr(sModel,".dat") then
             for N as long = 0 to len(sModel)
                if sModel[N]=13 then sModel[N]=32
             next N
          else 'if there isnt a model in the clipboard, then load this:
             sModel = _    
             "1 1 0.000000 0.000000 0.000000 1 0 0 0 1 0 0 0 1 3024.dat" EOL '60483 '39266p03.dat 
             
             'sModel = _    
             '"1 2 0.000000 0.000000 0.000000 1 0 0 0 1 0 0 0 1 NotFound.dat" EOL _
             'sModel = _
             '"1 1 -50.000000 0.000000 0.000000 1 0 0 0 1 0 0 0 1 3818.dat" EOL _ '91405
             '"1 1 50.000000 0.000000 0.000000  1 0 0 0 1 0 0 0 1 3819.dat" EOL '3818 / 3819
             
             ' ------------------------------------------------------
             'sModel = _ 'all of lines belo should end with EOL _
             '   "1 4 0 0 0 1 0 0 0 1 0 0 0 1 30068.dat"    EOL _
             '   "1 1 0 -10 0 1 0 0 0 1 0 0 0 1 18654.dat"  EOL _
             ' ------------------------------------------------------
             'sModel = _
             '   "1 0 0.000000 0.000000 0.000000 1 0 0 0 1 0 0 0 1 3958.dat"       EOL _
             '   "1 16 -50.000000 -24.000000 50.000000 1 0 0 0 1 0 0 0 1 3005.dat"
             ' ------------------------------------------------------
             'sModel = _
             '   "1 1 0.000000 0.000000 0.000000 1 0 0 0 1 0 0 0 1 47905.dat"     ' EOL _
                '"1 0 -60.000000 -24.000000 20.000000 1 0 0 0 1 0 0 0 1 3001.dat"
             ' ------------------------------------------------------
             'sModel = _
             '   "1 0 0.000000 0.000000 0.000000 1 0 0 0 -1 -8.74228e-008 0 8.74228e-008 -1 3001.dat" EOL _
             '   "1 22 -60.000000 24.000002 -19.999998 1 0 0 0 -1 -0 0 0 -1 3001.dat"
             
          end if
       end if            
    end if
    g_pModel = LoadModel( strptr(sModel) , sFilename )
    
  #endif
  
  dLoadTime = timer-dLoadTime
  printf(!"Total Load Model Time: %1.2f\n",dLoadTime)   
  printf(!"File Load Time: %1.2f\n",g_TotalLoadFileTime)
  printf(!"Processing time: %1.2f\n",dLoadTime-g_TotalLoadFileTime)
  'getchar()
  
  if sEndsExt=".dat" then bEditMode = true : puts("Edit mode?")  
  bEditMode = false
  
  if hGfxWnd=0 then
    hGfxWnd = InitOpenGL()
    if bLighting then glEnable( GL_LIGHTING ) else glDisable( GL_LIGHTING )
    if bCulling  then glEnable( GL_CULL_FACE ) else glDisable( GL_CULL_FACE )
    glEnable( GL_DEPTH_TEST )
    wglSwapIntervalEXT(g_Vsync)
  end if
  
  'glPolygonMode( GL_FRONT_AND_BACK, GL_LINE )
  dim as long g_DrawCount = g_pModel->iPartCount
  
  dLoadTIme = timer
  #ifdef UseVBO           
    
    'deallocate previous VBO/Vertex arrays if they were loaded.
    
    with g_tModelArrays
      'if iTriangleVBO then ,iColorTriVBO,iTrColTriVBO,iBorderVBO,iColorBrdVBO,iCubemapVBO
      'static shared as GLuint iCubemapIdxVBO, iBorderIdxVBO, iTriangleIdxVBO
      if .pTriangleVtx then MyDeallocVertex( .pTriangleVtx )
      if .pBorderVtx   then MyDeallocVertex( .pBorderVtx   )
      if .pColorTriVtx then MyDeallocVertex( .pColorTriVtx )
      if .pTrColTriVtx then MyDeallocVertex( .pTrColTriVtx )
      if .pColorBrdVtx then MyDeallocVertex( .pColorBrdVtx )
      if .pCubemapVtx  then MyDeallocVertex( .pCubemapVtx  )
      if .pCubeMapIdx  then MyDeallocIndex ( .pCubeMapIdx  )
      if .pTriangleIdx then MyDeallocIndex ( .pTriangleIdx )
      if .pBorderIdx   then MyDeallocIndex ( .pBorderIdx   )
      if .pPieces      then MyDeallocIndex ( .pPieces      )
    end with
    clear g_tModelArrays,,sizeof(g_tModelArrays)    
    GenModelDrawArrays( g_pModel , g_tModelArrays )
    #if 0
      with g_tModelArrays
        printf(!"My Pieces %i\n",.lPieceCount)
        for I as long = 0 to .lPieceCount-1
          with .pPieces[I]
            var p = @.tMatrix
            printf(!"#%i - %p %3i,%3i,%3i '%s'\n", _ 
            I,.pModel,cint(p->fPosX),cint(p->fPosY),cint(p->fPosZ),GetPartName(.pModel))
          end with
        next I
      end with
    #endif
    #macro CreateVBO( _name )      
      with g_tModelArrays
        if .l##_name##Cnt andalso clng(i##_name##VBO)=-1 then glGenBuffers(1 , @i##_name##VBO)
        #ifdef i##_name##IdxVBO
        if clng(i##_name##IdxVBO)=-1 then glGenBuffers(1 , @i##_name##IdxVBO)
        #endif
        if .p##_name##vtx andalso .l##_name##Cnt then
          #define vtxSz (.l##_name##Cnt * sizeof(typeof(*.p##_name##vtx)))
          #define idxSz (.l##_name##IdxCnt * sizeof(typeof(*.p##_name##Idx)))
          glBindBuffer(GL_ARRAY_BUFFER, i##_name##VBO)
          glBufferData(GL_ARRAY_BUFFER, vtxSz , .p##_name##vtx , GL_STATIC_DRAW)
          #ifdef i##_name##IdxVBO
          glBindBuffer(GL_ARRAY_BUFFER, i##_name##IdxVBO)
          glBufferData(GL_ARRAY_BUFFER, idxSz , .p##_name##Idx , GL_STATIC_DRAW)
          printf(!"%s = %1.1fmb (idx=%1.1fkb)\n" , #_name , (vtxSz+idxSz)/(1024*1024) , (idxSz)/(1024) )
          #else
          printf(!"%s = %1.1fmb\n" , #_name , (vtxSz)/(1024*1024) )
          #endif
          MyDeallocVertex( .p##_name##vtx ) : .p##_name##vtx = NULL
          #ifdef i##_name##IdxVBO
          MyDeallocIndex( .p##_name##Idx ) : .p##_name##Idx = NULL
          #endif
        else          
          #ifdef i##_name##IdxVBO            
            if .l##_name##IdxCnt then
              #define vtxSz (.l##_name##Cnt * sizeof(typeof(*.p##_name##vtx)))
              #define idxSz (.l##_name##IdxCnt * sizeof(typeof(*.p##_name##Idx)))
              glBindBuffer(GL_ARRAY_BUFFER, i##_name##IdxVBO)
              glBufferData(GL_ARRAY_BUFFER, idxSz , .p##_name##Idx , GL_STATIC_DRAW)
              printf(!"%s = %1.1fmb (idx=%1.1fkb)\n" , #_name , (vtxSz+idxSz)/(1024*1024) , (idxSz)/(1024) )          
            end if
          #endif
        end if
      end with
    #endmacro
    #ifdef iBorderIdxVBO
    GenerateOptimizedIndexes( g_tModelArrays , Triangle , Border )
    #else
    GenerateOptimizedIndexes( g_tModelArrays , Triangle )
    #endif
    CreateVBO( Triangle )
    CreateVBO( ColorTri )
    CreateVBO( TrColTri )
    'GenerateOptimizedIndexes( g_tModelArrays , Border )
    CreateVBO( Border   )    
    CreateVBO( ColorBrd )
  #else
    scope
      const bBorders=32
      g_iModels  = glGenLists( 1 )
      g_iBorders = glGenLists( 2 )
      glNewList( g_iModels ,  GL_COMPILE ) 'GL_COMPILE_AND_EXECUTE
      RenderModel( g_pModel , 0 )
      glEndList()   
      glNewList( g_iBorders ,  GL_COMPILE )
      RenderModel( g_pModel , bBorders )
      glEndList()
      glNewList( g_iBorders+1 ,  GL_COMPILE )
      RenderModel( g_pModel , bBorders , , -2 )
      glEndList()
    end scope
  #endif   
  
  'getchar()
  
  dim as single xMid,yMid,zMid,g_zFar  
  dim as long g_PartCount = -1 , g_CurPart = -1
  
  clear g_tSz ,, sizeof(g_tSz)
  SizeModel( g_pModel , g_tSz , , g_PartCount )
  
  with g_tSz
    xMid = (.xMin+.xMax)*.5
    yMid = (.yMin+.yMax)*.5
    zMid = (.zMin+.zMax)*.5
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
    
    #if 0
      glLoadIdentity()   
      'glScalef(1/-20, 1.0/-20, 1/20 )
      dim as GLdouble model(16-1), proj(16-1)
      dim as GLint viewport(4-1)    
      glGetDoublev(GL_MODELVIEW_MATRIX, @model(0))
      glGetDoublev(GL_PROJECTION_MATRIX, @proj(0))
      glGetIntegerv(GL_VIEWPORT, @viewport(0))    
      '/* Step 2: project this point to screen */
      dim as GLdouble sx, sy, sz
      gluProject( xMid, yMid, zMid, @model(0), @proj(0), @viewport(0), @sx, @sy, @sz)
      '/* Step 3: pick desired screen position (center of viewport) */
      var targetX = viewport(0) + viewport(2)*0.5 , targetY = viewport(1) + viewport(3)*0.5
      '/* Step 4: unproject the desired screen center at same depth */
      dim as GLdouble worldX, worldY, worldZ
      gluUnProject(targetX, targetY, sz, @model(0), @proj(0), @viewport(0), @worldX, @worldY, @worldZ)
      '/* Step 5: compute world translation needed */
      fPositionX = worldX-xMid
      fPositionY = worldY-yMid
      fPositionZ = ((worldZ/20)^2)*-2 ''-2000 '(worldZ-zMid)*20
      'printf(!"{%5f %5f %5f}\n",xMid,yMid,zMid)
      'printf(!"{%5f %5f %5f}\n",worldX,worldY,worldZ)
      'printf(!"{%5f %5f %5f}\n",fPositionX,fPositionY,fPositionZ)
    #endif
    
  end with

  redim as PartCollisionBox atCollision()
  #ifndef UseVBO
  CheckCollisionModel( g_pModel , atCollision() )
  #endif  
  printf(!"Parts: %i , Collisions: %i \n",g_PartCount,ubound(atCollision)\2)
  
  'Get size of each piece (CheckCollisionModel is doing it right)
  'TODO: check what's wrong with SizeModel()
  '#define GenerateCubesWithIndexes 'broken :(
    
  #ifdef UseVBO
    with g_tModelArrays
      dim as long lUnique        
      .pCubemapIdx = MyAllocIndex( .lCubemapCnt*sizeof(long) )
      var pCubeVtx = .pCubemapVtx , lCount = .lPieceCount
      #ifdef GenerateCubesWithIndexes
      var pCubeIdx = .pCubemapIdx , lCubeIdx = -36 , lCubeVtx = -8      
      #endif      
      for I as long = 0 to .lPieceCount-1
        #ifdef GenerateCubesWithIndexes
        lCubeVtx+=8 : lCubeIdx += 36
        #endif
        with .pPieces[I]                
          if .pModel = 0 then continue for
          if isBadReadPtr(.pModel,offsetof(DATFile,tParts(0))) then 
            puts(I & " BAD?") : .pModel = 0 : continue for
          end if        
          if .pModel->bHasSize=0 then
            #if 0
              with .pModel->tSize
                printf(!"%5i: xMin=%1.1f , yMin=%1.1f , zMin=%1.1f , xMax=%1.1f , yMax=%1.1f , zMax=%1.1f\n" , _
                lUnique , .xMin , .yMin , .zMin , .xMax , .yMax , .zMax )
              end with
            #endif
            .pModel->bHasSize=1 : SizeModel( .pModel , .pModel->tSize )
            
            with .pModel->tSize            
              .fRad = 0
              if abs(.xMin) > .fRad then .fRad = abs(.xMin)
              if abs(.yMin) > .fRad then .fRad = abs(.yMin)
              if abs(.zMin) > .fRad then .fRad = abs(.zMin)
              if abs(.xMax) > .fRad then .fRad = abs(.xMax)
              if abs(.yMax) > .fRad then .fRad = abs(.yMax)
              if abs(.xMax) > .fRad then .fRad = abs(.zMax)
              .fRad /= 19
              'printf(!"%5i: fRad=%1.1f xMin=%1.1f , yMin=%1.1f , zMin=%1.1f , xMax=%1.1f , yMax=%1.1f , zMax=%1.1f\n" , _
              'lUnique , .fRad , .xMin , .yMin , .zMin , .xMax , .yMax , .zMax )
            end with
            lUnique += 1
          end if
          
          #ifdef GenerateCubesWithIndexes
          var pVtxBase = pCubeVtx+lCubeVtx
          #else
          var pVtxBase = pCubeVtx+I*36
          #endif
          'printf(!"%i of %i > %p\n",I,lCount-1,pVtxBase)
          
          #ifdef GenerateCubesWithIndexes
            GenCubeVtxIdx8( pVtxBase , lCubeVtx , pCubeIdx , lCubeidx , .pModel->tSize )
            dim as Matrix3x3 tNormalMatrix = any 
            BuildNormalMatrix( .tMatrix , tNormalMatrix )
            for N as long = 0 to 7
              MultiplyMatrixVector( @pVtxBase[N].tPos.fX , @.tMatrix )
              TransformNormal( pVtxBase[N].tNormal , tNormalMatrix )
            next N
          #else
            GenCubeVtx36( pVtxBase , .pModel->tSize )
            for N as long = 0 to 35
              MultiplyMatrixVector( @pVtxBase[N].tPos.fX , @.tMatrix )              
            next N
            for N as long = 0 to 35 step 3
              SetVtxTrigNormal( pVtxBase+N )
            next N
          #endif          
          
        end with
      next I      
      #ifdef GenerateCubesWithIndexes
      .lCubemapCnt = lCubeVtx : .lCubeMapIdxCnt = lCubeidx
      .pCubemapVtx = MyReallocVertex( .pCubemapVtx , .lCubemapCnt*sizeof( VertexCubeMap ) )
      #endif      
    end with
    #ifndef GenerateCubesWithIndexes
      GenerateOptimizedIndexes( g_tModelArrays , Cubemap )
    #endif
    CreateVBO( Cubemap  )
  #endif
  
  puts("Load Time: " & timer-dLoadTIme)
  if g_PartCount = 0 then g_PartCount = 1
  
  #ifdef DebugShadowConnectors
  scope           
     dim as PartSnap tSnap
     for I as long = 0 to g_PartCount-1
        if g_pModel->tParts(I).bType <> 1 then continue for
        puts("=========== Part " & I & " ===========")
        var pSubPart = g_tModels( g_pModel->tParts(I)._1.lModelIndex ).pModel                  
        SnapModel( pSubPart , tSnap )
        with tSnap
           printf(!"Studs=%i Clutchs=%i Axles=%i Axlehs=%i Bars=%i Barhs=%i Pins=%i Pinhs=%i\n", _            
           .lStudCnt , .lClutchCnt , .lAxleCnt , .lAxleHoleCnt ,.lBarCnt , .lBarHoleCnt , .lPinCnt , .lPinHoleCnt )
           SortSnap( tSnap )
           puts("---------- stud ----------")
           for N as long = 0 to .lStudCnt-1
              with .pStud[N].tPos
                 printf(!"#%i %g %g %g\n",N+1,.x,.y,.z)
              end with
           next N
           puts("--------- clutch ---------")
           for N as long = 0 to .lClutchCnt-1
              with .pClutch[N].tPos
                 printf(!"#%i %g %g %g\n",N+1,.x,.y,.z)
              end with
           next N
        end with
     next I
     'while len(inkey)=0: flip : wend
  end scope
  #endif

  'DrawLimitsCube( .xMin-1,.xMax+1 , .yMin-1,.yMax+1 , .zMin-1,.zMax+1 )
  with g_tSz   
    
    'puts(".xMin=" & .xMin & " .xMax=" & .xMax)
    'puts(".yMin=" & .yMin & " .yMax=" & .yMax)
    'puts(".zMin=" & .zMin & " .zMax=" & .zMax)
    
    fPositionX = (.xMax+.xMin)/-2 '-.xMin
    fPositionY = (.yMax+.yMin)/-2 '.yMax*20
    'printf(!"\nzmin=%f zmax=%f\n",.zMin,.zMax)
    
    'fPositionZ = (.zMax-.zMin) 
    'if (.xMax-.xMin) > fPositionZ then fPositionZ = (.xMax-.xMin)
    'if (.yMax-.yMin) > fPositionZ then fPositionZ = (.yMax-.yMin)
    
    fPositionZ = abs(.zMin) 
    if abs(.xMin) > fPositionZ then fPositionZ = abs(.xMin)
    if abs(.xMax) > fPositionZ then fPositionZ = abs(.xMax)
    if abs(.yMin) > fPositionZ then fPositionZ = abs(.yMin)    
    if abs(.yMax) > fPositionZ then fPositionZ = abs(.yMax)
    if abs(.zMax) > fPositionZ then fPositionZ = abs(.zMax)    
    
    'fPositionZ = -g_zFar
    fPositionZ = fPositionZ*-2
    
    ''(.zMax-.zMin) 'abs(.zMax)-abs(.zMin)
    'fPositionZ = abs(iif(abs(.zMin)>abs(.zMax),.zMin,.zMax))
    'fPositionZ = sqr(fPositionZ)*-40
    'fPositionZ = -.zMax
    
  end with
  
  glFinish() : flip
    
  dim as double dFrameCPU , dAccCPU , dSpeed = 1
  dim as double dFrameGL  , dAccGL
  dim iFPS as long , dFPS as double = timer
  g_bNeedUpdate = true
  
  #ifdef UseVBO 
    bBorderMode = iif(g_tModelArrays.lPieceCount <= 2000,1,-1)
  #endif  
  glPolygonMode( GL_BACK , iif(bBorderMode<0,GL_LINE,GL_FILL) )
  if bBorderMode < 0 then glDisable( GL_CULL_FACE )
  
  do
    dFrameGL = timer
    
    'resize if window size change   
    if IsIconic( hGfxWnd )=0 then
      dim as RECT tRc : GetClientRect(hGfxWnd,@tRc)
      var iCliWid = tRc.right , iCliHei = tRc.bottom      
      if iCliWid < 64 then iCliWid = 64
      if iCliHei < 48 then iCliHei = 48
      if iOldCliWid <> iCliWid orelse iOldCliHei <> iCliHei then          
        iOldCliWid = iCliWid : iOldCliHei = iCliHei         
        ResizeOpengGL( iCliWid, iCliHei )         
        InitPickingFBO( iCliWid , iCliHei )
      end if
    end if
    
    dFrameCPU = timer
    
    glClear GL_COLOR_BUFFER_BIT OR GL_DEPTH_BUFFER_BIT
    glLoadIdentity()
    tCur = g_tIdentityMatrix
    
    Matrix4x4Scale( tCur , -1/20 , -1/20 , 1/20 )
    #ifndef UseVBO
      glScalef(-1/20, -1/20, 1/20 )      
    #endif
    
    
    #macro ControlKeys()
      select case e.ascii
      case 13                'Toggle mode
        g_FreeCam = not g_FreeCam
        if g_FreeCam then
          if g_bLocked then setmouse ,,,false
        else
          setmouse ,,,g_bLocked
          dim as long lDummy=any : GetMouseDelta(lDummy,lDummy)
        end if
      case asc("B")-asc("@") 'Border Toggle
        bBorderMode = ((bBorderMode+2) mod 3)-1
        static as zstring ptr pzBorder(-1 to 1) = {@"GENERATED",@"DISABLED",@"ENABLED"}        
        glPolygonMode( GL_BACK , iif(bBorderMode<0,GL_LINE,GL_FILL) )
        if bBorderMode < 0 then
          glDisable( GL_CULL_FACE )
        else
          if bCulling then glEnable( GL_CULL_FACE ) else glDisable( GL_CULL_FACE )
        end if        
        printf(!"Borders: %s\n",pzBorder(bBorderMode))
      case asc("C")-asc("@") 'Cull Toggle
        bCulling = (0=bCulling)
        printf(!"Culling: %s\n",iif(bCulling,"ENABLED","DISABLED"))
        if bBorderMode < 0 then
          puts("Changing culling wont have an effect while border is in 'GENERATED' mode")
        else
          if bCulling then glEnable( GL_CULL_FACE ) else glDisable( GL_CULL_FACE )
        end if
      case asc("L")-asc("@") 'Light Toggle
        bLighting = not bLighting
        printf(!"Lighting: %s\n",iif(bLighting,"ENABLED","DISABLED"))
        if bLighting then glEnable(GL_LIGHTING) else glDIsable(GL_LIGHTING)
      case asc("V")-asc("@") 'Vsync Toggle
        g_Vsync = ((g_Vsync+1) mod 3)
        printf(!"Vsync Frames = %i\n",g_VSync)
        wglSwapIntervalEXT(g_Vsync)             
      end select
      select case e.scancode
      case fb.SC_F5     : exit do 'reload
      end select
    #endmacro
    #macro _ButtonPress()
      #ifdef UseVBO
        'printf(!"Clicked on part: %i\n",PickPart(g_iMouseX,g_iMouseX))
        if e.button = fb.BUTTON_LEFT then
          g_CurDraw = PickPart(g_iMouseX,g_iMouseY)        
          do
            dim as long MX,MY,MB : getmouse MX,MY,,MB          
            if (MB and 2)=0 then exit do
            DisplayFBO( pickingFBO ) : flip
          loop
        end if
      #endif
    #endmacro
    
    if g_FreeCam then
      
      #if 0 'garbage
        ' --- 1. SETUP ---
        ' We control the TARGET, not the camera directly.
        static As Single fTargetX = 0.0f, fTargetY = 0.0f, fTargetZ = 0.0f
        static As Single fDist = 1.0f   ' The "Pivot" distance you liked
        'static As Single fYaw = 0.0f, fPitch = 0.0f
        #define fYaw (g_fYaw)
        #define fPitch (g_fPitch)
      
        ' Movement Speed
        Const MOVE_SPEED As Single = 10.0f
        ' --- 2. INPUT & UPDATE LOOP ---

        ' A. Calculate the Direction Vectors based on current Yaw
        '    (We need these to know which way is "Forward" for the WASD keys)
        Dim As Single radYaw = fYaw * 0.0174533f ' Deg to Rad
        Dim As Single camFwdX = Sin(radYaw)
        Dim As Single camFwdZ = Cos(radYaw)
        Dim As Single camRightX = Cos(radYaw) ' 90 deg offset for strafing
        Dim As Single camRightZ = -Sin(radYaw)
        
        ' B. Move the TARGET (The pivot point)
        '    Note: We move the pivot, so the camera follows it naturally.
        If MultiKey(fb.SC_W) Then 
            fTargetX += camFwdX * MOVE_SPEED
            fTargetZ += camFwdZ * MOVE_SPEED
        End If
        If MultiKey(fb.SC_S) Then 
            fTargetX -= camFwdX * MOVE_SPEED
            fTargetZ -= camFwdZ * MOVE_SPEED
        End If
        If MultiKey(fb.SC_A) Then 
            fTargetX -= camRightX * MOVE_SPEED
            fTargetZ -= camRightZ * MOVE_SPEED
        End If
        If MultiKey(fb.SC_D) Then 
            fTargetX += camRightX * MOVE_SPEED
            fTargetZ += camRightZ * MOVE_SPEED
        End If
        
        ' Optional: Vertical movement for the target (Space/C)
        If MultiKey(fb.SC_SPACE) Then fTargetY += MOVE_SPEED
        If MultiKey(fb.SC_LSHIFT) Then fTargetY -= MOVE_SPEED
        
        ' C. Calculate Camera Position (Orbit Logic)
        '    Camera is placed 'fDist' units BEHIND the target
        Dim As Single radPitch = fPitch * 0.0174533f
        
        ' Calculate offset from target
        Dim As Single offsetX = Sin(radYaw) * Cos(radPitch) * fDist
        Dim As Single offsetY = Sin(radPitch) * fDist
        Dim As Single offsetZ = Cos(radYaw) * Cos(radPitch) * fDist
        
        ' Set final Camera Eye position
        g_fCameraX = fTargetX - offsetX
        g_fCameraY = fTargetY - offsetY
        g_fCameraZ = fTargetZ - offsetZ
        
        ' --- 3. RENDER ---
        Matrix4x4LookAt( tCur, _
            g_fCameraX, g_fCameraY, g_fCameraZ, _  ' Camera (Eye)
            fTargetX,   fTargetY,   fTargetZ,   _  ' Target (LookAt)
            0.0f,       1.0f,       0.0f        _  ' Up Vector
        )
      #endif      
      #if 1 'original
        if g_bNeedUpdate then g_bNeedUpdate=false : UpdateCameraVectors()   
        dim as single fTargetX=g_fCameraX+g_fFrontX , fTargetY=g_fCameraY+g_fFrontY , fTargetZ=g_fCameraZ+g_fFrontZ
        
        'dim as GLfloat lightPos(...) = {g_fCameraX,g_fCameraY,g_fCameraZ, 1.0f}'; // (x, y, z, w), w=1 for positional light
        dim as GLfloat lightPos(...) = {0,0,0, 1.0f}
        glLightfv(GL_LIGHT0, GL_POSITION, @lightPos(0))
        
        ' gluLookAt(eyeX, eyeY, eyeZ, centerX, centerY, centerZ, upX, upY, upZ)
        Matrix4x4LookAt( tCur , _
          g_fCameraX, g_fCameraY, g_fCameraZ, _  ' Camera Position (P)
          fTargetX  , fTargetY  , fTargetZ  , _  ' Look Target (P + D)
          g_fUpX    , g_fUpY    , g_fUpZ      _  ' World Up Vector
        )
      #endif
      #if 0 'close but no camera
        if g_bNeedUpdate then g_bNeedUpdate=false : UpdateCameraVectors()   
        ' Configuration
        Dim As Single fDist = 500.0f      ' Distance to the pivot point (depth)
        'Dim As Single fYaw = 0.0f, fPitch = 0.0f
        #define fYaw (g_fYaw/10)
        #define fPitch (g_fPitch/10)
        Dim As Single fTargetX = 0.0f, fTargetY = 0.0f, fTargetZ = 0.0f
        '#define fTargetX g_fCameraX
        '#define fTargetY g_fCameraY
        '#define fTargetZ g_fCameraZ
        
        ' --- Inside update loop ---
        
        ' 1. Calculate Camera position based on the Pivot Point
        var fCameraX = fTargetX - fDist * Cos(fPitch) * Sin(fYaw) 
        var fCameraY = fTargetY - fDist * Sin(fPitch)             
        var fCameraZ = fTargetZ - fDist * Cos(fPitch) * Cos(fYaw) 
        
        ' 2. Apply to your Matrix
        ' Note: Eye is now calculated, Target is the fixed pivot
        Matrix4x4LookAt( tCur , _
            fCameraX, fCameraY, fCameraZ, _  
            fTargetX  , fTargetY  , fTargetZ  , _  
            0.0f      , 1.0f      , 0.0f        _  
        )
      #endif      
      
      #ifndef UseVBO
      glLoadMatrixf( @tCur.m(0) )
      #endif
      
      Matrix4x4Translate( tCur , 0 , 0 , 0 )
      Matrix4x4RotateZ( tCur , tCur , fvRotationY*-cPI180 )
      Matrix4x4RotateY( tCur , tCur , fvRotationX*-cPI180 )
      Matrix4x4Translate( tCur , 0 , 0 , 0 )
      
      glPushMatrix()
      RenderScenery()
      glPopMatrix()
      RenderOverlay()      
      
      Dim e as fb.EVENT = any
      dim as boolean bSkipMouse = not g_bFocus
      
      #if 1
        #define fSpd (cMovementSpeed*dSpeed)
        'printf(!"%1.2f\r",dSpeed)
        if bMoveForward  then g_fCameraX += g_fFrontX*fSpd : g_fCameraY += g_fFrontY*fSpd : g_fCameraZ += g_fFrontZ*fSpd   
        if bMoveBackward then g_fCameraX -= g_fFrontX*fSpd : g_fCameraY -= g_fFrontY*fSpd : g_fCameraZ -= g_fFrontZ*fSpd   
        if bStrafeLeft   then g_fCameraX += g_fRightX*fSpd : g_fCameraZ += g_fRightZ*fSpd
        if bStrafeRight  then g_fCameraX -= g_fRightX*fSpd : g_fCameraZ -= g_fRightZ*fSpd
        if bMoveUp       then g_fCameraY -= fSpd
        if bMoveDown     then g_fCameraY += fSpd
      #endif
      
      if multikey(fb.SC_J) then fvRotationX -= fSpd
      if multikey(fb.SC_L) then fvRotationX += fSpd
      if multikey(fb.SC_I) then fvRotationY -= fSpd
      if multikey(fb.SC_K) then fvRotationY += fSpd
       
      if g_bLocked then
        dim as long lDX=any,lDY=any : GetMouseDelta( lDX, lDY )
        if bSkipMouse=false andalso (lDX or lDY)<>0 then
           'puts(lDX & "," & lDY)
           'setmouse( (iOldCliWid\2) , (iOldCliHei\2) )
           'setmouse ,,,true
           g_fYaw   += lDX * -cLookSpeed
           g_fPitch -= lDY * -cLookSpeed ' Assuming inverted Y-axis
           if g_fPitch >  45.0 then g_fPitch =  45.0
           if g_fPitch < -45.0 then g_fPitch = -45.0
           g_bNeedUpdate = true      
        end if
      end if

      while (ScreenEvent(@e))
        Select Case e.type         
        case fb.EVENT_MOUSE_MOVE
          g_iMouseX = e.x : g_iMouseX = e.y
        case fb.EVENT_MOUSE_BUTTON_PRESS
           dim as long lDX=any,lDY=any : GetMouseDelta( lDX, lDY )            
           g_bLocked = true : setmouse ,,,g_bLocked
           _ButtonPress()
        case fb.EVENT_MOUSE_BUTTON_RELEASE
           g_bLocked = false : setmouse ,,,g_bLocked
        case fb.EVENT_KEY_PRESS
           
           ControlKeys()
           
           select case e.ascii
           case 8: g_fCameraX = 0 : g_fCameraY = 0 : g_fCameraZ = 0
           'case 8: if g_bLocked then g_bLocked = false : setmouse ,,,g_bLocked
           end select
           select case e.scancode         
           case fb.SC_W      : bMoveForward  = true
           case fb.SC_S      : bMoveBackward = true
           case fb.SC_A      : bStrafeLeft   = true
           case fb.SC_D      : bStrafeRight  = true
           case fb.SC_SPACE  : bMoveUp       = true
           case fb.SC_LSHIFT : bMoveDown     = true
           end select
        case fb.EVENT_KEY_RELEASE
           select case e.scancode
           case fb.SC_W      : bMoveForward  = false
           case fb.SC_S      : bMoveBackward = false
           case fb.SC_A      : bStrafeLeft   = false
           case fb.SC_D      : bStrafeRight  = false
           case fb.SC_SPACE  : bMoveUp       = false
           case fb.SC_LSHIFT : bMoveDown     = false
           end select      
        case fb.EVENT_WINDOW_GOT_FOCUS
           g_bFocus = true : bSkipMouse = 1
           if g_bLocked then setmouse ,,,g_bLocked
        case fb.EVENT_WINDOW_LOST_FOCUS
           if g_bLocked then setmouse ,,,false
           g_bFocus = false : bSkipMouse = 1
        case fb.EVENT_WINDOW_CLOSE
           exit do,do
        end select
      wend
       
    else
      
      #ifndef UseVBO
      if g_CurDraw <> -1 then
        if OldDraw <> g_CurDraw then
          var pSubPart = g_tModels( g_pModel->tParts(g_CurDraw)._1.lModelIndex ).pModel
          SnapModel( pSubPart , tSnapID )
          SortSnap( tSnapID )
        end if
      elseif bEditMode then
        if OldDraw <> g_CurDraw then
          SnapModel( g_pModel , tSnapID )
          SortSnap( tSnapID )
        end if
      end if      
      #endif
      
      '// Set light position (0, 0, 0)
      dim as GLfloat lightPos(...) = {0,0,0, 1f}'; // (x, y, z, w), w=1 for positional light
      glLightfv(GL_LIGHT0, GL_POSITION, @lightPos(0))
      
      #ifdef UseVBO
        Matrix4x4Translate( tCur , -fPositionX , fPositionY , fPositionZ*(fZoom+4) )        
        Matrix4x4RotateX( tCur , tCur , fRotationY*-cPI180 )
        Matrix4x4RotateY( tCur , tCur , fRotationX*-cPI180 )        
      #else
        glTranslatef( -fPositionX , fPositionY , fPositionZ*(fZoom+4) ) '*(fZoom+4) ) '80*fZoom ) '/-5)
        ''glTranslatef( 0 , 0 , -80*(fZoom+4) )
        glRotatef fRotationX , 0   , -1.0 , 0
        glRotatef fRotationY , 1.0 , 0.0 , 0
      #endif      
      
      RenderScenery()      
      RenderOverlay()
      
      dim e as fb.EVENT = any
      while (ScreenEvent(@e))
        Select Case e.type
        Case fb.EVENT_MOUSE_MOVE                   
          g_iMouseX = e.x : g_iMouseY = e.y          
           var fX = iif( fZoom<0 , e.dx/((fZoom*fZoom)+1) , e.dx*((fZoom*fzoom)+1) )
           var fY = iif( fZoom<0 , e.dy/((fZoom*fZoom)+1) , e.dy*((fZoom*fZoom)+1) )
           if bLeftPressed  then fRotationX += e.dx*2/sqr(g_zFar) : fRotationY += e.dy*2/sqr(g_zFar)
           if bRightPressed then fPositionX += (fX) * g_zFar/100 : fPositionY += (fY) * g_zFar/100
        case fb.EVENT_MOUSE_WHEEL
           iWheel = e.z-iPrevWheel
           fZoom = -3+(-iWheel/cWheelDivisor)
           'puts("" & fZoom)
        case fb.EVENT_MOUSE_BUTTON_PRESS
           if e.button = fb.BUTTON_MIDDLE then 
              iPrevWheel = iWheel
              fZoom = -3
           end if
           if e.button = fb.BUTTON_LEFT   then bLeftPressed  = true
           if e.button = fb.BUTTON_RIGHT  then bRightPressed = true
           _ButtonPress()
        case fb.EVENT_MOUSE_BUTTON_RELEASE
           if e.button = fb.BUTTON_LEFT   then bLeftPressed  = false
           if e.button = fb.BUTTON_RIGHT  then bRightPressed = false      
        case fb.EVENT_KEY_PRESS
           
           ControlKeys()
           
           select case e.ascii
           case 8
            if bBoundingBox then
               g_CurPart = -1
               printf(!"g_CurPart = %i    \r",g_CurPart)
               dim as PartSize tSzTemp
               SizeModel( g_pModel , tSzTemp , g_CurPart )
               g_tSz = tSzTemp
            else
               g_CurDraw = -1
               printf(!"g_CurDraw = %i    \r",g_CurDraw)
            end if
           case asc("="),asc("+")
              if bBoundingBox then
                 g_CurPart = ((g_CurPart+2) mod (g_PartCount+1))-1
                 printf(!"g_CurPart = %i    \r",g_CurPart)
                 dim as PartSize tSzTemp
                 SizeModel( g_pModel , tSzTemp , g_CurPart )
                 g_tSz = tSzTemp
              else
                 var iOrg = g_CurDraw
                 do
                    g_CurDraw = ((g_CurDraw+2) mod (g_DrawCount+1))-1
                    if g_CurDraw=-1 orelse g_pModel->tParts(g_CurDraw).bType = 1 orelse g_CurDraw = iOrg then exit do
                 loop
                 printf(!"g_CurDraw = %i    \r",g_CurDraw)
              end if
           case asc("-"),asc("_")
              if bBoundingBox then
                 g_CurPart = ((g_CurPart+g_PartCount+1) mod (g_PartCount+1))-1
                 printf(!"g_CurPart = %i    \r",g_CurPart)
                 dim as PartSize tSzTemp
                 SizeModel( g_pModel , tSzTemp , g_CurPart )
                 g_tSz = tSzTemp
              else
                 var iOrg = g_CurDraw
                 do
                    g_CurDraw = ((g_CurDraw+g_DrawCount+1) mod (g_DrawCount+1))-1
                    if g_CurDraw=-1 orelse g_pModel->tParts(g_CurDraw).bType = 1 orelse g_CurDraw = iOrg then exit do
                 loop
                 printf(!"g_CurDraw = %i    \r",g_CurDraw)
              end if               
           end select
           
           select case e.scancode           
           case fb.SC_TAB: bBoundingBox = not bBoundingBox
           end select
           
        case fb.EVENT_WINDOW_GOT_FOCUS
         g_bFocus = true
        case fb.EVENT_WINDOW_LOST_FOCUS
         g_bFocus = false
        case fb.EVENT_WINDOW_CLOSE
           exit do,do
        end select
      wend      
      
    end if
    
    dFrameCPU = timer-dFrameCPU      
    
    glFinish() : flip
    static as integer iOnce  
    
    'glGetFloatv(GL_MODELVIEW_MATRIX , @tCur.m(0))
    'end if
    'glGetFloatv(GL_PROJECTION_MATRIX , @tProj.m(0)) 'GL_TEXTURE_CUBE_MAP
    
    dSpeed = (timer-dFrameGL)        
    dAccCPU += dFrameCPU : dAccGL += dSpeed
    dSpeed *= 60
    
    var dElapsed = (timer-dFps) : iFps += 1
    if abs(dElapsed)>=.25 then
      dFps = timer : dAccCPU = dAccCPU*100/dElapsed : dAccGL  = dElapsed/(dAccGL/(iFPS/dElapsed))
      #ifdef UseVBO
        WindowTitle( _
          "P:" & g_uDrawParts & " B:" & g_uDrawBoxes & " H:" & _
          g_tModelArrays.lPieceCount-(g_uDrawParts+g_uDrawBoxes) & " of " & _
          g_tModelArrays.lPieceCount & _
          " - Fps: " & cint(dAccGL) & "/" & cint(iFps/dElapsed) & _
          " (" & cint(dAccCPU) & "% CPU)")
      #else
        WindowTitle( _          
          " Fps: " & cint(dAccGL) & "/" & cint(iFps/dElapsed) & _
          " (" & cint(dAccCPU) & "% CPU)")
      #endif
      iFps=0 : dAccCPU=0 : dAccGL=0
    else
      'if g_Vsync=0 then SleepEx(1,1)
      if g_bFocus=0 then SleepEx(100,1)
    end if
    
    if bFileDropped then 
      bFileDropped=false 
      fRotationX = 120 : fRotationY = 20
      fPositionX = 0 : fPositionY = 0 : fPositionZ = 0 : fZoom = -3
      exit do
    end if
    
    if multikey(fb.SC_ESCAPE) then exit do,do
  loop
loop



