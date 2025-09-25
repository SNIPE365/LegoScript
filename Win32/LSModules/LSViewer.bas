'******************************************************************
namespace Viewer
   dim shared as byte g_LoadFile = 0
   dim shared as string g_sGfxFile , g_sFileName
   dim shared as any ptr g_Mutex
   dim shared as boolean bShowCollision
   
   function LoadMemory( sContents as string , sName as string = "Unnamed.ls" ) as boolean
      MutexLock( g_Mutex )
         g_sGfxFile = sContents : g_sFileName = sName
         g_LoadFile = 1
      Mutexunlock( g_Mutex )
      return true
   end function      
   function LoadFile( sFile as string ) as boolean
      dim as boolean bLoadResult = FALSE
      MutexLock( g_Mutex )
      do
         g_LoadFile = 0  
         if .LoadFile( sFile , g_sGfxFile )=0 then exit do
         bLoadResult = TRUE : g_sFileName = sFile
         g_LoadFile = 1 : exit do                 
      loop
      Mutexunlock( g_Mutex )
      return bLoadResult
   end function

   sub MainThread( hReadyEvent as any ptr )
      
      g_Mutex = MutexCreate()
      dim as long ScrWid,ScrHei : screeninfo ScrWid,ScrHei      
      g_GfxHwnd = InitOpenGL(ScrWid,ScrHei)   
      
      scope
         dim as RECT tRcWnd = any , tRcCli = any
         GetWindowRect( g_GfxHwnd , @tRcWnd ): GetClientRect( g_GfxHwnd , @tRcCli ) 
         tRcWnd.right -= tRcWnd.left : tRcWnd.bottom -= tRcWnd.top
         tRcWnd.right -= tRcCli.right : tRcWnd.bottom -= tRcCli.Bottom
         SetWindowPos( g_GfxHwnd , NULL , g_tCfg.lGfxX,g_tCfg.lGfxY , _
            tRcWnd.right+g_tCfg.lGfxWid , tRcWnd.bottom+g_tCfg.lGfxHei , _
            SWP_NOMOVE or SWP_NOZORDER or SWP_NOACTIVATE )
      end scope
      ShowWIndow( g_GfxHwnd , SW_HIDE )
      if hReadyEvent then SetEvent( hReadyEvent )
      SetEvent( g_hResizeEvent )
                  
      dim as long iModel=-1,iBorders=-1
      dim as DATFile ptr  pModel
      dim as single xMid,yMid,zMid , g_zFar
      dim as PartSize tSz
      dim as long g_PartCount , g_CurPart = -1
               
      dim as boolean bBoundingBox
      dim as boolean bLeftPressed,bRightPressed,bWheelPressed
      dim as byte bShiftPressed
      dim as long iFps
      dim as single fRotationX = 120 , fRotationY = 20
      dim as single fPositionX , fPositionY , fPositionZ , fZoom = -3
      dim as long iWheel , iPrevWheel
      dim as long g_DrawCount , g_CurDraw = -1
      
      redim as PartCollisionBox atCollision()
                  
      do until g_DoQuit 
                           
         Dim e as fb.EVENT = any
         while (ScreenEvent(@e))
            Select Case e.type
            Case fb.EVENT_MOUSE_MOVE
               if bLeftPressed  then fRotationX += e.dx : fRotationY += e.dy
               if bRightPressed then fPositionX += e.dx*g_zFar/100 : fPositionY += e.dy*g_zFar/100
            case fb.EVENT_MOUSE_WHEEL
                 iWheel = e.z-iPrevWheel
                 fZoom = -3+(-iWheel/12) 'non inverted mouse wheel to zoom
            case fb.EVENT_MOUSE_BUTTON_PRESS
               if e.button = fb.BUTTON_MIDDLE then 
                  iPrevWheel = iWheel : fZoom = -3
                  fRotationX = 120 : fRotationY = 20
                  fPositionX = 0 : fPositionY = 0 
               end if
               if e.button = fb.BUTTON_LEFT   then bLeftPressed  = true
               if e.button = fb.BUTTON_RIGHT  then bRightPressed = true
            case fb.EVENT_MOUSE_BUTTON_RELEASE
               if e.button = fb.BUTTON_LEFT   then bLeftPressed  = false
               if e.button = fb.BUTTON_RIGHT  then bRightPressed = false      
            case fb.EVENT_KEY_PRESS
               select case e.ascii
               case 8
                  if bShiftPressed then
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
                  if bShiftPressed then
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
                  if bShiftPressed then
                     g_CurPart = ((g_CurPart+g_PartCount+1) mod (g_PartCount+1))-1
                     printf(!"g_CurPart = %i    \r",g_CurPart)
                     dim as PartSize tSzTemp
                     SizeModel( pModel , tSzTemp , g_CurPart )
                     tSz = tSzTemp
                  else
                     g_CurDraw = ((g_CurDraw+g_DrawCount+1) mod (g_DrawCount+1))-1
                     printf(!"g_CurDraw = %i    \r",g_CurDraw)
                  end if               
               case asc("S")-asc("@") 'ctrl+S 'shadow
                  if g_CurDraw >=0 then
                     'FindFile(
                     'FindShadowFile(
                     with pModel->tParts(g_CurDraw)
                        if .bType=1 then                              
                           var sFile = GetPartNameByIndex(._1.lModelIndex)
                           if FindShadowFile(sFile) then 
                              shell "start notepad "+sFile
                           else
                              MessageBox( g_GfxHwnd , sFile , "Shadow file not found" , MB_ICONWARNING )
                           end if
                        end if
                     end with
                  end if
               case asc("M")-asc("@") 'ctrl+M 'Model
                  if g_CurDraw >=0 then                     
                     with pModel->tParts(g_CurDraw)
                        if .bType=1 then                              
                           var sFile = GetPartNameByIndex(._1.lModelIndex)
                           if FindFile(sFile) then 
                              shell "start notepad "+sFile
                           else
                              MessageBox( g_GfxHwnd , sFile , "Model file not found" , MB_ICONWARNING )
                           end if
                        end if
                     end with
                  end if
               end select
               select case e.scancode
               case fb.SC_LSHIFT : bShiftPressed or= 1
               case fb.SC_RSHIFT : bShiftPressed or= 2
               case fb.SC_TAB    : bBoundingBox = not bBoundingBox
               case fb.SC_SPACE  : bShowCollision = not bShowCollision
               case fb.SC_DELETE
                  if bShiftPressed then
                     iPrevWheel = iWheel : fZoom = -3
                     fRotationX = 120 : fRotationY = 20
                     fPositionX = 0 : fPositionY = 0 
                  end if
               end select
            case fb.EVENT_KEY_RELEASE
               select case e.scancode
               case fb.SC_LSHIFT : bShiftPressed and= (not 1)
               case fb.SC_RSHIFT : bShiftPressed and= (not 2)
               end select
            case fb.EVENT_WINDOW_CLOSE
               menu.Trigger( 30001 ) 'hide GFX window
            end select
         wend
                     
         if IsWindowVisible( g_GfxHwnd ) = 0 then
            flip : sleep 10,1 : continue do
         end if
         flip
         
         static as double dLimitFps
         if abs(timer-dLimitFps) > 1 then dLimitFps = timer
         while (timer-dLimitFps) < 1/30
            sleep 1,1
         wend
         dLimitFps += 1/30
         
         static as double dFps : iFps += 1   
         if abs(timer-dFps)>1 then
            dFps = timer
            WindowTitle("Fps: " & iFps): iFps = 0         
         else
            sleep 1
         end if    
                  
         if g_LoadFile then
            MutexLock( g_Mutex )            
            Try()
               do            
                  g_LoadFile = 0
                  if pModel then 'cleanup previous loaded model/lists (leaking shadow?)
                     FreeModel( pModel )
                     if iModel >=0 then glDeleteLists( iModel , 1 ) : iModel = -1
                     if iBorders >=0 then glDeleteLists( iBorders , 2 ) : iBorders = -1
                  end if 
                  g_TotalLines = 0 : g_TotalOptis = 0 : g_TotalTrigs = 0 : g_TotalQuads = 0
                  static as string sPrevFilename                  
                  pModel = LoadModel( strptr(g_sGfxFile) , g_sFileName )                  
                  g_sGfxFile = "" : if pModel = NULL then exit do 'failed to load
                  iModel   = glGenLists( 1 )
                  glNewList( iModel ,  GL_COMPILE ) 'GL_COMPILE_AND_EXECUTE
                  RenderModel( pModel , false )
                  glEndList()
                  iBorders = glGenLists( 2 )
                  glNewList( iBorders ,  GL_COMPILE )
                  RenderModel( pModel , true )
                  glEndList()
                  glNewList( iBorders+1 ,  GL_COMPILE )
                  RenderModel( pModel , true , , -2 )
                  glEndList()
                                                      
                  var bResetAttributes = sPrevFilename <> g_sFileName
                  if bResetAttributes then
                     fZoom = -3 : fRotationX = 120 : fRotationY = 20
                     iWheel = 0 : iPrevWheel = 0 
                     sPrevFilename = g_sFileName
                  end if
                  
                  g_PartCount = 0 : g_DrawCount = pModel->iPartCount
                  g_CurPart = -1 : g_CurDraw = -1
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
                     #ifdef ViewerShowInfo
                        printf(!"X %f > %f (%g ldu)\n",.xMin,.xMax,(.xMax-.xMin))
                        printf(!"Y %f > %f (%g ldu)\n",.yMin,.yMax,(.yMax-.yMin))
                        printf(!"Z %f > %f (%g ldu)\n",.zMin,.zMax,(.zMax-.zMin))
                        printf(!"Lines: %i - Optis: %i - Trigs: %i - Quads: %i - Verts: %i\n", _
                           g_TotalLines , g_TotalOptis , g_TotalTrigs , g_TotalQuads , _
                           g_TotalLines*2+g_TotalOptis*2+g_TotalTrigs*3+g_TotalQuads*4 _
                        )
                     #endif
                     if bResetAttributes then
                        'fPositionX = 0 '((.xMin + .xMax)\-2)-.xMin
                        'fPositionY = (.yMin + .yMax)\-2
                        fPositionX = ((.xMax+.xMin)\-2) '-.xMin
                        fPositionY = ((.yMax+.yMin)\2) '+.yMin
                        fPositionZ = (.zMax-.zMin) 'abs(.zMax)-abs(.zMin)
                        fPositionZ = sqr(fPositionZ)*-40
                     end if
                  end with
                                 
                  CheckCollisionModel( pModel , atCollision() )
                  #ifdef ViewerShowInfo
                     printf(!"Parts: %i , Collisions: %i \n",g_PartCount,ubound(atCollision)\2)
                  #endif
                  
                  exit do 'loaded fine
                  
               loop
            Catch()
               LogError("Viewer.LoadFile crashed!!!")               
            EndCatch()
            EndTry()
            MutexUnlock( g_Mutex )
         end if
         
         
         're-create base view in case the window got resized
         if WaitForSingleObject( g_hResizeEvent , 0 )=0 then
            dim as RECT tRc : GetClientRect(g_GfxHwnd,@tRc)
            var g_iCliWid = tRc.right , g_iCliHei = tRc.bottom        
            glViewport 0, 0, gfx.g_iCliWid, gfx.g_iCliHei                  '' Reset The Current Viewport
            glMatrixMode GL_PROJECTION                       '' Select The Projection Matrix
            glLoadIdentity                                   '' Reset The Projection Matrix
            gluPerspective 45.0, gfx.g_iCliWid/gfx.g_iCliHei, 1, 100.0*cScale   '' Calculate The Aspect Ratio Of The Window
            glMatrixMode GL_MODELVIEW                        '' Select The Modelview Matrix
         end if
         
         glClear GL_COLOR_BUFFER_BIT OR GL_DEPTH_BUFFER_BIT      
         glLoadIdentity()
         
         if pModel=0 then continue do
         
         glScalef(1/-20, 1.0/-20, 1/20 )
            
         '// Set light position (0, 0, 0)
         dim as GLfloat lightPos(...) = {0,0,0, 1.0f}'; // (x, y, z, w), w=1 for positional light
         glLightfv(GL_LIGHT0, GL_POSITION, @lightPos(0))            
         glTranslatef( -fPositionX , fPositionY , fPositionZ*(fZoom+4) )      
         glRotatef fRotationY , -1.0 , 0.0 , 0
         glRotatef fRotationX , 0   , -1.0 , 0      
         
         'glPushMatrix()
         
         glDisable( GL_LIGHTING )
         
         static as long OldDraw = -1
         Try()
            if g_CurDraw < 0 then
               glCallList(	iModel ) : OldDraw = -1
            else
               RenderModel( pModel , false , , g_CurDraw )
               
               scope 'Render Snap IDs
                  static as PartSnap tSnapID
                  if g_CurDraw <> -1 andalso OldDraw <> g_CurDraw then                        
                     var pSubPart = g_tModels( pModel->tParts(g_CurDraw)._1.lModelIndex ).pModel                  
                     SnapModel( pSubPart , tSnapID )      
                     SortSnap( tSnapID )
                  end if
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
                        glDrawText( sText , .tPos.X,.tPos.Y+(_YOff),.tPos.Z , 8/len(sText),8 , true )
                     end if
                  #endmacro
                  if g_CurDraw <> -1 then      
                     glPushMatrix()                  
                     with pModel->tParts(g_CurDraw)._1
                        dim as single fMatrix(15) = { _
                           .fA , .fD , .fG , 0 , _ 'X scale ,    0?   ,   0?    , 0 
                           .fB , .fE , .fH , 0 , _ '  0?    , Y Scale ,   0?    , 0 
                           .fC , .fF , .fI , 0 , _ '  0?    ,    0?   , Z Scale , 0 
                           .fX , .fY , .fZ , 1 }   ' X Pos  ,  Y Pos  ,  Z Pos  , 1 
                        glMultMatrixf( @fMatrix(0) )
                     end with
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
                              DrawConnectorName(0)
                           end with
                        next N
                     end with
                     OldDraw = g_CurDraw
                     glPopMatrix()
                  end if
               end scope
               
               'SnapModel( pModel , tSnap , g_CurDraw )      
            end if
            glCallList(	iBorders-(g_CurDraw>=0) )
            Catch()
               LogError("Crashed at rendering!!!")
            EndCatch()
         EndTry()
      
         glEnable( GL_LIGHTING )
         
         #ifdef DebugShadow
            dim as PartSnap tSnap = any
            static as byte bOnce         
            SnapModel( pModel , tSnap , true )
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
         if bShowCollision andalso iCollisions<>0 andalso instr(g_sFileName,".dat")=0 then
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
         
         'glPopMatrix()
         
      loop
      
      puts("ending gfx")
      Screen 0, , , fb.GFX_SCREEN_EXIT
      mutexdestroy( g_Mutex )
      
   end sub
end namespace
