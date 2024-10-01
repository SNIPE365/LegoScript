#include "LoadLDR.bas"

#include "Include\Colours.bas"
#include "Modules\Clipboard.bas"

#include "Modules\InitGL.bas"
#include "Modules\Math3D.bas"
#include "Modules\Normals.bas"
#include "Modules\Matrix.bas"
#include "Modules\Model.bas"

var sPath = environ("userprofile")+"\Desktop\LDCAD\"

'3044a 'Regx for good files = ^1.*\.dat
'var sFile = sPath+"\LDraw\parts\3024.dat"
'var sFile = sPath+"\LDraw\parts\3044a.dat"
'var sFile = sPath+"\LDraw\parts\4589.dat"
'var sFile = sPath+"\LDraw\parts\3461.dat" '10??
'var sFile = sPath+"\LDraw\p\t01i3261.dat"
'var sFile = sPath+"LDraw\deleted\official\168315a.dat"

'var sFile = sPath+"\LDraw\parts\3011.dat"

#if 0
   var sFile = sPath+"\LDraw\parts\3461.dat" 'height should be 20 not 24, width and depth is fine
   var sFile = sPath+"\LDraw\parts\3032.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3001.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3002.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3003.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3004.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3005.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3006.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3007.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3008.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3009.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3010.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3011.dat" ' THE 59 LOOKS A LITTLE SUS BUT WHEN I TESTED I LDACAD IT SEEMS FINE
   var sFile = sPath+"\LDraw\parts\3023.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3022.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3021.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3020.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3026.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3027.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3030.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3031.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3032.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3033.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3034.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3035.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3036.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3037.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3038.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\3039.dat" 'FINE
   var sFile = sPath+"\LDraw\parts\18654.dat" 'should be 20x20x20 but maybe it has a slightly thinner diameter compared to a 1x1 round brick
   var sFile = sPath+"\LDraw\parts\3062bp02.dat" 'fine yeah the above part is probably just slightly narrower in diameter
   var sFile = sPath+"\LDraw\parts\4588.dat" 'FINE
#endif

'var sFile = sPath+"\LDraw\p\stud4.dat"
'var sFile = sPath+"\LDraw\p\4-4edge.dat"

'var sFile = sPath+"LDraw\models\car.ldr"
'var sFile = sPath+"\examples\5580.mpd"

'var sFile = sPath+"LDraw\digital-bricks.de parts not in LDRAW\12892.dat"

dim as string sModel

#if 0 '1 = Load File , 0 = Load From clipboard
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
      sModel = _ 'all of lines belo should end with EOL _
         "1 4 0 0 0 1 0 0 0 1 0 0 0 1 30068.dat"    EOL _
         "1 1 0 -10 0 1 0 0 0 1 0 0 0 1 18654.dat"  EOL _
      ' ------------------------------------------------------
   end if   
   var pModel = LoadModel( strptr(sModel) , "CopyPaste.ldr" )
#endif

InitOpenGL()

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
end with   

dim as double dRot = timer
dim as boolean bLeftPressed,bRightPressed,bWheelPressed
dim as long iFps

do
   
   glClear GL_COLOR_BUFFER_BIT OR GL_DEPTH_BUFFER_BIT      
   glLoadIdentity()
   
   glScalef(1/-20, 1.0/-20, 1/20 )
      
   '// Set light position (0, 0, 0)
   dim as GLfloat lightPos(...) = {0,0,0, 1.0f}'; // (x, y, z, w), w=1 for positional light
   glLightfv(GL_LIGHT0, GL_POSITION, @lightPos(0))
   
   glTranslatef( -fPositionX , fPositionY , g_zFar*fZoom ) '/-5)
   
   glRotatef fRotationY , -1.0 , 0.0 , 0
   glRotatef fRotationX , 0   , -1.0 , 0
   
   glPushMatrix()
   with tSz
      glTranslatef( (.xMin+.xMax)/-2  , (.yMin+.yMax)/-2 , (.zMin+.zMax)/-2 )
   end with
   
   glDisable( GL_LIGHTING )
   glCallList(	iModel )   
   glEnable( GL_LIGHTING )
         
   glColor4f(0,1,0,.25)
   with tSz
      DrawLimitsCube( .xMin-1,.xMax+1 , .yMin-1,.yMax+1 , .zMin-1,.zMax+1 )
   end with   
   
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


