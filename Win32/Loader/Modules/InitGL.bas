#ifndef __Main
  #error " Don't compile this one"
#endif  

'#define GL_GLEXT_PROTOTYPES

#include once "GL/gl.bi"
#include once "GL/glext.bi"
#include once "GL/glu.bi"
#include once "GL/glut.bi"
#include once "fbgfx.bi"

#include "ResizableGL.bas"

#if 0
   'https://www.ldraw.org/article/218 ldraw specification
   'LDraw uses a right-handed co-ordinate system where -Y is "up".
   dim as single transform[16] = { _
       1.0,  0.0,  0.0, 0.0,   _'// X stays the same
       0.0, -1.0,  0.0, 0.0,   _'// Y is flipped
       0.0,  0.0,  1.0, 0.0,   _'// Z stays the same
       0.0,  0.0,  0.0, 1.0    _'// Identity matrix for translation
   }   
   glMultMatrixf(@transform(0))
   'Draw parts are measured in LDraw Units (LDU)
   '1 brick width/depth = 20 LDU
   '1 brick height = 24 LDU
   '1 plate height = 8 LDU
   '1 stud diameter = 12 LDU
   '1 stud height = 4 LDU
   
   '0: Comment or META Command
   '1: Sub-file reference
   '2: Line
   '3: Triangle
   '4: Quadrilateral
   '5: Optional Line
   
#endif

'const ScrWid=640,ScrHei=480

#macro ForEachExtensionGL(_do)
   _do( glGenBuffers )
   _do( glBindBuffer )
   _do( glBufferData )
   _do( wglSwapIntervalEXT )
#endmacro

type PFNWGLSWAPINTERVALEXTPROC as function (as long) as winbool

#define DeclareExtension(_NAME) static shared as PFN##_NAME##PROC _NAME
ForEachExtensionGL( DeclareExtension )
#undef DeclareExtension

static shared as GLuint g_FontUI
const cUIFontWid=16 , cUIFontHei=16
sub checkGLError(message as string="")
    dim as GLenum ierr
    ierr = glGetError()
    while err <> GL_NO_ERROR
        select case ierr
        case GL_INVALID_ENUM
            puts( message & ": GL_INVALID_ENUM" )
        case GL_INVALID_VALUE
            puts( message & ": GL_INVALID_VALUE")
        case GL_INVALID_OPERATION
            puts( message & ": GL_INVALID_OPERATION")
        case GL_STACK_OVERFLOW
            puts( message & ": GL_STACK_OVERFLOW")
        case GL_STACK_UNDERFLOW
            puts( message & ": GL_STACK_UNDERFLOW")
        case GL_OUT_OF_MEMORY
            puts( message & ": GL_OUT_OF_MEMORY")
        case else
            puts( message & ": Unknown OpenGL error: " &  ierr)
        end select
        ierr = glGetError() '???
    wend
end sub
sub glDrawText( sText as string , fPX as single = 0 , fPY as single = 0 , fPZ as single , fWid as single = 1.0 , fHei as single = 1.0 , bCenter as boolean = false )
      
   glEnable (GL_ALPHA_TEST)
   glDisable(GL_BLEND)
   glDisable(GL_LIGHTING)

   glBindTexture(GL_TEXTURE_2D, g_FontUI)
   
   if fPY > 0 then fHei = -fHei 'fWid = -fWid 
   
   'if fPX > 0 then fWid = -fWid   
   'if fPZ > 0 then fHei = -fHei
   
   if bCenter then fPX -= len(sText)*fWid*.5 : fPZ -= fHei*.5
   dim as single fPXO = fPX
   
   
   for I as long = 0 to len(sText)-1
      const Q = 1/16
      var bChar = sText[I] 
      if bChar=13 then continue for
      if bChar=10 then fPX = fPXO : fPZ += fHei
      var fX = (bChar and 15)/16 , fY = (bChar\16)/16
      glBegin(GL_QUADS)
         glTexCoord2f(fX  , fY+Q) : glVertex3f(fPX      , fPY , fPZ     )
         glTexCoord2f(fX+Q, fY+Q) : glVertex3f(fPX+fWid , fPY , fPZ     )
         glTexCoord2f(fX+Q, fY  ) : glVertex3f(fPX+fWid , fPY , fPZ+fHei)
         glTexCoord2f(fX  , fY  ) : glVertex3f(fPX      , fPY , fPZ+fHei)
      glEnd()
      fPX += fWid
   next I    
   glBindTexture(GL_TEXTURE_2D, 0)
   
   glEnable(GL_LIGHTING)
   glDisable(GL_ALPHA_TEST)
   glEnable(GL_BLEND)
   'glEnable( GL_CULL_FACE )
   'glDisable( GL_CULL_FACE )
   'glFrontFace( GL_CCW ): glCullFace(	GL_BACK )
   
end sub
sub glInitFont()
         
   '--- create 16x16 white font with black border ---
   dim as fb.image ptr imgFont = ImageCreate( 16*cUIFontWid , 16*cUIFontHei , rgb(255,0,255) )
   dim as fb.image ptr imgChar = ImageCreate(cUIFontWid,cUIFontHei)
   dim as fb.image ptr imgChar2 = ImageCreate(cUIFontWid,cUIFontHei)
   for N as long = 0 to 255    
    line imgChar2, (0,0)-(cUIFontWid-1,cUIFontHei-1),rgb(255,0,255),bf
    for M as long = 0 to 1
      line imgChar, (0,0)-(cUIFontWid-1,cUIFontHei-1),rgb(255,0,255),bf
      draw string imgChar, (0,0), chr(N), iif( M , rgb(255,255,255) , rgb(8,8,8) )      
      for iX as long = 7 to 0 step-1
        put imgChar,(iX*2+1,0), imgChar,(iX,0)-(iX,7), pset
        put imgChar,(iX*2  ,0), imgChar,(iX,0)-(iX,7), pset
      next iX
      for iY as long = 7 to 0 step-1
        put imgChar,(0,iY*2+1), imgChar,(0,iY)-(cUIFontWid-1,iY), pset
        put imgChar,(0,iY*2  ), imgChar,(0,iY)-(cUIFontHei-1,iY), pset
      next iY
            
      if M then
        put imgChar2,(1,1), imgChar, trans
        var iPX = (N and 15)*cUIFontWid , iPY = (N\16)*cUIFontHei      
        put imgFont,(iPX,iPY),imgChar2,trans
      else        
        for iOY as long = -2 to 2
          for iOX as long = -2 to 2
            put imgChar2,(1+iOX,1+iOY), imgChar,trans
          next iOX
        next iOY        
      end if
      
    next M        
    
   next N
   var pPix = cptr(ulong ptr,imgFont+1)
   for iN as long = 0 to ((imgFont->Pitch\4)*(imgFont->Height))-1
      if pPix[iN] = rgb(255,0,255) then pPiX[iN] = 0 else pPix[iN] or= &hFF000000
   next iN  
  '--- upload font as OpenGL texture ---
   glGenTextures(1, @g_FontUI)
   glBindTexture(GL_TEXTURE_2D, g_FontUI)
   checkGLError()
   
   ' Upload the texture
   glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imgFont->width, imgFont->height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imgFont+1)
   checkGLError()
      
   ' Set texture filtering and wrapping
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
   'glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
   'glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
   
   glBindTexture(GL_TEXTURE_2D, 0)
    
   ImageDestroy( imgFont )
   ImageDestroy( imgChar )
   ImageDestroy( imgChar2 )
  
end sub

sub ResizeOpengGL( ScrWid as long , ScrHei as long )
   glViewport 0, 0, ScrWid, ScrHei                  '' Reset The Current Viewport
   glMatrixMode GL_PROJECTION                       '' Select The Projection Matrix
   glLoadIdentity                                   '' Reset The Projection Matrix
   gluPerspective 45.0, ScrWid/ScrHei, 1, 1000.0*cScale   '' Calculate The Aspect Ratio Of The Window
   glMatrixMode GL_MODELVIEW                        '' Select The Modelview Matrix
end sub

function InitOpenGL(ScrWid as long=640,ScrHei as long=480 ) as hwnd
   
   'screencontrol( fb.SET_GL_NUM_SAMPLES , 4 )
   'screencontrol( fb.SET_GL_DEPTH_BITS , 24 )
   'screencontrol( fb.SET_GL_COLOR_BITS , 32 )
   
   screenres 1,8192,32,,fb.GFX_OPENGL' or fb.GFX_MULTISAMPLE      
   Gfx.Resize(ScrWid,ScrHei)
   flip
   dim as HWND hwndGFX
   screencontrol fb.GET_WINDOW_HANDLE , *cptr(uinteger ptr,@hwndGFX)   
   InitRawInput( hwndGFX )
   
   #macro _InitExtension(_NAME) 
      _NAME = cast(any ptr, wglGetProcAddress(#_NAME))
      'printf(!"%s = %p\n",#_NAME,_NAME)
      if _NAME = 0 then
         printf("%s%s%s","ERROR: required extension '",#_NAME,!"' was not found\n")
         getchar : system()
      end if
   #endmacro
   ForEachExtensionGL( _InitExtension )
   #undef _InitExtension

         
   'var lCurStyle = GetWindowLong(hwndGFX,GWL_STYLE) and (not (WS_MINIMIZEBOX or WS_MAXIMIZEBOX))   
   var lCurStyle = GetWindowLong(hwndGFX,GWL_STYLE) or WS_MAXIMIZEBOX
   var lCurStyleEx = GetWindowLong(hwndGFX,GWL_EXSTYLE)
   SetWindowLong( hwndGFX , GWL_STYLE , lCurStyle or WS_SIZEBOX )
   'SetWindowLong( hwndGFX , GWL_EXSTYLE , lCurStyleEx or WS_EX_TOOLWINDOW )
   SetWindowPos( hwndGFX , NULL , 0,0 , 0,0 , SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED )
   
   '' ReSizeGLScene
   ResizeOpengGL( ScrWid , ScrHei )   
   glLoadIdentity                                   '' Reset The Modelview Matrix
   
   '' All Setup For OpenGL Goes Here
   glShadeModel GL_SMOOTH                           '' Enable Smooth Shading
   glClearColor 115/255, 140/255, 191/255, 1        '' Background color
   glClearDepth 1.0                                 '' Depth Buffer Setup
   glEnable GL_DEPTH_TEST                           '' Enables Depth Testing
   'glDisable GL_DEPTH_TEST                         '' Enables Depth Testing
   glDepthFunc GL_LESS                              '' The Type Of Depth Testing To Do
   glHint GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST '' Really Nice Perspective Calculations
   glEnable GL_BLEND
   glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
   glAlphaFunc( GL_GREATER , 0.5 )
   'glEnable(GL_NORMALIZE)
      
   glEnable(GL_TEXTURE_2D)
   
   'glDisable(GL_LINE_SMOOTH)
   'glEnable(GL_LINE_SMOOTH)
   'glLineWidth(1.25)
      
   'glEnable(GL_POLYGON_SMOOTH)
   'glEnable(GL_MULTISAMPLE)
   'glEnable(GL_SAMPLE_COVERAGE)
   'fnglSampleCoverage(0.5, GL_FALSE)
   
   
   'glPolygonMode( GL_FRONT_AND_BACK , GL_LINE )
   'GL_POINT, GL_LINE, and GL_FILL.
   'glEnable( GL_CULL_FACE )
   glDisable( GL_CULL_FACE )
   'glFrontFace( GL_CCW ): glCullFace(	GL_BACK )
   'glFrontFace( GL_CW ): glCullFace( GL_FRONT )
   glFrontFace( GL_CW ): glCullFace( GL_BACK )
      
   'glEnable(GL_POLYGON_OFFSET_FILL)
   'glPolygonOffset(1.0, 1/-20)
   
   '============== light initialization ==============
    glEnable(GL_LIGHTING)
    '// Enable light source 0
    glEnable(GL_LIGHT0)
    
    '// Set light properties (optional)
    
    '// Ambient light (soft background lighting)
    dim as GLfloat ambientLight(...) = {0.01f, 0.01f, 0.01f, 1.0f}';  // Low-intensity white ambient light
    glLightfv(GL_LIGHT0, GL_AMBIENT, @ambientLight(0))

    '// Diffuse light (main light that affects the surface)
    dim as GLfloat diffuseLight(...) = {1.0f/20, 1.0f/20, 1.0f/20, 1f}';  // Bright white diffuse light
    glLightfv(GL_LIGHT0, GL_DIFFUSE, @diffuseLight(0))

    '// Specular light (shiny reflections)
    dim as GLfloat specularLight(...) = {1.0f/20, 1.0f/20, 1.0f/20, 1f}'; // White specular light
    glLightfv(GL_LIGHT0, GL_SPECULAR, @specularLight(0))
    
    glEnable(GL_COLOR_MATERIAL)
    glColorMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE)
    
    glInitFont()
        
    return hwndGFX

end function
