#include "LoadLDR.bas"

#include "Include\Colours.bas"
#include "Modules\Clipboard.bas"

#include "Modules\InitGL.bas"
#include "Modules\Math3D.bas"
#include "Modules\Normals.bas"
#include "Modules\Matrix.bas"
#include "Modules\Model.bas"

'https://www.melkert.net/LDCad/tech/meta

'TODO: check shadow library format, Load and parse them??
   'Continue parsing of shadow library (must include files)
   'parse the named parameters of each type of snap information
   'seems that only cylindrical ones will be important for now
   'Male being stud... Female being clutches (detect aliases? to account for others?)   

'TODO: add studs from te DAT file (in SizeModel function)
'TODO: rename SizeModel function to GetModelInfo (to calculate size,studs,clutches,etc...)
'TODO: list studs/clutches/axles, their positions and normal vectors
'TODO: can we match studs/clutches/axles from sub primatives? (only studs and aliases?)

var sPath = environ("userprofile")+"\Desktop\LDCAD\"

'3044a 'Regx for good files = ^1.*\.dat
'var sFile = sPath+"\LDraw\parts\3023.dat"
'var sFile = sPath+"\LDraw\parts\3024.dat"
'var sFile = sPath+"\LDraw\parts\3044a.dat"
'var sFile = sPath+"\LDraw\parts\4589.dat"
'var sFile = sPath+"\LDraw\parts\3461.dat" '10??
'var sFile = sPath+"\LDraw\p\t01i3261.dat"
'var sFile = sPath+"LDraw\deleted\official\168315a.dat"
'var sFile = sPath+"\LDraw\parts\3011.dat"
'var sFile = sPath+"\LDraw\parts\3001.dat"
'var sFile = sPath+"\LDraw\parts\s\3001s01.dat"
'var sFile = sPath+"\LDraw\parts\4070.dat"
'var sFile = sPath+"\LDraw\parts\78329.dat"
'var sFile = sPath+"\LDraw\parts\2711.dat"
'var sFile = sPath+"\LDraw\parts\32124.dat" (axle holes)
''var sFile = sPath+"\LDraw\parts\17715.dat"
'var sFile = sPath+"\LDraw\parts\15588.dat" 'alias of 48092
'var sFile = sPath+"\LDraw\parts\48092.dat"
'var sFile = "stud.dat"
'var sFile = "18651.dat"
var sFile = "3703.dat"
'var sFile = "connhole.dat"
'var sFile = "C:\Users\greg\Desktop\LDCAD\examples\5510.mpd"

#if 1
   'var sFile = sPath+"\LDraw\parts\3001.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3002.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3003.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3004.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3005.dat"     'FINE (needs shadow library for clutch)
   'var sFile = sPath+"\LDraw\parts\3006.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3007.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3008.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3009.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3010.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3011.dat"     'THE 59 LOOKS A LITTLE SUS BUT WHEN I TESTED I LDACAD IT SEEMS FINE
   'var sFile = sPath+"\LDraw\parts\3018.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3020.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3021.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3022.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3023.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3026.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3027.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3030.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3031.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3032.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3033.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3034.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3035.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3036.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3037.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3038.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3039.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\18654.dat"    'should be 20x20x20 but maybe it has a slightly thinner diameter compared to a 1x1 round brick
   'var sFile = sPath+"\LDraw\parts\3062bp02.dat" 'FINE yeah the above part is probably just slightly narrower in diameter
   'var sFile = sPath+"\LDraw\parts\4588.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3040.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3041.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3042.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3043.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3044.dat"     'FINE (special clutch)
   'var sFile = sPath+"\LDraw\parts\3045.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3046.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3048.dat"     'FINE (special clutch)
   'var sFile = sPath+"\LDraw\parts\3049.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3058.dat"     'FINE (combination of aliases)
   'var sFile = sPath+"\LDraw\parts\3062.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3063.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3065.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3066.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3067.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3068.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3069.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3070.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3082.dat"     'THIS APPEARS TO BE WRONG, IT LOOKS LIKE ITS 2 LDU thick by 39 LDU tall including the nub and 32 LDU WIDE 
   'var sFile = sPath+"\LDraw\parts\3109.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3110.dat"     'this appears to be 20 LDU tall by 32 LDU wide by 72 LDU long
   'var sFile = sPath+"\LDraw\parts\3111.dat"     'actually right :) (need further review on the subparts of this)
   'var sFile = sPath+"\LDraw\parts\3112.dat"     'actually right :) (need further review on the subparts of this)
   'var sFile = sPath+"\LDraw\parts\3127.dat"     'mega wrong :D
   'var sFile = sPath+"\LDraw\parts\3130.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3131.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3134.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3135.dat"     '45 LDU not 100 LDU
   'var sFile = sPath+"\LDraw\parts\3136.dat"     'cool, fine
   'var sFile = sPath+"\LDraw\parts\3137.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3139.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3144.dat"     'damn this is actaully right
   
   'var sFile = sPath+"\LDraw\parts\3145.dat"     'I cant move that finley in ldcad but 122.96 LDU looks correct as well as 69.28
   'var sFile = sPath+"\LDraw\parts\3148.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3149.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3160.dat"     'width and depdth is fine, heigh seems kinda insaneley precise.
   'var sFile = sPath+"\LDraw\parts\3161.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3167.dat"     'FINE
   'var sFile = sPath+"\LDraw\parts\3176.dat"     'FINE
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
      "1 14 0 0 0 1 0 0 0 1 0 0 0 1 3001.dat"     EOL _
      "1 1 0 24 0 1 0 0 0 1 0 0 0 1 3623.dat"     EOL _
      "1 4 -38 24 73 1 0 0 0 1 0 0 0 1 34103.dat" EOL _
      "1 2 46 24 75 1 0 0 0 1 0 0 0 1 77850.dat"  EOL _
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

dim as PartSize tSz
dim as single xMid,yMid,zMid , g_zFar
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
      glTranslatef( (.xMin+.xMax)/-2  , (.yMin+.yMax)/-2 , (.zMin+.zMax)/-2 )
   end with
   
   glDisable( GL_LIGHTING )
   glCallList(	iModel )   
   glEnable( GL_LIGHTING )
   
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


