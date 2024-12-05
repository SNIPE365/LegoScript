#define __Main
'#define __Tester
'#define DebugShadow
'#define ColorizePrimatives

'#ifndef __NoRender

#include "LoadLDR.bas"

#include "Include\Colours.bas"
#include "Modules\Clipboard.bas"

#include "Modules\InitGL.bas"
#include "Modules\Math3D.bas"
#include "Modules\Normals.bas"
#include "Modules\Matrix.bas"
#include "Modules\Model.bas"

' TODO make the GUI window so that it can be part of LS in GUI/CLI mode but also part of the lego game.

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

'pinhole
'{SNAP_CYL} - <[id=connhole] [gender=F] [caps=none] [secs=R 8 2   R 6 16   R 8 2] [center=true] [slide=true]>
'not pinhole
'{SNAP_CYL} - <[gender=F] [caps=none] [secs=R 6 6   A 6 6   R 4 16] [slide=true] [pos=0 24 0]>

'3044a 'Regx for good files = ^1.*\.dat
'var sFile = "3023.dat"
'var sFile = "3626cp0p.dat"
'var sFile = "65826.dat" 'no shadow pin?
'var sFile = "4274.dat" 'Duplicated Stud (bigger lock compressible cylinder)?? (still wrong stud count?) [!bad orientation?]
'var sFile = "3749.dat" 'axle+pin (duplicated axles) (no barhole!!) [!bad center?]
'var sFile = "18651.dat" 'axle+pin (duplicated axles) (the only one of this class with barhole) [!bad orientation?]
'var sFile = "3024.dat" 'duplicated clutches (CHECK: unknown male)
'var sFile = "18654.dat" 'pinhole (hollow pin = 2 clutches)
'var sFile = "32006.dat" 'pinholes+axlehole+clutch (duplicated axlehole both sides???????)
'var sFile = "4589.dat" ' axlehole with clutch (bigger hollow stud?) (duplicated axlehole both sides?????) [!bad orientation?]
'var sFile = "87994.dat" 'bar
'var sFile = "3461.dat" 'have a (king)fat pinhole (maybe add a fat clutch/pinhole class?)
'var sFile = "967.dat"  'have a (king)pin [??bad center??]
'var sFile = "3011.dat" 'duplo (extra clutches)
var sFile = "3001.dat" 'clutches as aliases?
'var sFile = "3044a.dat" 'square clutches in a grid can slide? (or need hardcoded slide?) 

'var sFile = "4070.dat" '[!bad center]
'var sFile = "11203.dat" 'inverted tile '[!bad centering! (good test)] {?} '[grid centering?]
'var sFile = "32124.dat" '(axle holes) [!outside! female round] '[grid centering?]
'var sFile = "2711.dat" '(grid pinhole!! duplicated clutches (2711+steerend) [!outside! female round] '[!bad orientation]

'var sFile = "78329.dat"
'var sFile = "axlehole.dat"
'var sFile = "steerend.dat"
'var sFile = sPath+"\LDraw\parts\17715.dat" (removed??)
'var sFile = "15588.dat" 'alias of 48092 (need extra aliases clutches?)
'var sFile = "48092.dat"
'var sFile = "stud.dat"
'var sFile = "18651.dat" '(big axle that could have one extra virtual axle?) [!bad orientation!]
''var sFile = "3703.dat" '(included shadow over a grid... TODO: implement!) (SNAP_INCL)
''var sFile = "3003.dat" 'Shadow: SNAP_INCL
''var sFile = "3004.dat" 'Shadow: SNAP_INCL (name ref? duplicated clutches? (ignore?) TODO!)
'var sFile = "4531.dat" 'Shadow: SNAP_* (hinges, TODO: later implement)
'var sFile = "3673.dat" 'Shadow: SNAP_CLEAR (extra pin, missing barhole?) [!good orientation?!]
'var sFile = "3002.dat" 'same class of piece as 3001.dat
'var sFile = "3022.dat" 'same class of piece as 3001.dat
'var sFile = "2431.dat" 'tile
'var sFile = "35459.dat" 'tile
'var sFile = "32530.dat" 'OK 6 clutches , 2 pinholes
'var sFile = "3865.dat" 'baseplate

'var sFile = "168315a.dat" 'sticker
'var sFile = "3001s01.dat" 'subpart of 3001.dat
'var sFile = "connhole.dat" 'subpart
'var sFile = "t01i3261.dat" 'subpart
'var sFile = "connect.dat" 'subpart
'var sFile = "axle.dat" 'subpart
'var sFile = "C:\Users\greg\Desktop\LDCAD\examples\5510.mpd"

#if 1
   'var sFile = sPath+"\LDraw\parts\3001.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3002.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3003.dat"     'FINE (duplicated clutches from two subparts)
   'var sFile = sPath+"\LDraw\parts\3004.dat"     'FINE (duplicated clutches
   'var sFile = sPath+"\LDraw\parts\3005.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3006.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3007.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3008.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3009.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3010.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3011.dat"     'THE 59 LOOKS A LITTLE SUS BUT WHEN I TESTED I LDACAD IT SEEMS FINE
   'var sFile = sPath+"\LDraw\parts\3018.dat"     'FINE (huge stud/clutch)
   'var sFile = sPath+"\LDraw\parts\3020.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3021.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3022.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3023.dat"     'FINE plate
   'var sFile = sPath+"\LDraw\parts\3026.dat"     'FINE (144 studs 259 clutches)
   'var sFile = sPath+"\LDraw\parts\3027.dat"     'FINE plate
   'var sFile = sPath+"\LDraw\parts\3030.dat"     'FINE plate
   'var sFile = sPath+"\LDraw\parts\3031.dat"     'FINE plate
   'var sFile = sPath+"\LDraw\parts\3032.dat"     'FINE plate
   'var sFile = sPath+"\LDraw\parts\3033.dat"     'FINE plate
   'var sFile = sPath+"\LDraw\parts\3034.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3035.dat"     'FINE plate
   'var sFile = sPath+"\LDraw\parts\3036.dat"     'FINE plate
   'var sFile = sPath+"\LDraw\parts\3037.dat"     'FINE (missing shadow for the clutch holes?)
   'var sFile = sPath+"\LDraw\parts\3038.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3039.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\18654.dat"    'should be 20x20x20 but maybe it has a slightly thinner diameter compared to a 1x1 round brick
   'var sFile = sPath+"\LDraw\parts\3062bp02.dat" 'FINE (A caps?)
   'var sFile = sPath+"\LDraw\parts\4588.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3040.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3041.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3042.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3043.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3044.dat"     'FINE (special clutch) [!Center! mismatch]
   'var sFile = sPath+"\LDraw\parts\3045.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3046.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3048.dat"      'FINE (special clutch) (TODO: (ignore) male grid of square clutches????)
   'var sFile = sPath+"\LDraw\parts\3049.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3058.dat"     'FINE (combination of aliases) [!Center?! mismatch]
   'var sFile = sPath+"\LDraw\parts\3062.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3063.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3065.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3066.dat"     'FINE (slide clutch defined as 8 clutches)
   'var sFile = sPath+"\LDraw\parts\3067.dat"     'FINE (slide clutch)
   'var sFile = sPath+"\LDraw\parts\3068.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3069.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3070.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3082.dat"     'THIS APPEARS TO BE WRONG, IT LOOKS LIKE ITS 2 LDU thick by 39 LDU tall including the nub and 32 LDU WIDE 
   'var sFile = sPath+"\LDraw\parts\3109.dat"     'FINE (subpart? shadow does not account holes)
   'var sFile = sPath+"\LDraw\parts\3110.dat"     '(subpart) this appears to be 20 LDU tall by 32 LDU wide by 72 LDU long
   'var sFile = sPath+"\LDraw\parts\3111.dat"     '(no shadow) actually right :) (need further review on the subparts of this)
   'var sFile = sPath+"\LDraw\parts\3112.dat"     '(no shadow) actually right :) (need further review on the subparts of this)
   'var sFile = sPath+"\LDraw\parts\3127.dat"     '(size? mega wrong :D)
   'var sFile = sPath+"\LDraw\parts\3130.dat"     'FINE (miss many shadow info)
   'var sFile = sPath+"\LDraw\parts\3131.dat"     'FINE (miss many shadow info)
   'var sFile = sPath+"\LDraw\parts\3134.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3135.dat"     '45 LDU not 100 LDU [!center! mismatch]
   'var sFile = sPath+"\LDraw\parts\3136.dat"      'cool, fine (different size studs?)
   'var sFile = sPath+"\LDraw\parts\3137.dat"     'FINE (check shadow?)
   'var sFile = sPath+"\LDraw\parts\3139.dat"     'FINE (no shadow info)
   'var sFile = sPath+"\LDraw\parts\3144.dat"     'damn this is actaully right (male grid (to be ignored?), two caps)
   'var sFile = sPath+"\LDraw\parts\3145.dat"     '(TODO: 3 sided connections, missing some?) I cant move that finley in ldcad but 122.96 LDU looks correct as well as 69.28
   'var sFile = sPath+"\LDraw\parts\3148.dat"     'FINE (TODO: hinge)
   'var sFile = sPath+"\LDraw\parts\3149.dat"     'FINE (TODO: hinges)
   'var sFile = sPath+"\LDraw\parts\3160.dat"     'width and depdth is fine, heigh seems kinda insaneley precise.
   'var sFile = sPath+"\LDraw\parts\3161.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3167.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3176.dat"     'FINE (resume checking from here)
   'var sFile = sPath+"\LDraw\parts\3190.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3191.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3192.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3193.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3194.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3195.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3200.dat"     'part doesn't exist but stop here (so at 3200)
    
   'var sFile = sPath+"\LDraw\parts\3461.dat"     'height should be 20 not 24, width and depth is fine (24 both on part/subparts)
#endif   

'var sFile = sPath+"\LDraw\p\stud4.dat"
'var sFile = sPath+"\LDraw\p\4-4edge.dat"

'var sFile = sPath+"LDraw\models\car.ldr"
'var sFile = sPath+"\examples\5580.mpd"

'var sFile = sPath+"LDraw\digital-bricks.de parts not in LDRAW\12892.dat"

dim as string sModel

#if 1 '1 = Load File , 0 = Load From clipboard
   if instr(sFile,"\")=0 andalso instr(sFile,"/")=0 then FindFile(sFile)
   printf(!"Model: '%s'\n",sFile)
   if LoadFile( sFile , sModel ) = 0 then
      print "Failed to load '"+sFile+"'"
      sleep : system
   end if
   var pModel = LoadModel( strptr(sModel) , sFile )
#else
   sModel = GetClipboard() 
   if instr(sModel,".dat") then
      for N as long = 0 to len(sModel)
         if sModel[N]=13 then sModel[N]=32
      next N
   else 'if there isnt a model in the clipboard, then load this:
      sModel = _    
      "1 1 -40 24 20 1 0 0 0 1 0 0 0 1 3001.dat" EOL _
      "1 1 0 0 0 1 0 0 0 1 0 0 0 1 3001.dat" EOL _      
      ' ------------------------------------------------------
      
      'sModel = _ 'all of lines belo should end with EOL _
      '   "1 4 0 0 0 1 0 0 0 1 0 0 0 1 30068.dat"    EOL _
      '   "1 1 0 -10 0 1 0 0 0 1 0 0 0 1 18654.dat"  EOL _
      ' ------------------------------------------------------
   end if   
   var pModel = LoadModel( strptr(sModel) , "CopyPaste.ldr" )
#endif

InitOpenGL()

'glPolygonMode( GL_FRONT_AND_BACK, GL_LINE )

dim as single fRotationX = 120 , fRotationY = 20
dim as single fPositionX , fPositionY , fZoom = -3
dim as long iWheel , iPrevWheel

var iModel = glGenLists( 1 )
glNewList( iModel ,  GL_COMPILE ) 'GL_COMPILE_AND_EXECUTE
RenderModel( pModel , false )
RenderModel( pModel , true )
glEndList()

dim as single xMid,yMid,zMid , g_zFar
dim as PartSize tSz
SizeModel( pModel , tSz )
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

'puts("3001 <2> B1 s7 = 3001 <2> B2 c1;")
puts("")
puts("3001 B1 s7 = 3001 B2 c1;")
puts("1 0 40 -24 -20 1 0 0 0 1 0 0 0 1 3001.dat")
puts("1 0 0 0 0 1 0 0 0 1 0 0 0 1 3001.dat")

dim as double dRot = timer
dim as boolean bBoundingBox
dim as boolean bLeftPressed,bRightPressed,bWheelPressed
dim as long iFps

do
   
   glClear GL_COLOR_BUFFER_BIT OR GL_DEPTH_BUFFER_BIT      
   glLoadIdentity()
   
   glScalef(1/-20, 1.0/-20, 1/20 )
      
   '// Set light position (0, 0, 0)
   dim as GLfloat lightPos(...) = {0,0,0, 1.0f}'; // (x, y, z, w), w=1 for positional light
   glLightfv(GL_LIGHT0, GL_POSITION, @lightPos(0))
   
   'g_zFar
   glTranslatef( -fPositionX , fPositionY , 80*fZoom ) '/-5)
   
   glRotatef fRotationY , -1.0 , 0.0 , 0
   glRotatef fRotationX , 0   , -1.0 , 0
   
   glPushMatrix()
   with tSz
      'glTranslatef( (.xMin+.xMax)/-2  , (.yMin+.yMax)/-2 , (.zMin+.zMax)/-2 )
   end with
   
   glDisable( GL_LIGHTING )
   glCallList(	iModel )   
   glEnable( GL_LIGHTING )
   
   
   dim as PartSnap tSnap = any
   static as byte bOnce
   'if bOnce=0 then
      'SnapModel( pModel , tSnap , 2 )
      'bOnce=1
   'else
      SnapModel( pModel , tSnap , true )
   'end if

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
   
   if bBoundingBox then         
      glColor4f(0,1,0,.25)
      with tSz
         DrawLimitsCube( .xMin-1,.xMax+1 , .yMin-1,.yMax+1 , .zMin-1,.zMax+1 )
      end with   
   end if
   
   glPopMatrix()
            
   Dim e as fb.EVENT = any
   while (ScreenEvent(@e))
      Select Case e.type
      Case fb.EVENT_MOUSE_MOVE
         if bLeftPressed  then fRotationX += e.dx : fRotationY += e.dy
         if bRightPressed then fPositionX += e.dx*g_zFar/100 : fPositionY += e.dy*g_zFar/100
      case fb.EVENT_MOUSE_WHEEL
         iWheel = e.z-iPrevWheel
         fZoom = -3+(iWheel/2)
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
         select case e.scancode
         case fb.SC_TAB
            bBoundingBox = not bBoundingBox
         end select
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


