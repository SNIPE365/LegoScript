sub SnapAddClutch( tSnap as PartSnap , iCnt as long , byval tPV as SnapPV = (0) )
   with tSnap
      for N as long = 0 to iCnt-1
        .lClutchCnt += 1
        .pClutch = reallocate(.pClutch,sizeof(tPV)*.lClutchCnt)
        .pClutch[.lClutchCnt-1] = tPV        
      next N
   end with
end sub 

#ifndef __NoRender
static shared as ulong MaleStipple(32-1), FemaleStipple(32-1)
for iY as long = 0 to 31         
   MaleStipple(iY)   = iif(iY and 1,&h55555555,&hAAAAAAAA)
   FeMaleStipple(iY) = iif(iY and 1,&hAAAAAAAA,&h55555555)
next iY

static shared as single g_fNX=-.95,g_fNY=.95

function ndcToWorld(x as single, y as single, z as single , byref OutX as single, byref OutY as single, byref OutZ as single) as long
    

    dim as double modelview(15)=any
    dim as double projection(15)=any
    dim as integer viewport(3)=any
    glGetDoublev(GL_MODELVIEW_MATRIX, @modelview(0))
    glGetDoublev(GL_PROJECTION_MATRIX, @projection(0))
    glGetIntegerv(GL_VIEWPORT, @viewport(0))

    dim as double winX = (x + 1) * 0.5 * viewport(2)
    dim as double winY = (y + 1) * 0.5 * viewport(3)
    dim as double winZ = z

    dim as double objX=any, objY=any, objZ=any
    gluUnProject(winX, winY, winZ, @modelview(0), @projection(0), @viewport(0), @objX, @objY, @objZ)
    OutX = objX : OutY = ObjY : OutZ = ObjZ
    
    return 1
end function

function worldToNDC(x as single, y as single, z as single, byref ndcX as single, byref ndcY as single) as long
    dim as double modelview(15)=any
    dim as double projection(15)=any
    dim as integer viewport(3)=any
    dim as double winX=any, winY=any, winZ=any

    glGetDoublev(GL_MODELVIEW_MATRIX, @modelview(0))
    glGetDoublev(GL_PROJECTION_MATRIX, @projection(0))
    glGetIntegerv(GL_VIEWPORT, @viewport(0))

    ' Use gluProject to get window coordinates
    if gluProject(x, y, z, @modelview(0), @projection(0), @viewport(0), @winX, @winY, @winZ) = GL_TRUE then
        ' Convert window coords to NDC (-1 to 1)
        ndcX = (winX / viewport(2)) * 2.0 - 1.0
        ndcY = ((winY / viewport(3)) * 2.0 - 1.0)
        return 1 ' success
    else
        return 0 ' failure
    end if
end function


sub DrawMaleShape( fX as single , fY as single , fZ as single , fRadius as single , fLength as single , bRound as byte , sName as string = "M?" )
   'dim as single fVec(2) = {fX_,fY_,fZ_}
   'MultiplyMatrixVector( @fVec(0) )
   '#define FX fVec(0)
   '#define FY fVec(1)
   '#define FZ fVec(2)
   
   if g_bRenderConnector then
      glPushMatrix()   
      glLoadCurrentMatrix()
      glTranslatef( fX , fY-fLength/2.0 , fZ )      
      glColor3f( 1 , 1 , 0 )
      
      #if 0
         glColor4f( 0 , 0 , 0 , .5 )   
         glLineWidth( 2 )
         
         #if 0
            dim as single fOX,fOY,fOZ   
            ndcToWorld( g_fNX , g_fNY , 0 , fOX,fOY,fOZ )
            g_fNX += .05
               
            glBegin(GL_LINES)
            glVertex3D(0,0,0)   
            glVertex3D(fOX,fOY,fOZ)   
            glEnd()
         #else
            dim as single fOX,fOY , fNX,fNY,fNZ
            worldToNDC( 0,0,0 , fOX , fOY )
            
            glMatrixMode(GL_PROJECTION)
            glPushMatrix()
            glLoadIdentity()
            glOrtho(-1, 1, -1, 1, -1, 1)      
            glMatrixMode(GL_MODELVIEW)
            glPushMatrix()
            glLoadIdentity()      
            glDisable(GL_DEPTH_TEST)
            
            dim as single fA = atan2( fOY , fOX )
            dim as single fPX, fPY
            fPX = cos(fA)*8 : fPY = sin(fA)*8
            glBegin(GL_LINES)
            glVertex3D(fPX,fPY,0)      
            glVertex3D(fOX,fOY,0)
            glEnd()
            
            glEnable(GL_DEPTH_TEST)
            glPopMatrix() ' MODELVIEW
            glMatrixMode(GL_PROJECTION)
            glPopMatrix()
            glMatrixMode(GL_MODELVIEW)
            
         #endif
         
         glLineWidth( 1 )
      #endif      
      glDrawText( sName ,0,-fLength,0 , fRadius/len(sName),fRadius , true )
      
      glPopMatrix() 'ignore display of shape
   end if
   if g_bRenderShadow=false then exit sub
   
   glEnable( GL_POLYGON_STIPPLE )
   glRotatef( 90 , 1,0,0 )      
   glPolygonStipple(	cptr(glbyte ptr,@MaleStipple(0)) )   
   
   if bRound then
      glScalef( 8/7 , 8/7 , (fLength/fRadius)*(5/7) ) 'cylinder
      glutSolidSphere( fRadius , 18 , 7 ) 'male round (.5,.5,N\2)
   else
      glScalef( 2 , 2 , (fLength/fRadius) ) 'square
      glutSolidCube(fRadius) 'male square (1,1,N)
   end if
   
   glDisable( GL_POLYGON_STIPPLE )
   
   glPopMatrix()
   
end sub

sub DrawFemaleShape( fX as single , fY as single , fZ as single , fRadius as single , fLength as single , bRound as byte , sName as string = "F?" )   
   'dim as single fVec(2) = {fX_,fY_,fZ_}
   'MultiplyMatrixVector( @fVec(0) )
   '#define FX fVec(0)
   '#define FY fVec(1)
   '#define FZ fVec(2)   
   
   if g_bRenderConnector then
      glPushMatrix()   
      
      glLoadCurrentMatrix()
      glTranslatef( fX , fY-fLength/2.0 , fZ )   
      
      glColor3f( 1 , 0 , 0 )
      
      glRotatef( 180 , 1,0,0 )
      glDrawText( sName ,0,-abs(fLength*.5),0 , fRadius/len(sName) , fRadius , true )
      glRotatef( 180 , 1,0,0 )
      
      glPopMatrix() : exit sub 'ignore display of shape
   end if
   if g_bRenderShadow=false then exit sub
   glRotatef( 90 , 1,0,0 )
   glEnable( GL_POLYGON_STIPPLE )
   glPolygonStipple(	cptr(glbyte ptr,@FeMaleStipple(0)) )      
   if bRound then      
      glScalef( 1 , 1 , fLength )      
      glutSolidTorus( 0.5 , fRadius , 18 , 18 ) 'female round? (.5,.5,N*8)
   else
      glRotatef( 45 , 0,0,1 ) 'square
      glScalef( 1 , 1 , fLength )
      glutSolidTorus( 0.5 , fRadius , 18 , 4  ) 'female "square" (.5,.5,N*8)
   end if   
   glPopMatrix()
   glDisable( GL_POLYGON_STIPPLE )
end sub
#endif


sub SortSnap( tSnap as PartSnap )   
   #macro SortLogic( _ConnName )
      do
         var bDidSort = 0
         for N as long = 0 to .l##_ConnName##Cnt-2
            var fW0 = .p##_ConnName[N+0].tPos.Y*(100^3) + .p##_ConnName[N+0].tPos.Z*(100^2) - .p##_ConnName[N+0].tPos.X
            var fW1 = .p##_ConnName[N+1].tPos.Y*(100^3) + .p##_ConnName[N+1].tPos.Z*(100^2) - .p##_ConnName[N+1].tPos.X
            if fW1 > fW0 then swap .p##_ConnName[N],.p##_ConnName[N+1]: bDidSort=1 : continue for
         next N
         if bDidSort=0 then exit do
      loop
   #endmacro
   with tSnap
      SortLogic( stud )
      SortLogic( clutch )
   end with
end sub

'sub RenderModel( pPart as DATFile ptr , iBorders as long , uCurrentColor as ulong = &h70605040 , lDrawPart as long = -1 , uCurrentEdge as ulong = 0 DebugPrimParm )
#if 0

sub SnapModel( pPart as DATFile ptr , tSnap as PartSnap , lDrawPart as long = -2 , pRoot as DATFile ptr = NULL )   
   #ifdef __NoRender
   lDrawPart=-2   
   #endif
   static as integer iMale=0 , iFemale=0   
   if pRoot = NULL then 
      pRoot = pPart : iMale=0 : iFemale=0 : 'puts("-----------------")
      memset( @tSnap.lStudCnt , 0 , offsetof(PartSnap,pStud) )
   end if
   with *pPart
      if .tSize.zMax = .tSize.zMin then
         dim as PartSize tSz : SizeModel( pPart , tSz )
         .tSize = tSz
         '.fSizeX = tSz.xMax - tSz.xMin
         '.fSizeY = tSz.yMax - tSz.yMin
         '.fSizeZ = tSz.zMax - tSz.zMin
      end if
      if .iShadowCount then
         #ifndef __Tester
            #ifdef DebugShadow
               if lDrawPart=-2 then printf(!"Shadow Entries=%i (%s)\n",.iShadowCount,GetPartName(pPart))
            #endif
         #endif
         
         var iIdent = 2, iPrevRec = 0         
         'var pMat = @tMatrixStack(g_CurrentMatrix)
         'var fYScale = (pMat->fScaleY) , YScale = cint(fYScale)
         'const fYScale = 1 , YScale = 1
         
         for N as long = 0 to .iShadowCount-1
            with .paShadow[N]
               dim as single fPX = .fPosX , fPY = .fPosY , fPZ = .fPosZ
               var pG = @.tGrid 'grid xCnt,zCnt,xStep,zStep
               var pMat = @tMatrixStack(g_CurrentMatrix)
               var xCnt = abs(.tGrid.xCnt)-1 , zCnt = abs(.tGrid.zCnt)-1
               if .bFlagHasGrid then
                  if .tGrid.xCnt < 0 then fPX += (xCnt*.tGrid.Xstep)/-2 '.tGrid.Xstep/-2
                  if .tGrid.zCnt < 0 then fpZ += (zCnt*.tGrid.Zstep)/-2 '.tGrid.ZStep/-2
               end if
               select case .bType
               case sit_Include
                  #ifndef __Tester
                  if lDrawPart>-2 then puts("sit_Include")
                  #endif
                  iIdent += 2
               case sit_Cylinder
                  static as zstring ptr pzCaps(...)={@"none",@"one",@"two",@"A",@"B"}
                  if iPrevRec>.bRecurse then iIdent -= 2
                  iPrevRec=.bRecurse '4
                  
                  dim as single ptr pMatOri = NULL
                  #if 0
                     if .bFlagOriMat then 
                        pMatOri = @.fOri(0)
                        puts("with origin")
                     else
                        puts("without origin")
                     end if
                  #endif
                  
                  #ifndef __Tester                   
                  #ifndef __NoRender
                  if lDrawPart>-2 then                     
                     if .bFlagOriMat then
                        dim as single fMatrix(15) = { _                           
                          .fOri(0) , .fOri(3) , .fOri(6) , 0 , _ 'X scale ,    0?   ,   0?    , 0 
                          .fOri(1) , .fOri(4),  .fOri(7) , 0 , _ '  0?    , Y Scale ,   0?    , 0 
                          .fOri(2) , .fOri(5) , .fOri(8) , 0 , _ '  0?    ,    0?   , Z Scale , 0 
                            0      ,    0    ,    0     , 1 }
                          '-.fPosX  ,  -.fPosY , -.fPosZ  , 1 }   ' X Pos  ,  Y Pos  ,  Z Pos  , 1 
                        PushAndMultMatrix( @fMatrix(0) )
                        '#ifndef __Tester
                        puts("Origin!")
                        '#endif
                     end if
                     
                     'var pMat = @tMatrixStack(g_CurrentMatrix)
                     'var fYScale = (pMat->fScaleY) , YScale = cint(fYScale)
                     
                     '#define __Position__ fCenX+fOffX+.fPosX+pMat->fPosX , fCenY+.fPosY+pMat->fPosY , fCenZ+fOffZ+.fPosZ+pMat->fPosZ
                     #define __Position__ fCenX+fOffX+.fPosX , fCenY+.fPosY , fCenZ+fOffZ+.fPosZ
                     var xCnt=0 , zCnt=0 , fStartX=0f , fOffZ=0f
                     if .bFlagHasGrid then 
                        xCnt = abs(.tGrid.xCnt)-1 : zCnt = abs(.tGrid.zCnt)-1
                        if .tGrid.xCnt < 0 then fStartX = ((xCnt)*.tGrid.Xstep)/-2 '.tGrid.Xstep/-2
                        if .tGrid.zCnt < 0 then fOffZ   = ((zCnt)*.tGrid.Zstep)/-2 '.tGrid.ZStep/-2
                     end if
                     for iZ as long = 0 to zCnt
                        var fOffX = fStartX
                        for iX as long = 0 to xCnt
                           for I as long = 0 to .bSecCnt-1
                              var p = @.tSecs(I)                        
                              dim as byte bRound = false
                              select case p->bShape
                              case sss_Round  : bRound  = true
                              case sss_Square : bRound  = false
                              case else      : continue for 'skip
                              end select  
                              dim as single fCenX,fCenY,fCenZ
                              var pMat = @tMatrixStack(g_CurrentMatrix)
                              if .bFlagCenter then                                 
                                 'fCenY = (p->bLength*fYScale)/-2
                                 'fCenY = (p->bLength*(pMat->fScaleY))/-2
                                 fCenY = p->bLength/-2
                                 fCenZ += .fPosY
                                 #ifndef __Tester
                                 puts("Center flag")
                                 #endif
                              else
                                 'continue for
                              end if                              
                              if .bFlagMale then                                 
                                 'if bDraw=2 then
                                    'printf( !"%g %g %g\n" , __Position__ )
                                    'with tMatrixStack(g_CurrentMatrix)
                                    '   printf(!"[ %g %g %g %g\n",.m( 0),.m( 1),.m( 2),.m( 3))
                                    '   printf(!"  %g %g %g %g\n",.m( 4),.m( 5),.m( 6),.m( 7))
                                    '   printf(!"  %g %g %g %g\n",.m( 8),.m( 9),.m(10),.m(11))
                                    '   printf(!"  %g %g %g %g ]\n",.m(12),.m(13),.m(14),.m(15))
                                    'end with
                                 'end if                                 
                                 'if lDrawPart <> -2 then 
                                    iMale += 1
                                    DrawMaleShape( __Position__ , p->wFixRadius/100 , p->bLength , bRound , "" & iMale )
                                 'end if
                              else
                                 'if lDrawPart <> -2 then 
                                    iFemale += 1
                                    DrawFemaleShape( __Position__ , p->wFixRadius/100 , p->bLength , bRound , "" & iFemale ) '*(pMat->fScaleY)
                                 'end if
                              end if
                              
                           next I
                           fOffX += .tGrid.Xstep
                        next iX
                        fOffZ += .tGrid.Zstep
                     next iZ                     
                     if .bFlagOriMat then PopMatrix()
                  else
                  #endif
                  #ifdef __NoRender
                  if 1 then
                  #endif
                     '#define __Position__ .fPosX+pMat->fPosX , .fPosY+pMat->fPosY , .fPosZ+pMat->fPosZ
                     #define __Position__ .fPosX , .fPosY , .fPosZ
                     #ifdef DebugShadow
                        printf(!"%sSecs=%i Gender=%s Caps=%s HasGrid=%s GridX=%i GridZ=%i (Pos=%g,%g,%g)",space(iIdent), _
                        .bSecCnt , iif(.bFlagMale,"M","F") , pzCaps(.bCaps) , iif(.bFlagHasGrid,"Yes","No") , _
                        abs(.tGrid.xCnt) , abs(.tGrid.zCnt) , __Position__ )
                     #endif
                  end if
                  #endif                  
                  for I as long = 0 to .bSecCnt-1
                     static as zstring ptr pzSecs(...)={@"Invalid",@"Round",@"Axle",@"Square",@"FlexPrev",@"FlexNext"}                     
                     with .tSecs(I)
                        #ifndef __Tester                            
                           #ifdef DebugShadow
                              var pMat = @tMatrixStack(g_CurrentMatrix)
                              if lDrawPart=-2 then printf(" %s(%g %g)",pzSecs(.bShape),.wFixRadius/100,.bLength*(pMat->fScaleY))
                           #endif
                        #endif
                     end with
                  next I      
                  #ifndef __Tester
                     #ifdef DebugShadow
                        if lDrawPart=-2 then puts("")
                     #endif
                  #endif                  
                  
                  '>>>>> Detect Shape type (stud,clutch,alias,etc...) >>>>>
                  scope
                     var iConCnt = 1 , bConType = spUnknown , bSecs = .bSecCnt , bSides = 1
                     select case .bCaps
                     case sc_None : bSides = 2
                     case sc_One  : bSides = 1
                     #ifndef __Tester
                     case sc_Two  : if lDrawPart=-2 then puts("!!!!! CHECK TWO CAPS!!!!!")
                     #endif
                     end select
                     
                     'negative xCnt/zCnt are "centered"
                     if .bFlagHasGrid then iConCnt = abs(.tGrid.xCnt)*abs(.tGrid.zCnt)
                     if .bFlagMale then 
                        var pMat = @tMatrixStack(g_CurrentMatrix)
                        var iIgnore = 0
                        #ifndef __Tester
                        if iConCnt > 1 andalso lDrawPart=-2 then puts("!!!!!! MALE GRID FOUND !!!!!")
                        #endif
                        bConType = spStud
                        for I as long = 0 to .bSecCnt-1
                           select case .tSecs(I).bShape
                           case sss_FlexNext, sss_FlexPrev : iIgnore += 1
                           end select
                        next I                           
                        for I as long = 0 to .bSecCnt-1
                           if .tSecs(I).bLength = 1 then bSecs -= 1 : continue for 'ignore length=1 sections
                           select case .tSecs(I).bShape
                           case sss_Axle
                              if lDrawPart=-2 then 
                                 DbgConnect(!"Axle += %i\n",iConCnt)
                              end if
                              tSnap.lAxleCnt += iConCnt : bSecs -= 1 'AXLEHOLE //bConType = spAxleHole: exit for 
                              'puts("Axle " & bSecs)
                           case sss_FlexNext
                              bSecs -= 1 'other side of pin?
                              'puts("Pin Mirror " & bSecs)
                           case sss_FlexPrev
                              if lDrawPart=-2 then 
                                 DbgConnect(!"Pin += %i\n",iConCnt)
                              end if
                              ''tSnap.lPinCnt += iConCnt 
                              bSecs -= 1  'PIN // bConType = spPin : exit for
                              'bSecs -= 1: 'continuation of the pin must be ignored
                              'puts("Pin" & bSecs)
                           case sss_Round                              
                              if .tSecs(I).wFixRadius = 800 then
                                 bSecs -= 1 'STOPPER? Ignoring it for now
                                 'puts("Stopper" & bSecs)
                              elseif .tSecs(I).wFixRadius = 400 then
                                 if lDrawPart=-2 then 
                                    DbgConnect(!"Bar += %i\n",iConCnt)
                                 end if
                                 ''tSnap.lBarCnt += iConCnt 
                                 bSecs -= 1 'BARHOLE
                                 'puts("Bar" & bSecs)
                              elseif .tSecs(I).wFixRadius = 600 then 'stud
                                 if lDrawPart<>-3 then '=-2
                                    DbgConnect(!"Stud += %i\n",iConCnt)
                                    'var p = pPart
                                    with *pMat
                                       'printf(!"stud ori: %p\n",pMatOri)
                                       'puts("Male: " & iMale)
                                       SnapAddStud( tSnap , iConCnt , type(fPX+.fPosX , fPY+.fPosY , fPZ+.fPosZ) )
                                    end with
                                 end if                                 
                                 bSecs -= 1 'stud
                              else
                                 if iIgnore then
                                    iIgnore -= 1 : bSecs -= 1
                                    '#ifndef __Tester
                                    'puts("Ignored (pin part)" & bSecs)
                                    '#endif
                                 else
                                    #ifndef __Tester
                                    if lDrawPart=-2 then puts("Unknown male round cylinder?")
                                    #endif
                                 end if
                              end if
                           case else
                              if lDrawPart=-2 then puts("Unknown male?")
                           end select
                        next I
                     else 'females can be BARHOLE / PINHOLE / CLUTCHES / ALIAS
                        bConType = spClutch
                        if .bFlagSlide then 'PINHOLE / AXLEHOLE / BARHOLE
                           'if iConCnt > 1 then puts("!!!!! GRID PINHOLE FOUND !!!!!")
                           'bConType = spPinHole
                           var iMaybePins = 0
                           dim as byte bDidAxleHole,bDidClutch,bDidBarHole
                           for I as long = 0 to .bSecCnt-1                              
                              if .tSecs(I).bLength*((pMat->fScaleY)) = 1 then
                                 #ifndef __Tester
                                 if lDrawPart=-2 then puts("Length 1 section ignored")
                                 #endif
                                 bSecs -= 1 : continue for 'ignore length=1 sections
                              end if
                              select case .tSecs(I).bShape 
                              case sss_Axle                                 
                                 if lDrawPart=-2 then 
                                    DbgConnect(!"AxleHole += %i (Axle slide)\n",iConCnt*bSides)
                                 end if
                                 if bDidAxleHole=0 then bDidAxleHole=1 '': tSnap.lAxleHoleCnt += iConCnt*bSides 
                                 'AXLEHOLE //bConType = spAxleHole: exit for 
                                 'if there's an axlehole then it can't be a pinhole, and it can't have dual clutches
                                 bSecs -= 1 : iMaybePins=-999 : bSides = 1
                              case sss_Square   
                                 if lDrawPart<>-3 then '=-2
                                    if bDidClutch=0 then
                                       bDidClutch=1
                                       with *pMat
                                          ''puts("Female: " & iFemale)
                                          SnapAddClutch( tSnap , iConCnt , type(fPX+.fPosX , fPY+.fPosY , fPZ+.fPosZ) )                                       
                                       end with
                                    end if
                                    DbgConnect(!"Clutch += %i (Square slide)\n",iConCnt)
                                    DbgConnect(!"BarHole += %i (Square slide)\n",iConCnt*bSides)
                                 end if
                                 'if bDidClutch=0  then bDidClutch=1  : tSnap.lClutchCnt  += iConCnt
                                 if bDidBarHole=0 then bDidBarHole=1 '': tSnap.lBarHoleCnt += iConCnt*bSides
                                 bSecs -= 1 'BARHOLE //bConType = spBarHole: exit for
                              case sss_Round                                 
                                 select case .tSecs(I).wFixRadius
                                 case 800: bSecs -= 1 '???? (anti-stopper??)
                                 case 600: iMaybePins += 1 
                                 case 400
                                    if lDrawPart-2 then 
                                       DbgConnect(!"BarHole += %i (Round slide)\n",iConCnt*bSides)
                                    end if
                                    if bDidBarHole=0 then bDidBarHole=1 '': tSnap.lBarHoleCnt += iConCnt*bSides 
                                    bSecs -= 1 'BARHOLE
                                 end select                                 
                              end select
                           next I
                           if iMaybePins>0 then 
                              if lDrawPart=-2 then
                                 DbgConnect(!"Clutch += %i (round slide from pin?)\n",iConCnt*iMaybePins*bSides )
                                 DbgConnect(!"PinHole += %i (round slide )\n", iConCnt*iMaybePins)
                                 #ifndef __Tester
                                 puts("ERROR: unimplemented clutches were not added")
                                 #endif
                              end if
                              'tSnap.lClutchCnt += iConCnt*iMaybePins*bSides 
                              ''tSnap.lPinHoleCnt += iConCnt*iMaybePins 
                              bSecs -= iMaybePins 'PINHOLE
                           end if
                        else 'BARHOLE / CLUTCH / KingPin (fat)
                           dim as byte bDidPinHole,bDidBarHole
                           for I as long = 0 to .bSecCnt-1                              
                              'if .tSecs(I).wFixRadius > 600 then bConType = spPinHole : exit for
                              select case .tSecs(I).bShape
                              case sss_Axle
                                 #ifndef __Tester
                                 if lDrawPart=-2 then puts("Axle hole without slide??????")
                                 #endif
                              case sss_FlexPrev
                                 if lDrawPart=-2 then 
                                    DbgConnect(!"PinHole += %i (FlexPrev)\n",iConCnt)
                                 end if
                                 if bDidPinHole=0 then bDidPinHole=1 '': tSnap.lPinHoleCnt += iConCnt 
                                 bSecs -= 1: 'bConType = spPinHole
                              case sss_Round 'barholes have radius of 4.0
                                 if .tSecs(I).wFixRadius = 400 then 
                                    if lDrawPart=-2 then 
                                       DbgConnect(!"BarHole += %i (Round)\n",iConCnt*bSides)
                                    end if
                                    if bDidBarHole=0 then bDidBarHole = 1 '': tSnap.lBarHoleCnt += iConCnt*bSides 
                                    bSecs -= 1 'bConType = spBarhole : exit for 'BARHOLE
                                 elseif .tSecs(I).wFixRadius = 600 then 'clutch?
                                    if lDrawPart<>-3 then  '=-2
                                       DbgConnect(!"Clutch += %i (Round)\n",iConCnt)
                                       with *pMat                                       
                                          for iGX as long = 0 to xCnt
                                             for iGZ as long = 0 to zCnt
                                                ''puts("Female: " & iFemale)
                                                SnapAddClutch( tSnap , 1 , type(fPX+.fPosX+iGX*pG->xStep , fPY+.fPosY , fPZ+.fPosZ+iGZ*pG->zStep) )
                                             next igZ
                                          next iGX
                                       end with
                                    end if
                                    bSecs -= 1                                    
                                 end if
                              end select
                           next I  
                           ''if bConType = spBarHole andalso .bCaps = sc_None then iConCnt *= 2 'dual for hollow
                        end if
                     end if
                     if lDrawPart=-2 then 
                        if bSecs < 0 then puts("ERROR: remaining section counter is negative")
                        if bSecs > 1 then puts("ERROR: Too many unhandled sections!")
                     end if
                     if bSecs > 0 then 'remaining sects (fallback)
                        select case bConType                           
                        case spStud    
                           if lDrawPart=-2 then 
                              'DbgConnect(!"Stud += %i (Fallback)\n",iConCnt)
                              #ifndef __Tester
                              printf(!"Stud += %i (Fallback {ignored})\n",iConCnt)
                              #endif
                           end if
                           ''tSnap.lStudCnt     += iConCnt
                           '#ifndef __Tester
                           'puts("!!! FALLBACK STUD !!!")
                           '#endif
                        case spClutch  
                           'printf(!"Sides=%i\n",bSides)
                           if lDrawPart<>-3 then '=-2
                              with *pMat
                                 'puts("Female: " & iFemale)
                                 SnapAddClutch( tSnap , iConCnt , type(fPX+.fPosX , fPY+.fPosY , fPZ+.fPosZ) )                                       
                              end with
                              DbgConnect(!"Clutch += %i (Fallback {ignored})\n",iConCnt)
                              #ifndef __Tester
                              if iConCnt > 1 then printf(!"WARNING: %i clutches added as fallback {ignored}\n",iConCnt)
                              #endif
                              'printf(!"Clutch += %i (Fallback)\n",iConCnt)
                           end if
                           
                           'tSnap.lClutchCnt   += iConCnt '*bSides 
                           
                           '#ifndef __Tester
                           'puts("!!! FALLBACK CLUTCH !!!")
                           '#endif
                        case spAlias   
                           if lDrawPart=-2 then 
                              DbgConnect(!"Alias += %i (Fallback {ignored})\n",iConCnt)
                           end if
                           ''tSnap.lAliasCnt    += iConCnt
                        case spBar     
                           if lDrawPart=-2 then 
                              DbgConnect(!"Bar += %i (Fallback {ignored})\n",iConCnt)
                           end if
                           ''tSnap.lBarCnt      += iConCnt
                        case spBarHole : tSnap.lBarHoleCnt  += iConCnt*bSides
                           if lDrawPart=-2 then 
                              DbgConnect(!"BarHole += %i (Fallback {ignored})\n",iConCnt)
                           end if
                        case spPin     '': tSnap.lPinCnt      += iConCnt 
                           if lDrawPart=-2 then 
                              DbgConnect(!"Pin += %i (Fallback {ignored})\n",iConCnt)
                           end if
                        case spPinHole 
                           if lDrawPart=-2 then 
                              DbgConnect(!"PinHole += %i (Fallback {ignored})\n",iConCnt)
                           end if
                           ''tSnap.lPinHoleCnt  += iConCnt
                           '#ifndef __Tester
                           'puts("!!! FALLBACK PINHOLE !!!")
                           '#endif
                        case spAxle
                           if lDrawPart=-2 then 
                              DbgConnect(!"Axle += %i (Fallback {ignored})\n",iConCnt)
                           end if
                           ''tSnap.lAxleCnt     += iConCnt
                        case spAxleHole
                           if lDrawPart=-2 then 
                              DbgConnect(!"AxleHole += %i (Fallback {ignored})\n",iConCnt)
                           end if
                           ''tSnap.lAxleHoleCnt += iConCnt
                        end select
                     end if
                  end scope
                  ' <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                  
               end select
            end with
         next N
      end if
      for N as long = 0 to .iPartCount-1         
         dim as byte bDoDraw
         if (lDrawPart=-1 orelse lDrawPart=N) then bDoDraw = -1 else bDoDraw = -3
         if lDrawPart=-2 then bDoDraw = -2
         with .tParts(N)            
            if .bType = 1 then 'we only care for includes
               'continue for
               with ._1
                  var pSubPart = g_tModels(.lModelIndex).pModel
                  
                  
                  dim as single fMatrix(15) = { _
                    .fA , .fD , .fG , 0 , _ 'X scale ,    0?   ,   0?    , 0 
                    .fB , .fE , .fH , 0 , _ '  0?    , Y Scale ,   0?    , 0 
                    .fC , .fF , .fI , 0 , _ '  0?    ,    0?   , Z Scale , 0 
                    .fX , .fY , .fZ , 1 }   ' X Pos  ,  Y Pos  ,  Z Pos  , 1 
                  
                  'var sName = *cptr(zstring ptr,strptr(g_sFilenames)+g_tModels(.lModelIndex).iFilenameOffset+6)
                  'puts(sName)                  
                  'for N as long = 0 to 15
                  '   printf("%f ",fMatrix(N))
                  '   if (N and 3)=3 then puts("")
                  'next N
                  
                  PushAndMultMatrix( @fMatrix(0) )                  
                  SnapModel( pSubPart , tSnap , bDoDraw , pRoot )
                  PopMatrix()
               end with               
            end if
         end with
      next N
   end with
end sub
#else

sub SnapModel( pPart as DATFile ptr , tSnap as PartSnap , pRoot as DATFile ptr = NULL )      
   static as integer iMale=0 , iFemale=0   
   if pRoot = NULL then 
      pRoot = pPart : iMale=0 : iFemale=0 : 'puts("-----------------")
      memset( @tSnap.lStudCnt , 0 , offsetof(PartSnap,pStud) )
   end if
   with *pPart
      if .tSize.zMax = .tSize.zMin then
         dim as PartSize tSz : SizeModel( pPart , tSz )
         .tSize = tSz
         '.fSizeX = tSz.xMax - tSz.xMin
         '.fSizeY = tSz.yMax - tSz.yMin
         '.fSizeZ = tSz.zMax - tSz.zMin
      end if
      if .iShadowCount then
         #ifndef __Tester
            #ifdef DebugShadow
               if lDrawPart=-2 then printf(!"Shadow Entries=%i (%s)\n",.iShadowCount,GetPartName(pPart))
            #endif
         #endif
         
         var iIdent = 2, iPrevRec = 0         
         'var pMat = @tMatrixStack(g_CurrentMatrix)
         'var fYScale = (pMat->fScaleY) , YScale = cint(fYScale)
         'const fYScale = 1 , YScale = 1
         
         for N as long = 0 to .iShadowCount-1
            with .paShadow[N]
               dim as single fPX = .fPosX , fPY = .fPosY , fPZ = .fPosZ
               var pG = @.tGrid 'grid xCnt,zCnt,xStep,zStep
               var pMat = @tMatrixStack(g_CurrentMatrix)
               var xCnt = abs(.tGrid.xCnt)-1 , zCnt = abs(.tGrid.zCnt)-1
               if .bFlagHasGrid then
                  if .tGrid.xCnt < 0 then fPX += (xCnt*.tGrid.Xstep)/-2 '.tGrid.Xstep/-2
                  if .tGrid.zCnt < 0 then fpZ += (zCnt*.tGrid.Zstep)/-2 '.tGrid.ZStep/-2
               end if
               select case .bType
               case sit_Include
                  #ifndef __Tester
                  puts("sit_Include")
                  #endif
                  iIdent += 2
               case sit_Cylinder
                  static as zstring ptr pzCaps(...)={@"none",@"one",@"two",@"A",@"B"}
                  if iPrevRec>.bRecurse then iIdent -= 2
                  iPrevRec=.bRecurse '4

                  dim as Matrix3x3 tMatOri = any
                                    
                  scope
                     
                     'with tMatrixStack(g_CurrentMatrix)
                     if .bFlagOriMat then
                        
                        'tMatOri = *cptr(Matrix3x3 ptr,@.fOri(0))
                        
                        '#define _M(_I) tMatOri.M(_I)
                        '_M(0) = .fOri(0) : _M(1) = .fOri(3) : _M(2) = .fOri(6)
                        '_M(3) = .fOri(1) : _M(4) = .fOri(4) : _M(5) = .fOri(7)
                        '_M(6) = .fOri(2) : _M(7) = .fOri(5) : _M(8) = .fOri(8)
                        
                        dim as single fMatrix(15) = { _                           
                          .fOri(0) , .fOri(1) , .fOri(2) , 0 , _ 'X scale ,    0?   ,   0?    , 0 
                          .fOri(3) , .fOri(4),  .fOri(5) , 0 , _ '  0?    , Y Scale ,   0?    , 0 
                          .fOri(6) , .fOri(7) , .fOri(8) , 0 , _ '  0?    ,    0?   , Z Scale , 0 
                            0      ,    0    ,    0     , 1 }
                          '-.fPosX  ,  -.fPosY , -.fPosZ  , 1 }   ' X Pos  ,  Y Pos  ,  Z Pos  , 1 
                        PushAndMultMatrix( @fMatrix(0) )
                        '#ifndef __Tester
                        'puts("Origin!")
                        '#endif
                     'else
                     '   tMatOri = g_tIdentityMatrix3x3 '.fScaleX = 0
                     end if
                     
                     with tMatOri
                        #define _m(_N) tMatrixStack(g_CurrentMatrix).m(_N)
                        .m(0) = _m(0) : .m(3) = _m(1) : .m(6) = _m( 2)
                        .m(1) = _m(4) : .m(4) = _m(5) : .m(7) = _m( 6)
                        .m(2) = _m(8) : .m(5) = _m(9) : .m(8) = _m(10)
                     end with
                     
                     'var pMat = @tMatrixStack(g_CurrentMatrix)
                     'var fYScale = (pMat->fScaleY) , YScale = cint(fYScale)
                     
                     '#define __Position__ fCenX+fOffX+.fPosX+pMat->fPosX , fCenY+.fPosY+pMat->fPosY , fCenZ+fOffZ+.fPosZ+pMat->fPosZ
                     #define __Position__ fCenX+fOffX+.fPosX , fCenY+.fPosY , fCenZ+fOffZ+.fPosZ
                     var xCnt=0 , zCnt=0 , fStartX=0f , fOffZ=0f
                     if .bFlagHasGrid then 
                        xCnt = abs(.tGrid.xCnt)-1 : zCnt = abs(.tGrid.zCnt)-1
                        if .tGrid.xCnt < 0 then fStartX = ((xCnt)*.tGrid.Xstep)/-2 '.tGrid.Xstep/-2
                        if .tGrid.zCnt < 0 then fOffZ   = ((zCnt)*.tGrid.Zstep)/-2 '.tGrid.ZStep/-2
                     end if
                     for iZ as long = 0 to zCnt
                        var fOffX = fStartX
                        for iX as long = 0 to xCnt
                           for I as long = 0 to .bSecCnt-1
                              var p = @.tSecs(I)                        
                              dim as byte bRound = false
                              select case p->bShape
                              case sss_Round  : bRound  = true
                              case sss_Square : bRound  = false
                              case else      : continue for 'skip
                              end select  
                              dim as single fCenX,fCenY,fCenZ
                              var pMat = @tMatrixStack(g_CurrentMatrix)
                              if .bFlagCenter then                                 
                                 'fCenY = (p->bLength*fYScale)/-2
                                 'fCenY = (p->bLength*(pMat->fScaleY))/-2
                                 fCenY = p->bLength/-2
                                 fCenZ += .fPosY
                                 #ifndef __Tester
                                 puts("Center flag")
                                 #endif
                              else
                                 'continue for
                              end if                              
                              if .bFlagMale then                                 
                                 'if bDraw=2 then
                                    'printf( !"%g %g %g\n" , __Position__ )
                                    'with tMatrixStack(g_CurrentMatrix)
                                    '   printf(!"[ %g %g %g %g\n",.m( 0),.m( 1),.m( 2),.m( 3))
                                    '   printf(!"  %g %g %g %g\n",.m( 4),.m( 5),.m( 6),.m( 7))
                                    '   printf(!"  %g %g %g %g\n",.m( 8),.m( 9),.m(10),.m(11))
                                    '   printf(!"  %g %g %g %g ]\n",.m(12),.m(13),.m(14),.m(15))
                                    'end with
                                 'end if                                 
                                 'if lDrawPart <> -2 then 
                                    iMale += 1
                                    #ifndef __NoRender
                                       DrawMaleShape( __Position__ , p->wFixRadius/100 , p->bLength , bRound , "" & iMale )
                                    #endif
                                 'end if
                              else
                                 'if lDrawPart <> -2 then 
                                    iFemale += 1
                                    #ifndef __NoRender
                                       DrawFemaleShape( __Position__ , p->wFixRadius/100 , p->bLength , bRound , "" & iFemale ) '*(pMat->fScaleY)
                                    #endif
                                 'end if
                              end if
                              
                           next I
                           fOffX += .tGrid.Xstep
                        next iX
                        fOffZ += .tGrid.Zstep
                     next iZ                     
                     if .bFlagOriMat then PopMatrix()
                  end scope

                  
                  #if 0
                     '#define __Position__ .fPosX+pMat->fPosX , .fPosY+pMat->fPosY , .fPosZ+pMat->fPosZ
                     #define __Position__ .fPosX , .fPosY , .fPosZ
                     #ifdef DebugShadow
                        printf(!"%sSecs=%i Gender=%s Caps=%s HasGrid=%s GridX=%i GridZ=%i (Pos=%g,%g,%g)",space(iIdent), _
                        .bSecCnt , iif(.bFlagMale,"M","F") , pzCaps(.bCaps) , iif(.bFlagHasGrid,"Yes","No") , _
                        abs(.tGrid.xCnt) , abs(.tGrid.zCnt) , __Position__ )
                     #endif
                  #endif
                  
                  for I as long = 0 to .bSecCnt-1
                     static as zstring ptr pzSecs(...)={@"Invalid",@"Round",@"Axle",@"Square",@"FlexPrev",@"FlexNext"}                     
                     with .tSecs(I)
                        #ifndef __Tester                            
                           #ifdef DebugShadow
                              var pMat = @tMatrixStack(g_CurrentMatrix)
                              printf(" %s(%g %g)",pzSecs(.bShape),.wFixRadius/100,.bLength*(pMat->fScaleY))
                           #endif
                        #endif
                     end with
                  next I      
                  #ifndef __Tester
                     #ifdef DebugShadow
                        puts("")
                     #endif
                  #endif                  
                  
                  '>>>>> Detect Shape type (stud,clutch,alias,etc...) >>>>>
                  scope
                     var iConCnt = 1 , bConType = spUnknown , bSecs = .bSecCnt , bSides = 1
                     select case .bCaps
                     case sc_None : bSides = 2
                     case sc_One  : bSides = 1
                     #ifndef __Tester
                     case sc_Two  : puts("!!!!! CHECK TWO CAPS!!!!!")
                     #endif
                     end select
                     
                     'negative xCnt/zCnt are "centered"
                     if .bFlagHasGrid then iConCnt = abs(.tGrid.xCnt)*abs(.tGrid.zCnt)
                     if .bFlagMale then 
                        var pMat = @tMatrixStack(g_CurrentMatrix)
                        var iIgnore = 0
                        #ifndef __Tester
                        if iConCnt > 1 then puts("!!!!!! MALE GRID FOUND !!!!!")
                        #endif
                        bConType = spStud
                        for I as long = 0 to .bSecCnt-1
                           select case .tSecs(I).bShape
                           case sss_FlexNext, sss_FlexPrev : iIgnore += 1
                           end select
                        next I                           
                        for I as long = 0 to .bSecCnt-1
                           if .tSecs(I).bLength = 1 then bSecs -= 1 : continue for 'ignore length=1 sections
                           select case .tSecs(I).bShape
                           case sss_Axle                              
                              DbgConnect(!"Axle += %i\n",iConCnt)                              
                              tSnap.lAxleCnt += iConCnt : bSecs -= 1 'AXLEHOLE //bConType = spAxleHole: exit for 
                              'puts("Axle " & bSecs)
                           case sss_FlexNext
                              bSecs -= 1 'other side of pin?
                              'puts("Pin Mirror " & bSecs)
                           case sss_FlexPrev                              
                              DbgConnect(!"Pin += %i\n",iConCnt)                              
                              ''tSnap.lPinCnt += iConCnt 
                              bSecs -= 1  'PIN // bConType = spPin : exit for
                              'bSecs -= 1: 'continuation of the pin must be ignored
                              'puts("Pin" & bSecs)
                           case sss_Round                              
                              if .tSecs(I).wFixRadius = 800 then
                                 bSecs -= 1 'STOPPER? Ignoring it for now
                                 'puts("Stopper" & bSecs)
                              elseif .tSecs(I).wFixRadius = 400 then                                 
                                 DbgConnect(!"Bar += %i\n",iConCnt)                                 
                                 ''tSnap.lBarCnt += iConCnt 
                                 bSecs -= 1 'BARHOLE
                                 'puts("Bar" & bSecs)
                              elseif .tSecs(I).wFixRadius = 600 then 'stud
                                 DbgConnect(!"Stud += %i\n",iConCnt)
                                 'var p = pPart
                                 with *pMat
                                    'printf(!"stud ori: %p\n",pMatOri)
                                    'puts("Male: " & iMale)
                                    dim as SnapPV tPV = type(fPX+.fPosX , fPY+.fPosY , fPZ+.fPosZ) : tPV.tOriMat = tMatori
                                    SnapAddStud( tSnap , iConCnt , tPV )
                                 end with                                 
                                 bSecs -= 1 'stud
                              else
                                 if iIgnore then
                                    iIgnore -= 1 : bSecs -= 1
                                    '#ifndef __Tester
                                    'puts("Ignored (pin part)" & bSecs)
                                    '#endif
                                 else
                                    #ifndef __Tester
                                    puts("Unknown male round cylinder?")
                                    #endif
                                 end if
                              end if
                           case else
                              puts("Unknown male?")
                           end select
                        next I
                     else 'females can be BARHOLE / PINHOLE / CLUTCHES / ALIAS
                        bConType = spClutch
                        if .bFlagSlide then 'PINHOLE / AXLEHOLE / BARHOLE
                           'if iConCnt > 1 then puts("!!!!! GRID PINHOLE FOUND !!!!!")
                           'bConType = spPinHole
                           var iMaybePins = 0
                           dim as byte bDidAxleHole,bDidClutch,bDidBarHole
                           for I as long = 0 to .bSecCnt-1                              
                              if .tSecs(I).bLength*((pMat->fScaleY)) = 1 then
                                 #ifndef __Tester
                                 puts("Length 1 section ignored")
                                 #endif
                                 bSecs -= 1 : continue for 'ignore length=1 sections
                              end if
                              select case .tSecs(I).bShape 
                              case sss_Axle
                                 DbgConnect(!"AxleHole += %i (Axle slide)\n",iConCnt*bSides)
                                 if bDidAxleHole=0 then bDidAxleHole=1 '': tSnap.lAxleHoleCnt += iConCnt*bSides 
                                 'AXLEHOLE //bConType = spAxleHole: exit for 
                                 'if there's an axlehole then it can't be a pinhole, and it can't have dual clutches
                                 bSecs -= 1 : iMaybePins=-999 : bSides = 1
                              case sss_Square                                    
                                 if bDidClutch=0 then
                                    bDidClutch=1
                                    with *pMat
                                       ''puts("Female: " & iFemale)
                                       dim as SnapPV tPV = type(fPX+.fPosX , fPY+.fPosY , fPZ+.fPosZ) : tPV.tOriMat = tMatori
                                       SnapAddClutch( tSnap , iConCnt , tPV )
                                    end with
                                 end if
                                 DbgConnect(!"Clutch += %i (Square slide)\n",iConCnt)
                                 DbgConnect(!"BarHole += %i (Square slide)\n",iConCnt*bSides)
                                 'if bDidClutch=0  then bDidClutch=1  : tSnap.lClutchCnt  += iConCnt
                                 if bDidBarHole=0 then bDidBarHole=1 '': tSnap.lBarHoleCnt += iConCnt*bSides
                                 bSecs -= 1 'BARHOLE //bConType = spBarHole: exit for
                              case sss_Round                                 
                                 select case .tSecs(I).wFixRadius
                                 case 800: bSecs -= 1 '???? (anti-stopper??)
                                 case 600: iMaybePins += 1 
                                 case 400                                    
                                    DbgConnect(!"BarHole += %i (Round slide)\n",iConCnt*bSides)                                    
                                    if bDidBarHole=0 then bDidBarHole=1 '': tSnap.lBarHoleCnt += iConCnt*bSides 
                                    bSecs -= 1 'BARHOLE
                                 end select                                 
                              end select
                           next I
                           if iMaybePins>0 then                               
                              DbgConnect(!"Clutch += %i (round slide from pin?)\n",iConCnt*iMaybePins*bSides )
                              DbgConnect(!"PinHole += %i (round slide )\n", iConCnt*iMaybePins)
                              #ifndef __Tester
                              puts("ERROR: unimplemented clutches were not added")
                              #endif
                              'tSnap.lClutchCnt += iConCnt*iMaybePins*bSides 
                              ''tSnap.lPinHoleCnt += iConCnt*iMaybePins 
                              bSecs -= iMaybePins 'PINHOLE
                           end if
                        else 'BARHOLE / CLUTCH / KingPin (fat)
                           dim as byte bDidPinHole,bDidBarHole
                           for I as long = 0 to .bSecCnt-1                              
                              'if .tSecs(I).wFixRadius > 600 then bConType = spPinHole : exit for
                              select case .tSecs(I).bShape
                              case sss_Axle
                                 #ifndef __Tester
                                 puts("Axle hole without slide??????")
                                 #endif
                              case sss_FlexPrev                                 
                                 DbgConnect(!"PinHole += %i (FlexPrev)\n",iConCnt)                                 
                                 if bDidPinHole=0 then bDidPinHole=1 '': tSnap.lPinHoleCnt += iConCnt 
                                 bSecs -= 1: 'bConType = spPinHole
                              case sss_Round 'barholes have radius of 4.0
                                 if .tSecs(I).wFixRadius = 400 then                                     
                                    DbgConnect(!"BarHole += %i (Round)\n",iConCnt*bSides)                                    
                                    if bDidBarHole=0 then bDidBarHole = 1 '': tSnap.lBarHoleCnt += iConCnt*bSides 
                                    bSecs -= 1 'bConType = spBarhole : exit for 'BARHOLE
                                 elseif .tSecs(I).wFixRadius = 600 then 'clutch?
                                    DbgConnect(!"Clutch += %i (Round)\n",iConCnt)
                                    with *pMat                                       
                                       for iGX as long = 0 to xCnt
                                          for iGZ as long = 0 to zCnt
                                             ''puts("Female: " & iFemale)
                                             dim as SnapPV tPV = type(fPX+.fPosX+iGX*pG->xStep , fPY+.fPosY , fPZ+.fPosZ+iGZ*pG->zStep) : tPV.tOriMat = tMatori
                                             SnapAddClutch( tSnap , 1 , tPV )
                                          next igZ
                                       next iGX
                                    end with
                                    bSecs -= 1                                    
                                 end if
                              end select
                           next I  
                           ''if bConType = spBarHole andalso .bCaps = sc_None then iConCnt *= 2 'dual for hollow
                        end if
                     end if                     
                     if bSecs < 0 then puts("ERROR: remaining section counter is negative")
                     if bSecs > 1 then puts("ERROR: Too many unhandled sections!")
                     if bSecs > 0 then 'remaining sects (fallback)
                        select case bConType                           
                        case spStud                               
                           'DbgConnect(!"Stud += %i (Fallback)\n",iConCnt)
                           #ifndef __Tester
                           printf(!"Stud += %i (Fallback {ignored})\n",iConCnt)
                           #endif
                           ''tSnap.lStudCnt     += iConCnt
                           '#ifndef __Tester
                           'puts("!!! FALLBACK STUD !!!")
                           '#endif
                        case spClutch  
                           'printf(!"Sides=%i\n",bSides)
                           with *pMat
                              'puts("Female: " & iFemale)
                              dim as SnapPV tPV = type(fPX+.fPosX , fPY+.fPosY , fPZ+.fPosZ) : tPV.tOriMat = tMatori
                              SnapAddClutch( tSnap , iConCnt , tPV )
                           end with
                           DbgConnect(!"Clutch += %i (Fallback {ignored})\n",iConCnt)
                           #ifndef __Tester
                           if iConCnt > 1 then printf(!"WARNING: %i clutches added as fallback {ignored}\n",iConCnt)
                           #endif
                           'printf(!"Clutch += %i (Fallback)\n",iConCnt)
                           
                           'tSnap.lClutchCnt   += iConCnt '*bSides 
                           
                           '#ifndef __Tester
                           'puts("!!! FALLBACK CLUTCH !!!")
                           '#endif
                        case spAlias                              
                           DbgConnect(!"Alias += %i (Fallback {ignored})\n",iConCnt)
                           ''tSnap.lAliasCnt    += iConCnt
                        case spBar                                
                           DbgConnect(!"Bar += %i (Fallback {ignored})\n",iConCnt)
                           ''tSnap.lBarCnt      += iConCnt
                        case spBarHole : tSnap.lBarHoleCnt  += iConCnt*bSides                           
                           DbgConnect(!"BarHole += %i (Fallback {ignored})\n",iConCnt)                           
                        case spPin     '': tSnap.lPinCnt      += iConCnt 
                           DbgConnect(!"Pin += %i (Fallback {ignored})\n",iConCnt)
                        case spPinHole
                           DbgConnect(!"PinHole += %i (Fallback {ignored})\n",iConCnt)                           
                           ''tSnap.lPinHoleCnt  += iConCnt
                           '#ifndef __Tester
                           'puts("!!! FALLBACK PINHOLE !!!")
                           '#endif
                        case spAxle                           
                           DbgConnect(!"Axle += %i (Fallback {ignored})\n",iConCnt)                           
                           ''tSnap.lAxleCnt     += iConCnt
                        case spAxleHole                           
                           DbgConnect(!"AxleHole += %i (Fallback {ignored})\n",iConCnt)                           
                           ''tSnap.lAxleHoleCnt += iConCnt
                        end select
                     end if
                  end scope
                  ' <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                  
               end select
            end with
         next N
      end if
      for N as long = 0 to .iPartCount-1
         with .tParts(N)
            if .bType = 1 then 'we only care for includes
               'continue for
               with ._1
                  var pSubPart = g_tModels(.lModelIndex).pModel                  
                  
                  dim as single fMatrix(15) = { _
                    .fA , .fD , .fG , 0 , _ 'X scale ,    0?   ,   0?    , 0 
                    .fB , .fE , .fH , 0 , _ '  0?    , Y Scale ,   0?    , 0 
                    .fC , .fF , .fI , 0 , _ '  0?    ,    0?   , Z Scale , 0 
                    .fX , .fY , .fZ , 1 }   ' X Pos  ,  Y Pos  ,  Z Pos  , 1 
                  
                  'var sName = *cptr(zstring ptr,strptr(g_sFilenames)+g_tModels(.lModelIndex).iFilenameOffset+6)
                  'puts(sName)                  
                  'for N as long = 0 to 15
                  '   printf("%f ",fMatrix(N))
                  '   if (N and 3)=3 then puts("")
                  'next N
                  
                  PushAndMultMatrix( @fMatrix(0) )                  
                  SnapModel( pSubPart , tSnap , pRoot )
                  PopMatrix()
               end with               
            end if
         end with
      next N
   end with
end sub
#endif

#ifndef __NoRender

sub DrawLimitsCube( xMin as single , xMax as single , yMin as single , yMax as single , zMin as single , zMax as single )

    glBegin(GL_QUADS)'  // Start drawing the cube with quads

    '// Front face (normal pointing towards +Z)
    glNormal3f(0.0f, 0.0f, 1.0f)
    glVertex3f(xmin, ymin, zmax)
    glVertex3f(xmax, ymin, zmax)
    glVertex3f(xmax, ymax, zmax)
    glVertex3f(xmin, ymax, zmax)

    '// Back face (normal pointing towards -Z)
    glNormal3f(0.0f, 0.0f, -1.0f)
    glVertex3f(xmin, ymin, zmin)
    glVertex3f(xmax, ymin, zmin)
    glVertex3f(xmax, ymax, zmin)
    glVertex3f(xmin, ymax, zmin)

    '// Left face (normal pointing towards -X)
    glNormal3f(-1.0f, 0.0f, 0.0f)
    glVertex3f(xmin, ymin, zmin)
    glVertex3f(xmin, ymin, zmax)
    glVertex3f(xmin, ymax, zmax)
    glVertex3f(xmin, ymax, zmin)

    '// Right face (normal pointing towards +X)
    glNormal3f(1.0f, 0.0f, 0.0f)
    glVertex3f(xmax, ymin, zmin)
    glVertex3f(xmax, ymin, zmax)
    glVertex3f(xmax, ymax, zmax)
    glVertex3f(xmax, ymax, zmin)

    '// Top face (normal pointing towards +Y)
    glNormal3f(0.0f, 1.0f, 0.0f)
    glVertex3f(xmin, ymax, zmin)
    glVertex3f(xmax, ymax, zmin)
    glVertex3f(xmax, ymax, zmax)
    glVertex3f(xmin, ymax, zmax)

    '// Bottom face (normal pointing towards -Y)
    glNormal3f(0.0f, -1.0f, 0.0f)
    glVertex3f(xmin, ymin, zmin)
    glVertex3f(xmax, ymin, zmin)
    glVertex3f(xmax, ymin, zmax)
    glVertex3f(xmin, ymin, zmax)

    glEnd()
end sub
#endif


function DetectPartCathegory( pPart as DATFile ptr ) as byte   
   if pPart = 0 then return pcNone
   dim as PartSize tSize = any
   SizeModel( pPart , tSize )
   'with tSize : printf(!"<%f %f %f>\n",.xMax-.xMin,.yMax-.yMin,.zMax-.zMin) : end with
   var pSnap = cptr(PartSnap ptr,pPart->pData)
   
   'filter by height first
   select case cuint(tSize.yMax-tSize.yMin)
   case ( 4+4) 'baseplate
      if (pSnap->lStudCnt) then return pcBaseplate      
   case ( 8+4) 'plate
      if (pSnap->lStudCnt) andalso (pSnap->lClutchCnt) then 
         return pcPlate
      end if
   case (16+4) 'slab
      if (pSnap->lStudCnt) andalso (pSnap->lClutchCnt) then 
         return pcSlab
      end if      
   end select      
   'puts("Other (fallback)")
   return pcOther
end function