'******************************************************************
redim shared as PartCollisionBox g_Viewer_atCollision()
'declare sub View_ToggleKey()

namespace Viewer
  '#define UseVBO
  
  dim shared as byte g_LoadFile = 0
  dim shared as string g_sGfxFile , g_sFileName
  dim shared as any ptr g_Mutex
  dim shared as DATFile ptr g_pLoadedModel
  dim shared as boolean bShowCollision' = true
  common shared as DWORD Viewer_dwThisThread
  
  sub ReloadFile()
    MutexLock( g_Mutex )
    g_LoadFile = abs(g_LoadFile)
    Mutexunlock( g_Mutex )
  end sub
  
  function LoadMemory( sContents as string , sName as string = "Unnamed.ls" , bDoLock as boolean = true ) as boolean
    if bDoLock then MutexLock( g_Mutex )
       g_sGfxFile = sContents : g_sFileName = sName
       g_LoadFile = 1
    if bDoLock then Mutexunlock( g_Mutex )
    return true
  end function      
  function LoadFile( sFile as string ) as boolean
    dim as boolean bLoadResult = FALSE
    MutexLock( g_Mutex )
    do
       g_LoadFile = 0  
       if .LoadFile( sFile , g_sGfxFile )=0 then exit do
       bLoadResult = TRUE : g_sFileName = sFile
       g_LoadFile = 2 : exit do                 
    loop
    Mutexunlock( g_Mutex )
    return bLoadResult
  end function
  
  const NOTVIS = (not WS_VISIBLE)
  const CANRES = WS_THICKFRAME  
  const _TOOL = WS_EX_LAYERED
  
  dim shared PreDetour as any ptr,llDetour as ulongint  
  declare sub PreventWindowBlink(iUndo as integer=0)  
  private sub AutoUnDetour() destructor        
  'TimeEndPeriod(1)
  if PreDetour then PreventWindowBlink(1): PreDetour=0
  end sub
  
  sub CreateWindowExADetour naked alias "CreateWindowExADetour" ()
    asm      
      mov eax,[PreDetour]
      pusha
      call GetCurrentThreadID             '\ if we are not on the right THREAD
      cmp eax,[Viewer_dwThisThread]       '| then skip undoing the detour
      jnz 1f                              '/
      'push 1                                   
      'call PreventWindowBlink             ' undo detour
      'xor eax, eax                        ' tell that we did undo the detour
      1:
      popa     
      jnz 1f                              ' straight to the trampoline if not right THREAD    
      'and dword ptr [esp+3*4+8], NOTVIS
      'or dword ptr [esp+3*4+8], CANRES
      'or dword ptr [esp+0*4+8], TOOL
      mov dword ptr [esp+0*4+4], _TOOL
      'mov dword ptr [esp+3*4+4], _SET
      'hlt
      1:
      push ebp
      mov ebp,esp      
      jmp eax
      2:
      hlt
    end asm
  end sub
  sub PreventWindowBlink(iUndo as integer=0)    
    'TimeBeginPeriod(1)
    var pPtr = cast(any ptr,GetProcAddress(GetModuleHandle("user32.dll"),"CreateWindowExA"))
    dim as integer OldProt = any    
    VirtualProtect(pPtr,8,PAGE_READWRITE,@OldProt)      
    if iUndo then
      if PreDetour then
        'puts("undo")      
        *cptr(ulongint ptr,pPtr) = llDetour : PreDetour = 0
      end if
    else              
      if PreDetour=0 then                  
        'puts("detour")
        Viewer_dwThisThread = GetCurrentThreadID()
        PreDetour = pPtr+5 'mov esi | push ebp | mov ebp,esp
        llDetour = *cptr(ulongint ptr,pPtr)
        *cptr(ubyte ptr,pPtr+0) = &hE9
        *cptr(ulong ptr,pPtr+1) = clng(@CreateWindowExADetour)-clng(pPtr+5)
      end if
    end if
    VirtualProtect(pPtr,8,OldProt,@OldProt)
    FlushInstructionCache(GetCurrentProcess(),pPtr,8)
  end sub
  
  dim shared as any ptr g_pCollisionThread
  dim shared as long g_iCollisions
  
  sub CollisionThread( pbRedraw as any ptr )    
    SetThreadPriority( GetCurrentThread() , THREAD_PRIORITY_BELOW_NORMAL )
    var dTmr = timer : g_iCollisions = 0
    CheckCollisionModel( g_pLoadedModel , g_Viewer_atCollision() , @g_LoadFile )
    printf(!"Collision check took %ims\n",cint((timer-dTmr)*1000))
    #ifdef ViewerShowInfo
       printf(!"Parts: %i , Collisions: %i \n",g_PartCount,ubound(g_Viewer_atCollision)\2)
    #endif
    if g_LoadFile>0 then exit sub
    g_iCollisions = ubound(g_Viewer_atCollision)
    if g_iCollisions > 0 then InterlockedIncrement( pbRedraw )
  end sub
  
  sub MainThread( hReadyEvent as any ptr )
    
    g_Mutex = MutexCreate()
    
    dim as long ScrWid,ScrHei : screeninfo ScrWid,ScrHei                        
    #if __Main <> "LegoCAD"        
    PreventWindowBlink()
    #endif      
    g_GfxHwnd = InitOpenGL(ScrWid,ScrHei)      
    
    #if __Main <> "LegoCAD"
      PreventWindowBlink(1) 
      ShowWIndow( g_GfxHwnd , SW_HIDE )
      SetWindowLong( g_GfxHwnd , GWL_EXSTYLE ,  GetWindowLong( g_GfxHwnd , GWL_EXSTYLE ) and (not WS_EX_LAYERED) )      
      'if bShowCollision then bShowCollision = false : View_ToggleKey()
    #endif
    
    scope
      dim as RECT tRcWnd = any , tRcCli = any
      GetWindowRect( g_GfxHwnd , @tRcWnd ): GetClientRect( g_GfxHwnd , @tRcCli )
      tRcWnd.right -= tRcWnd.left : tRcWnd.bottom -= tRcWnd.top
      tRcWnd.right -= tRcCli.right : tRcWnd.bottom -= tRcCli.Bottom
      #if __Main <> "LegoCAD"         
      SetWindowPos( g_GfxHwnd , NULL , g_tCfg.lGfxX,g_tCfg.lGfxY , _
        tRcWnd.right+g_tCfg.lGfxWid , tRcWnd.bottom+g_tCfg.lGfxHei , _
        SWP_NOMOVE or SWP_NOZORDER or SWP_NOACTIVATE )
      #else
        ShowWindow( g_GfxHwnd , SW_SHOW )
      #endif
    end scope    
    
    if hReadyEvent then SetEvent( hReadyEvent )
    SetEvent( g_hResizeEvent )
    
    #ifdef UseVBO
    redim as VertexStruct atModelTrigs() , atModelVtxLines()
    dim as GLuint iModelVBO, iBorderVBO
    dim as long iTrianglesCount, iBorderCount
    glGenBuffers(1, @iModelVBO) : glGenBuffers(1, @iBorderVBO)
    #else
    dim as GLuint iModel=-1,iBorders=-1      
    iModel   = glGenLists( 1 )
    iBorders = glGenLists( 2 )
    #endif      
    
    dim as single xMid,yMid,zMid , g_zFar
    dim as PartSize tSz
    dim as long g_PartCount , g_CurPart = -1
           
    dim as boolean bBoundingBox
    dim as boolean bLeftPressed,bRightPressed,bWheelPressed
    dim as byte bShiftPressed
    dim as long iFps
    dim as single fRotationX = 120 , fRotationY = 20
    dim as single fPositionX , fPositionY , fPositionZ , fZoom
    dim as single fCenterX , fCenterY , fCenterZ
    dim as long iWheel , iPrevWheel
    dim as long g_DrawCount , g_CurDraw = -1
    dim as long bRedraw = 1
    
    do until g_DoQuit 
    
      'puts("READY!")
      MutexLock( g_Mutex )
      if g_LoadFile > 0 then bRedraw += 2
      MutexUnlock( g_Mutex )
      
      're-create base view in case the window got resized
      if WaitForSingleObject( g_hResizeEvent , 0 )=0 then
        dim as RECT tRc : GetClientRect(g_GfxHwnd,@tRc)
        gfx.g_iCliWid = tRc.right : gfx.g_iCliHei = tRc.bottom
        ResizeOpengGL( gfx.g_iCliWid, gfx.g_iCliHei ) : bRedraw or= 1
      end if
      
      Dim e as fb.EVENT = any
      while (ScreenEvent(@e))
        Select Case e.type
        Case fb.EVENT_MOUSE_MOVE           
           var fZoomAcc = 1/-40 '1+(sqr(abs(fZoom)+1)/100) : fZoomAcc *= (fZoomAcc/2)
           var fX = e.dx*fZoomAcc , fY = e.dy*fZoomAcc
           if bLeftPressed  then fRotationX += (e.dx/8) : fRotationY += (e.dy/8) : bRedraw or= 1
           'if bRightPressed then fPositionX += (fX) * g_zFar/100 : fPositionY += (fY) * g_zFar/100 : bRedraw or= 1
           if bRightPressed then fPositionX += fX : fPositionY += fY : bRedraw or= 1
        case fb.EVENT_MOUSE_WHEEL
           bRedraw or= 1 : iWheel = e.z-iPrevWheel 
           fZoom = 2^(-iWheel/8) : if fZoom < 1 then fZoom = -iWheel
           'puts(">> " & fZoom)
        case fb.EVENT_MOUSE_BUTTON_PRESS
           if e.button = fb.BUTTON_MIDDLE then 
              iPrevWheel = iWheel : fZoom = 0
              fRotationX = 120 : fRotationY = 20
              fPositionX = 0 : fPositionY = 0 : bRedraw += 1
           end if
           if e.button = fb.BUTTON_LEFT   then bLeftPressed  = true
           if e.button = fb.BUTTON_RIGHT  then bRightPressed = true
        case fb.EVENT_MOUSE_BUTTON_RELEASE
           if e.button = fb.BUTTON_LEFT   then bLeftPressed  = false
           if e.button = fb.BUTTON_RIGHT  then bRightPressed = false      
        case fb.EVENT_KEY_PRESS           
        select case e.ascii
        case 8
          bRedraw or= 1
          if bShiftPressed then
             g_CurPart = -1 
             printf(!"g_CurPart = %i    \r",g_CurPart)
             dim as PartSize tSzTemp
             SizeModel( g_pLoadedModel , tSzTemp , g_CurPart )
             tSz = tSzTemp
          else
             g_CurDraw = -1
             printf(!"g_CurDraw = %i    \r",g_CurDraw)
          end if               
        case asc("="),asc("+")
          bRedraw or= 1
          if bShiftPressed then
             g_CurPart = ((g_CurPart+2) mod (g_PartCount+1))-1 
             printf(!"g_CurPart = %i    \r",g_CurPart)
             dim as PartSize tSzTemp
             SizeModel( g_pLoadedModel , tSzTemp , g_CurPart )
             tSz = tSzTemp
          else
             g_CurDraw = ((g_CurDraw+2) mod (g_DrawCount+1))-1
             printf(!"g_CurDraw = %i    \r",g_CurDraw)                     
          end if
        case asc("-"),asc("_")
          bRedraw or= 1
          if bShiftPressed then
             g_CurPart = ((g_CurPart+g_PartCount+1) mod (g_PartCount+1))-1 
             printf(!"g_CurPart = %i    \r",g_CurPart)
             dim as PartSize tSzTemp
             SizeModel( g_pLoadedModel , tSzTemp , g_CurPart )
             tSz = tSzTemp
          else
             g_CurDraw = ((g_CurDraw+g_DrawCount+1) mod (g_DrawCount+1))-1
             printf(!"g_CurDraw = %i    \r",g_CurDraw)
          end if               
        case asc("S")-asc("@") 'ctrl+S 'shadow
          if g_CurDraw >=0 then
             'FindFile(
             'FindShadowFile(
             with g_pLoadedModel->tParts(g_CurDraw)
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
             with g_pLoadedModel->tParts(g_CurDraw)
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
        case fb.SC_F5     : if g_LoadFile = -2 then LoadFile( g_sFileName ) : bRedraw or= 1
        case fb.SC_LSHIFT : bShiftPressed or= 1
        case fb.SC_RSHIFT : bShiftPressed or= 2
        case fb.SC_TAB    : bBoundingBox = not bBoundingBox : bRedraw or= 1
        case fb.SC_SPACE  
          bShowCollision = not bShowCollision : bRedraw or= 1
          #ifdef meView_ShowCollision
            Menu.MenuState( g_WndMenu,meView_ShowCollision, iif(Viewer.bShowCollision,MFS_CHECKED,0) )
            g_tCfg.bGfxCollision = (Viewer.bShowCollision<>0)
          #endif
        case fb.SC_DELETE
          if bShiftPressed then
            iPrevWheel = iWheel : fZoom = 0
            fRotationX = 120 : fRotationY = 20
            fPositionX = 0 : fPositionY = 0  : bRedraw += 1
          end if
        end select
        case fb.EVENT_KEY_RELEASE
           select case e.scancode
           case fb.SC_LSHIFT : bShiftPressed and= (not 1)
           case fb.SC_RSHIFT : bShiftPressed and= (not 2)
           end select
        case fb.EVENT_WINDOW_CLOSE
           #ifdef menu
           menu.Trigger( meView_ToggleGW ) 'hide GFX window
           #endif
        end select
      wend   
            
      if bShowCollision andalso g_iCollisions<>0 andalso instr(g_sFileName,".dat")=0 then
        static as double dLastTime : if abs(timer-dLastTime) > .25 then dLastTime = timer : if bRedraw=0 then bRedraw=1
      end if
      
      if IsWindowVisible( g_GfxHwnd ) = 0 orelse bRedraw=0 then            
        screencontrol fb.POLL_EVENTS : sleep 1,1 : continue do
      end if
        
      'WindowTitle(g_sFileName & " - Fps: " & iFps): iFps = 0
       
      var bLoaded = false
      MutexLock( g_Mutex )
      if g_LoadFile > 0 then
        if g_pCollisionThread then ThreadWait(g_pCollisionThread):g_pCollisionThread=0
        puts("Loading file")
        Try()
           do            
              g_LoadFile = -g_LoadFile
              if g_pLoadedModel then 'cleanup previous loaded model/lists (leaking shadow?)
                 FreeModel( g_pLoadedModel )
                 '#ifndef UseVBO
                 '   if iModel >=0 then glDeleteLists( iModel , 1 ) : iModel = -1
                 '   if iBorders >=0 then glDeleteLists( iBorders , 2 ) : iBorders = -1
                 '#endif
              end if 
              g_TotalLines = 0 : g_TotalOptis = 0 : g_TotalTrigs = 0 : g_TotalQuads = 0
              static as string sPrevFilename                  
              if len(g_sGfxFile) then g_pLoadedModel = LoadModel( strptr(g_sGfxFile) , g_sFileName )                  
              if g_pLoadedModel = NULL then exit do 'failed to load
              
              #ifdef UseVBO
                 GenArrayModel( g_pLoadedModel , atModelTrigs()     , false )
                 iTrianglesCount = ubound(atModelTrigs)+1   
                 glBindBuffer(GL_ARRAY_BUFFER, iModelVBO)
                 glBufferData(GL_ARRAY_BUFFER, iTrianglesCount*sizeof(VertexStruct), @atModelTrigs(0)     , GL_STATIC_DRAW)
                 erase( atModelTrigs )
                 GenArrayModel( g_pLoadedModel , atModelVtxLines() , true ) ',, -2 )
                 iBorderCount = ubound(atModelVtxLines)+1
                 glBindBuffer(GL_ARRAY_BUFFER, iBorderVBO)
                 glBufferData(GL_ARRAY_BUFFER, iBorderCount*sizeof(VertexStruct), @atModelVtxLines(0) , GL_STATIC_DRAW)
                 erase( atModelVtxLines )                     
              #else                     
                 glNewList( iModel ,  GL_COMPILE ) 'GL_COMPILE_AND_EXECUTE
                 RenderModel( g_pLoadedModel , false )
                 glEndList()                     
                 glNewList( iBorders ,  GL_COMPILE )
                 RenderModel( g_pLoadedModel , true )
                 glEndList()
                 glNewList( iBorders+1 ,  GL_COMPILE )
                 RenderModel( g_pLoadedModel , true , , -2 )
                 glEndList()
              #endif
                                                  
              var bResetAttributes = sPrevFilename <> g_sFileName
              if bResetAttributes then
                 fZoom = 0 : fRotationX = 120 : fRotationY = 20
                 iWheel = 0 : iPrevWheel = 0 
                 sPrevFilename = g_sFileName
              end if
              
              g_PartCount = 0 : g_DrawCount = g_pLoadedModel->iPartCount
              g_CurPart = -1 : g_CurDraw = -1
              SizeModel( g_pLoadedModel , tSz , , g_PartCount )
              with tSz
                xMid = (.xMin+.xMax)/2 : yMid = (.yMin+.yMax)/2 : zMid = (.zMin+.zMax)/2                
                var dx = .xMax-xMid , dy = .yMax-yMid , dz = .zMax-zMid
                var radius = Sqr(dx*dx + dy*dy + dz*dz)                
                '' Adjust radius by your scale factor (1/20 = 0.05)
                var scaledRadius = radius * 0.05 , fov = 45.0
                '' Distance to fit the scaled model in a 45-degree FOV
                g_zFar = scaledRadius / Sin((fov * 0.5) * (PI / 180.0))
                if g_zFar < 20 then g_zFar = 20
                
                #if 0
                  g_zFar = abs(xMid-.xMin)  
                  #define Chk(_Axis,_Suffix) if abs(_Axis##Mid-._Axis##_Suffix) > g_zFar then g_zFar = abs(_Axis##Mid-._Axis##_Suffix)
                  #macro Chk2(_Axis)
                    Chk(_Axis,Min)
                    Chk(_Axis,Max)
                  #endmacro 
                  Chk(x,Max)
                  Chk2(y)
                  Chk2(z)
                  g_zFar *= 3+((1/sqr(g_zFar)*3))
                  if g_zFar < 400 then g_zFar = 400
                #endif
                
                #if 1 'def ViewerShowInfo
                    printf(!"X %f > %f (%g ldu)\n",.xMin,.xMax,(.xMax-.xMin))
                    printf(!"Y %f > %f (%g ldu)\n",.yMin,.yMax,(.yMax-.yMin))
                    printf(!"Z %f > %f (%g ldu)\n",.zMin,.zMax,(.zMax-.zMin))
                    printf(!"Far = %f\n",g_zFar)
                    printf(!"Lines: %i - Optis: %i - Trigs: %i - Quads: %i - Verts: %i\n", _
                       g_TotalLines , g_TotalOptis , g_TotalTrigs , g_TotalQuads , _
                       g_TotalLines*2+g_TotalOptis*2+g_TotalTrigs*3+g_TotalQuads*4 _
                    )
                #endif
                if bResetAttributes then
                  'fPositionX = 0 '((.xMin + .xMax)\-2)-.xMin
                  'fPositionY = (.yMin + .yMax)\-2
                  fPositionX = 0 '((.xMax+.xMin)\-2) '-.xMin
                  fPositionY = 0 '((.yMax+.yMin)\2) '+.yMin
                  fPositionZ = -1 '(.zMax-.zMin) 'abs(.zMax)-abs(.zMin)
                  'fPositionZ = sqr(fPositionZ)*-40
                end if
              end with
              
              g_iCollisions = 0
              g_pCollisionThread = ThreadCreate( @CollisionThread , @bRedraw )
              
              bLoaded = true
              exit do 'loaded fine
              
           loop
        Catch()
           LogError("Viewer.LoadFile crashed!!!")               
        EndCatch()
        EndTry()            
        puts("File loaded")
        WindowTitle( g_sFileName )
      end if
      MutexUnlock( g_Mutex )  
       
      dim as double dRendertime = timer
      
      glClear GL_COLOR_BUFFER_BIT OR GL_DEPTH_BUFFER_BIT      
      glLoadIdentity()
      
      if g_pLoadedModel=0 then flip: continue do
      
      '' 2. "Zoom" - Move the camera back //'' Use the calculated autoZoomDist + your manual fZoom offset
      glTranslatef(0, 0, -(g_zFar+fZoom))      
      '' 3. User Panning (Optional)
      glTranslatef(-fPositionX, fPositionY, fPositionZ)      
      '' 4. Rotation (Now happens around the origin 0,0,0)
      glRotatef(fRotationY, 1, 0, 0) 
      glRotatef(fRotationX, 0, 1, 0)      
      '' 5. Scale the model 
      glScalef(1/-20, 1/-20, 1/20)      
      '' 6. Center the model (Move its calculated center to 0,0,0)
      glTranslatef(-xMid, -yMid, -zMid)      
                       
      'glPushMatrix()      
      'glDisable( GL_LIGHTING )
      
      static as long OldDraw = -1
      Try()
        if g_CurDraw < 0 then
           #ifdef UseVBO
              DrawColorVBO( iModelVBO , GL_TRIANGLES , iTrianglesCount )
           #else
              glCallList(	iModel )
           #endif
           OldDraw = -1
        else
           RenderModel( g_pLoadedModel , false , , g_CurDraw )
           RenderModel( g_pLoadedModel , true , , g_CurDraw )
           
           scope 'Render Snap IDs
              static as PartSnap tSnapID
              if g_CurDraw <> -1 andalso OldDraw <> g_CurDraw then                        
                 var pSubPart = g_tModels( g_pLoadedModel->tParts(g_CurDraw)._1.lModelIndex ).pModel                  
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
                 with g_pLoadedModel->tParts(g_CurDraw)._1
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
           
           'SnapModel( g_pLoadedModel , tSnap , g_CurDraw )      
        end if            
        #ifdef UseVBO         
           if g_CurDraw < 0 then                  
              DrawColorVBO( iBorderVBO , GL_LINES , iBorderCount )         
           else
              glColor4f(.5,.5,.5,.25)
              DrawVBO( iBorderVBO , GL_LINES , iBorderCount )         
           end if
        #else
           glCallList(	iBorders-(g_CurDraw>=0) )
        #endif
        
        Catch()
           LogError("Crashed at rendering!!!")
        EndCatch()
      EndTry()
      
      glEnable( GL_LIGHTING )
      
      #ifdef DebugShadow
        dim as PartSnap tSnap = any
        static as byte bOnce         
        SnapModel( g_pLoadedModel , tSnap , true )
      #endif
      
      #if 0
        glEnable( GL_POLYGON_STIPPLE )
        
        'SnapModel( g_pLoadedModel , tSnap )
        
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
      
      DrawCollisionDebug()
      
      if bBoundingBox then
        glColor4f(0,1,0,.25)
        with tSz
           DrawLimitsCube( .xMin-1,.xMax+1 , .yMin-1,.yMax+1 , .zMin-1,.zMax+1 )      
        end with
      end if
      
      if bShowCollision andalso g_iCollisions<>0 andalso instr(g_sFileName,".dat")=0 then
        glEnable( GL_POLYGON_STIPPLE )      
        static as ulong aStipple(32-1)
        dim as long iMove = (timer*8) and 7
        for iY as long = 0 to 31         
           var iN = iif(iY and 1,&h1414141414141414ll,&h4141414141414141ll)         
           aStipple(iY) = iN shr ((iY+iMove) and 7)
        next iY
        glPolygonStipple(	cptr(glbyte ptr,@aStipple(0)) )
        if (iMove and 2) then glColor4f(1,0,0,1) else glColor4f(0,0,0,1)
        for I as long = 0 to g_iCollisions-1   
           with g_Viewer_atCollision(I)
              DrawLimitsCube( .xMin-1,.xMax+1 , .yMin-1,.yMax+1 , .zMin-1,.zMax+1 )
           end with
        next I
        glDisable( GL_POLYGON_STIPPLE )      
      end if
      glDepthMask (GL_TRUE)
      
      'glPopMatrix()
      flip : if bRedraw > 0 then bRedraw -= 1
      if bLoaded then flip
      'printf(!"%lf\n",timer)
      
      'var dTime = (timer-dRendertime)*1000
      'printf(!"Render time=%1.2fms (%i fps)   \r",dTime,cint(int(1000/dTime)))
     
    loop
    
    puts("ending gfx")
    Screen 0, , , fb.GFX_SCREEN_EXIT
    mutexdestroy( g_Mutex )
      
  end sub
end namespace
