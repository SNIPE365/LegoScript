'#define GL_GLEXT_PROTOTYPES

#include once "GL/gl.bi"
#include once "GL/glext.bi"
#include once "GL/glu.bi"
#include once "GL/glut.bi"
#include once "fbgfx.bi"

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

const ScrWid=640,ScrHei=480

sub InitOpenGL()   
   
   'screencontrol( fb.SET_GL_NUM_SAMPLES , 4 )
   'screencontrol( fb.SET_GL_DEPTH_BITS , 24 )
   'screencontrol( fb.SET_GL_COLOR_BITS , 32 )
   screenres ScrWid,ScrHei,32,,fb.GFX_OPENGL' or fb.GFX_MULTISAMPLE      
   
   '' ReSizeGLScene
   glViewport 0, 0, ScrWid, ScrHei                  '' Reset The Current Viewport
   glMatrixMode GL_PROJECTION                       '' Select The Projection Matrix
   glLoadIdentity                                   '' Reset The Projection Matrix
   gluPerspective 45.0, ScrWid/ScrHei, 1, 100.0*cScale   '' Calculate The Aspect Ratio Of The Window
   glMatrixMode GL_MODELVIEW                        '' Select The Modelview Matrix
   glLoadIdentity                                   '' Reset The Modelview Matrix
   
   '' All Setup For OpenGL Goes Here
   glShadeModel GL_SMOOTH                           '' Enable Smooth Shading
   glClearColor 115/255, 140/255, 191/255, 0.5      '' Background color
   glClearDepth 1.0                                 '' Depth Buffer Setup
   glEnable GL_DEPTH_TEST                           '' Enables Depth Testing
   'glDisable GL_DEPTH_TEST                         '' Enables Depth Testing
   glDepthFunc GL_LEQUAL                            '' The Type Of Depth Testing To Do
   glHint GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST '' Really Nice Perspective Calculations
   glEnable GL_BLEND
   glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
   
   'glPolygonMode( GL_FRONT_AND_BACK , GL_LINE )
   'GL_POINT, GL_LINE, and GL_FILL.    
   
   glEnable(GL_LINE_SMOOTH)
   'glEnable(GL_POLYGON_SMOOTH)
   glEnable(GL_MULTISAMPLE)
   'glEnable(GL_SAMPLE_COVERAGE)
   'fnglSampleCoverage(0.5, GL_FALSE)
   glLineWidth(1.25)
   
   'glEnable( GL_CULL_FACE )
   glDisable( GL_CULL_FACE )
   'glFrontFace( GL_CCW ): glCullFace(	GL_BACK )
   'glFrontFace( GL_CW ): glCullFace( GL_FRONT )
   
   glEnable(GL_POLYGON_OFFSET_FILL)
   glPolygonOffset(1.0, 1/-20)
   
   '============== light initialization ==============
    glEnable(GL_LIGHTING)
    '// Enable light source 0
    glEnable(GL_LIGHT0)
    
    '// Set light properties (optional)
    
    '// Ambient light (soft background lighting)
    dim as GLfloat ambientLight(...) = {0.2f, 0.2f, 0.2f, 1.0f}';  // Low-intensity white ambient light
    glLightfv(GL_LIGHT0, GL_AMBIENT, @ambientLight(0))

    '// Diffuse light (main light that affects the surface)
    dim as GLfloat diffuseLight(...) = {1.0f/20, 1.0f/20, 1.0f/20, 1.0f}';  // Bright white diffuse light
    glLightfv(GL_LIGHT0, GL_DIFFUSE, @diffuseLight(0))

    '// Specular light (shiny reflections)
    dim as GLfloat specularLight(...) = {1.0f/20, 1.0f/20, 1.0f/20, 1.0f}'; // White specular light
    glLightfv(GL_LIGHT0, GL_SPECULAR, @specularLight(0))
    
    glEnable(GL_COLOR_MATERIAL)
    glColorMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE)        
    
    

end sub
