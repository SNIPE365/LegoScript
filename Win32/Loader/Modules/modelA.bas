#ifndef __Main
  #error " Don't compile this one"
#endif  

#ifdef DebugPrimitive
   #define DebugPrimParm  , sIdent as string = ""
   #define DebugPrimIdent , "   "+sIdent
#else
   #define DebugPrimParm
   #define DebugPrimIdent
#endif

static shared as boolean g_bRenderShadow , g_bRenderConnector

'Get SubPartType (based on the name !shouldnt be used we should trust the shadow library!)

function GetSubPartType( sPartName as string , bDebug as boolean = false ) as long
   'all duplos studs/clutches are hollow
   var sL = lcase(sPartName)
   var iPos = instr(sL,"stud")   
   if instr(sL,"stud") then
      if sL[iPos+4] = asc(".") then 
         'stud3(2x hei) stud4(hollow) stud5 stud8(duplo)
         select case sl[iPos+3]
         case asc("3"),asc("4"),asc("5"),asc("8")
            if bDebug then printf(!"%s\n",sPartName,"spClutch")
            return spClutch
         end select
      end if       
      if instr(sL,"4od.") orelse instr(sL,"4a.") orelse instr(sL,"3a.") then
         'stud3a stud4od (hollow) stud4a (hollow)
         if bDebug then printf(!"%s\n",sPartName,"spClutch")
         return spClutch
      end if
      'stud stud2 stud2a(hollow) stud7(duplo)
      if bDebug then printf(!"%s\n",sPartName,"spStud")
      return spStud
   end if
   if instr(sL,"axle.") then
      return spAxle
   end if
   return spUnknown
end function

function GetPartNameByIndex( iIndex as long ) as string
   if iIndex < 0 or iIndex >= g_ModelCount then return ""
   with g_tModels(iIndex)         
      return *cptr(zstring ptr,strptr(g_sFilenames)+.iFilenameOffset+6)   
   end with
end function

function GetPartName( pPart as DATFile ptr ) as string
   for I as long = 0 to g_ModelCount-1
      with g_tModels(I)
         if .pModel = pPart then
            return *cptr(zstring ptr,strptr(g_sFilenames)+.iFilenameOffset+6)
         end if
      end with
   next I
end function

#ifndef __NoRender

sub RenderModel( pPart as DATFile ptr , iBorders as long , uCurrentColor as ulong = &h70605040 , lDrawPart as long = -1 , uCurrentEdge as ulong = 0 DebugPrimParm )
   if uCurrentColor = &h70605040 then uCurrentColor = g_Colours(c_Blue) : uCurrentEdge = g_EdgeColours(c_Blue)
   
   var uEdge = uCurrentEdge
   static as integer iOnce
   
           
   with *pPart      
      'for M as long = 0 to 1
      for N as long = 0 to .iPartCount-1
         dim as byte bDoDraw = (lDrawPart<0 orelse lDrawPart=N)
         dim as ulong uColor = any', uEdge = any
         with .tParts(N)
            #ifdef DebugPrimitive
               'printf sIdent+"(" & .bType & ") Color=" & .wColour & " (Current=" & hex(uCurrentColor,8) & ")"
               'sle ep
            #endif
                        
            if .wColour = c_Main_Colour then 'inherit
               uColor = uCurrentColor ': uEdge = uCurrentEdge
            elseif .wColour <> c_Edge_Colour then
               if .wColour > ubound(g_Colours) then
                  puts("Bad Color: " & .wColour)
               end if
               uColor = g_Colours(.wColour)
               'uEdge  = g_EdgeColours(.wColour)
               'uEdge = ((uColor and &hFEFEFE) shr 1) or (uColor and &hFF000000)
               'if .wColour = c_Trans_Yellow then
               '   puts "Trans Yellow"
               'end if
            end if
            
            
            'if M=0 then
            '   if .bType=1 or .bType=5 then continue for
            'else
            '   if .bType<>2 and .bType<>5 then continue for
            'end if
            select case .bType
            case 1
               'continue for
               'uEdge = rgb(rnd*255,rnd*255,rnd*255)
               uEdge = ((uColor and &hFEFEFE) shr 1) or (uColor and &hFF000000)
               'g_EdgeColours(.wColour)
               var T1 = ._1
               with T1
                  if bDoDraw then
                     var pSubPart = g_tModels(.lModelIndex).pModel
                     var sName = *cptr(zstring ptr,strptr(g_sFilenames)+g_tModels(.lModelIndex).iFilenameOffset+6)
                                          
                     '1 16 0 0 0 1 0 0 0 8 0 0 0 1 axlehole.dat
   
                     #ifdef DebugPrimitive
                     Puts _
                        " fX:" & .fX & " fY:" & .fY & " fZ:" & .fZ & _
                        " fA:" & .fA & " fB:" & .fB & " fC:" & .fC & _
                        " fD:" & .fD & " fE:" & .fE & " fF:" & .fF & _
                        " fG:" & .fG & " fH:" & .fH & " fI:" & .fI & " '" & sName & "'"                     
                     #endif
                                       
                     'MultiplyMatrixVector( @.fX ) 
                  
                     dim as single fMatrix(15) = { _
                       .fA*cScale , .fD*cScale , .fG*cScale , 0 , _ 'X scale ,    ?    ,    ?    
                       .fB*cScale , .fE*cScale , .fH*cScale , 0 , _ '  ?     , Y Scale ,    ?    
                       .fC*cScale , .fF*cScale , .fI*cScale , 0 , _ '  ?     ,    ?    , Z Scale 
                       .fX*cScale , .fY*cScale , .fZ*cScale , 1 }   ' X Pos  ,  Y Pos  ,  Z Pos  
                     
                     'if sName = "axle.dat" then fMatrix(4) *= 2
                     PushAndMultMatrix( @fMatrix(0) )
                     
                     #ifdef ColorizePrimatives
                     if iBorders=0 then
                        select case GetSubPartType( sName )
                        case spStud   : uColor = &hFF4488FF                        
                        case spClutch : uColor = &hFF1122FF
                        case spAxle   : uColor = &hFF44FF88
                        end select
                     end if
                     #endif
                     
                     RenderModel( pSubPart , iBorders , uColor , iif(lDrawPart=-2,-2,-1) , uEdge DebugPrimIdent )
                     PopMatrix()
                  end if                  
               end with               
            case 2               
               if iBorders=0 andalso lDrawPart <> N then continue for
               'glPushMatrix() : glMultMatrixf( @fMatrix(0) )
               
               var T2 = ._2               
               MultiplyMatrixVector( @T2.fX1 )
               MultiplyMatrixVector( @T2.fX2 )
               SetLineNormal( T2 )
               
               with T2
                  #ifdef DebugPrimitive
                  puts _
                     " fX1:" & .fX1 & " fY1:" & .fY1 & " fZ1:" & .fZ1 & _
                     " fX2:" & .fX2 & " fY2:" & .fY2 & " fZ2:" & .fZ2
                  #endif
                                    
                  if lDrawPart = -2 then
                     var uEdge2 = uEdge
                     cast(ubyte ptr,@uEdge2)[3] shr= 2
                     glColor4ubv( cast(ubyte ptr,@uEdge2) )
                  else
                     glColor4ubv( cast(ubyte ptr,@uEdge) )
                  end if
                                    
                  glBegin GL_LINES                  
                  glVertex3f .fX1*cScale , .FY1*cScale , .fZ1*cScale
                  glVertex3f .fX2*cScale , .FY2*cScale , .fZ2*cScale
                  glEnd
               end with
            case 3
               if iBorders orelse bDoDraw=0 then continue for
               var T3 = ._3               
               MultiplyMatrixVector( @T3.fX1 ) 
               MultiplyMatrixVector( @T3.fX2 )
               MultiplyMatrixVector( @T3.fX3 )
               SetTrigNormal(T3)
               with T3
                  #ifdef DebugPrimitive
                     puts _
                        " fX1:" & .fX1 & " fY1:" & .fY1 & " fZ1:" & .fZ1 & _
                        " fX2:" & .fX2 & " fY2:" & .fY2 & " fZ2:" & .fZ2 & _
                        " fX3:" & .fX3 & " fY3:" & .fY3 & " fZ3:" & .fZ3
                  #endif
                  
                  glColor4ubv( cast(ubyte ptr,@uColor) )
                                                                        
                  glBegin GL_TRIANGLES                  
                  'glNormal3f( rnd , rnd , rnd )
                  glVertex3f .fX1*cScale , .FY1*cScale , .fZ1*cScale 
                  'glNormal3f( rnd , rnd , rnd )
                  glVertex3f .fX2*cScale , .FY2*cScale , .fZ2*cScale
                  'glNormal3f( rnd , rnd , rnd )
                  glVertex3f .fX3*cScale, .FY3*cScale , .fZ3*cScale 
                  glEnd
               end with
            case 4               
               if iBorders orelse bDoDraw=0 then continue for
               var T4 = ._4               
               MultiplyMatrixVector( @T4.fX1 ) 
               MultiplyMatrixVector( @T4.fX2 )
               MultiplyMatrixVector( @T4.fX3 )
               MultiplyMatrixVector( @T4.fX4 )               
               SetQuadNormal( T4 )
               'SetTrigNormal( *cptr( typeof(._3) ptr , @T4 ) ) 'just need the line
               with T4
                  #ifdef DebugPrimitive
                     puts _
                        " fX1:" & .fX1 & " fY1:" & .fY1 & " fZ1:" & .fZ1 & _
                        " fX2:" & .fX2 & " fY2:" & .fY2 & " fZ2:" & .fZ2 & _
                        " fX3:" & .fX3 & " fY3:" & .fY3 & " fZ3:" & .fZ3 & _
                        " fX4:" & .fX4 & " fY4:" & .fY4 & " fZ4:" & .fZ4
                  #endif
                  
                  glColor4ubv( cast(ubyte ptr,@uColor) )                  
                  glBegin GL_QUADS
                  glVertex3f .fX1*cScale , .FY1*cScale , .fZ1*cScale 
                  glVertex3f .fX2*cScale , .FY2*cScale , .fZ2*cScale
                  glVertex3f .fX3*cScale , .FY3*cScale , .fZ3*cScale 
                  glVertex3f .fX4*cScale , .FY4*cScale , .fZ4*cScale
                  glEnd
               end with
            case 5
               'continue for
               if iBorders=0 orelse bDoDraw=0 then continue for
               var T5 = ._5               
               MultiplyMatrixVector( @T5.fX1 ) 
               MultiplyMatrixVector( @T5.fX2 )               
               SetLineNormal( *cptr( typeof(._2) ptr , @T5 ) ) 'just need the line
               with T5
                  #ifdef DebugPrimitive
                     puts _
                        " fX1:" & .fX1 & " fY1:" & .fY1 & " fZ1:" & .fZ1 & _
                        " fX2:" & .fX2 & " fY2:" & .fY2 & " fZ2:" & .fZ2 & _
                        " fXA:" & .fX3 & " fYA:" & .fY3 & " fZA:" & .fZ3 & _
                        " fXB:" & .fX4 & " fYB:" & .fY4 & " fZB:" & .fZ4
                  #endif
                  
                  'glColor4ubv( cast(ubyte ptr,@uEdge) )
                  #ifdef RenderOptionals
                     glColor4f( 0 , 1 , 0 , .33 )                  
                     glBegin GL_LINES                  
                     glVertex3f .fX1*cScale , .FY1*cScale , .fZ1*cScale
                     glVertex3f .fX2*cScale , .FY2*cScale , .fZ2*cScale
                     glEnd                  
                  #endif
               end with
            end select
         end with
      next N      
      'next M
      iOnce = 1
   end with   
end sub
#endif

static shared as long g_TotalLines , g_TotalOptis , g_TotalTrigs , g_TotalQuads

sub SizeModel( pPart as DATFile ptr , tSize as PartSize , iPartWanted as long = -1 , byref iPartNum as long = -1 , pRoot as DATFile ptr = NULL )
   
   dim as boolean bInitSizeStruct
   if pRoot = NULL then 
      pRoot = pPart 
      dim as typeof(tSize) tTemp : tSize = tTemp
   end if
   
   #macro CheckZ( _Var ) 
      if bWantSize then
         if tSize.xMax=fUnused orelse .fX##_Var > tSize.xMax then tSize.xMax = .fX##_Var 
         if tSize.xMin=fUnused orelse .fX##_Var < tSize.xMin then tSize.xMin = .fX##_Var
         
         if tSize.yMax=fUnused orelse .fY##_Var > tSize.yMax then tSize.yMax = .fY##_Var 
         if tSize.yMin=fUnused orelse .fY##_Var < tSize.yMin then tSize.yMin = .fY##_Var
         
         if tSize.zMax=fUnused orelse .fZ##_Var > tSize.zMax then tSize.zMax = .fZ##_Var 
         if tSize.zMin=fUnused orelse .fZ##_Var < tSize.zMin then tSize.zMin = .fZ##_Var      
      end if
   #endmacro
   
   if pRoot = pPart then PushIdentityMatrix()      
        
   with *pPart            
      
      for N as long = 0 to .iPartCount-1         
         if pRoot = pPart then iPartNum += 1       
         var bWantSize = (iPartWanted<0) orelse (iPartWanted=iPartNum)
         with .tParts(N)            
            select case .bType
            case 1                 
               'continue for
               with ._1
                  var pSubPart = g_tModels(.lModelIndex).pModel
                  var sName = *cptr(zstring ptr,strptr(g_sFilenames)+g_tModels(.lModelIndex).iFilenameOffset+6)
                  dim as single fMatrix(15) = { _
                    .fA*cScale , .fD*cScale , .fG*cScale , 0 , _
                    .fB*cScale , .fE*cScale , .fH*cScale , 0 , _
                    .fC*cScale , .fF*cScale , .fI*cScale , 0 , _
                    .fX*cScale , .fY*cScale , .fZ*cScale , 1 }                                      
                  PushAndMultMatrix( @fMatrix(0) )                   
                  
                  #if 0
                     select case GetSubPartType( sName , false )
                     case spStud                        
                        with tMatrixStack(g_CurrentMatrix)
                           printf(!"Stud X=%1.1f Y=%1.1f Z=%1.1f\n",.m(12),.m(13),.m(14))
                        end with
                     case spClutch 
                        rem nothing yet
                     end select
                  #endif
                  
                  SizeModel( pSubPart , tSize , iPartWanted , iPartNum , pRoot )
                  PopMatrix()                  
               end with               
            case 2               
               var T2 = ._2 
               'if bMain then T2.fY1 += 4 : T2.fY2 += 4
               MultiplyMatrixVector( @T2.fX1 )
               MultiplyMatrixVector( @T2.fX2 )
               
               g_TotalLines += 1
               
               with T2                  
                  CheckZ(1) 
                  CheckZ(2)
               end with
            case 3               
               var T3 = ._3   
               'if bMain then T3.fY1 += 4 : T3.fY2 += 4 : T3.fY3 += 4
               MultiplyMatrixVector( @T3.fX1 ) 
               MultiplyMatrixVector( @T3.fX2 )
               MultiplyMatrixVector( @T3.fX3 )               
               
               g_TotalTrigs += 1
               
               with T3                  
                  CheckZ(1) 
                  CheckZ(2)
                  CheckZ(3)
               end with
            case 4               
               var T4 = ._4
               'if bMain then T4.fY1 += 4 : T4.fY2 += 4 : T4.fY3 += 4 : T4.fY4 += 4
               MultiplyMatrixVector( @T4.fX1 ) 
               MultiplyMatrixVector( @T4.fX2 )
               MultiplyMatrixVector( @T4.fX3 )
               MultiplyMatrixVector( @T4.fX4 )
               
               g_TotalQuads += 1
               
               with T4                  
                  CheckZ(1) 
                  CheckZ(2)
                  CheckZ(3) 
                  CheckZ(4)                  
               end with            
            case 5
               g_TotalOptis += 1
            end select
         end with
      next N
   end with 
   
   if pRoot = pPart then PopMatrix()
   
end sub

type PartCollisionBox as PartSize


sub GetCollisionBoundaries( tResult as PartCollisionBox , tA as PartCollisionBox , tB as PartCollisionBox )   
    tResult.xMin = iif(tA.xMin > tB.xMin , tA.xMin , tB.xMin)
    tResult.xMax = iif(tA.xMax < tB.xMax , tA.xMax , tB.xMax)
    tResult.yMin = iif(tA.yMin > tB.yMin , tA.yMin , tB.yMin)
    tResult.yMax = iif(tA.yMax < tB.yMax , tA.yMax , tB.yMax)
    tResult.zMin = iif(tA.zMin > tB.zMin , tA.zMin , tB.zMin)
    tResult.zMax = iif(tA.zMax < tB.zMax , tA.zMax , tB.zMax)
end sub

function CheckCollision ( tA as PartSize , tB as PartSize ) as byte    
   ' Check X overlap
   if tA.xMax < tB.xMin orelse tA.xMin > tB.xMax then return false        
   ' Check Y overlap
   if tA.yMax < tB.yMin orelse tA.yMin > tB.yMax then return false    
   ' Check Z overlap
   IF tA.zMax < tB.zMin orelse tA.zMin > tB.zMax then return false
   ' If we get here, all three axes overlap
   return true
end function


sub CheckCollisionModel( pPart as DATFile ptr , atCollision() as PartCollisionBox , pRoot as DATFile ptr = NULL )
   
   if pRoot = NULL then pRoot = pPart
   static as PartCollisionBox AtPartBound()
   static as PartCollisionBox ptr ptSize
   
   #macro CheckZ( _Var )       
      if ptSize->xMax=fUnused orelse .fX##_Var > ptSize->xMax then ptSize->xMax = .fX##_Var 
      if ptSize->xMin=fUnused orelse .fX##_Var < ptSize->xMin then ptSize->xMin = .fX##_Var
      
      if ptSize->yMax=fUnused orelse .fY##_Var > ptSize->yMax then ptSize->yMax = .fY##_Var 
      if ptSize->yMin=fUnused orelse .fY##_Var < ptSize->yMin then ptSize->yMin = .fY##_Var
      
      if ptSize->zMax=fUnused orelse .fZ##_Var > ptSize->zMax then ptSize->zMax = .fZ##_Var 
      if ptSize->zMin=fUnused orelse .fZ##_Var < ptSize->zMin then ptSize->zMin = .fZ##_Var
   #endmacro
   
   'prepare to get bounding of each main part 
   if pPart=pRoot then 
      redim AtPartBound(pPart->iPartCount-1)      
      redim atCollision(0)
   end if

   'walking trough all polygons and obtain min/max coordinates
   with *pPart 
      if .tSize.zMax = .tSize.zMin then         
         dim as PartSize tSz : SizeModel( pPart , tSz ) : .tSize = tSz                  
      end if
      for N as long = 0 to .iPartCount-1         
         if pPart=pRoot then 
            'start clean for each main part
            with AtPartBound(N)
               .xMin = fUnused : .xMax = fUnused
               .yMin = fUnused : .yMax = fUnused
               .zMin = fUnused : .zMax = fUnused
            end with
            ptSize = @AtPartBound(N)       
         end if         
         'for main parts we will be getting both original and modified sizes
         'WARNING: i think parts rotated in Y willl totally fail!!! 
         '(TODO: fix it? maybe by keeping rotation and only identity the position?)
         with .tParts(N)            
            select case .bType
            case 1                 
               'continue for
               with ._1
                  var pSubPart = g_tModels(.lModelIndex).pModel
                  var sName = *cptr(zstring ptr,strptr(g_sFilenames)+g_tModels(.lModelIndex).iFilenameOffset+6)                  
                  dim as single fMatrix(15) = { _
                    .fA*cScale , .fD*cScale , .fG*cScale , 0 , _
                    .fB*cScale , .fE*cScale , .fH*cScale , 0 , _
                    .fC*cScale , .fF*cScale , .fI*cScale , 0 , _
                    .fX*cScale , .fY*cScale , .fZ*cScale , 1 }
                  PushAndMultMatrix( @fMatrix(0) )
                  'TODO maybe i can keep using SizeModel here right? is there any advantage?
                  'SizeModel( pSubPart , atCollision() , pRoot )
                  CheckCollisionModel( pSubPart , atCollision() , pRoot )
                  PopMatrix()                  
               end with               
            case 2               
               var T2 = ._2                
               MultiplyMatrixVector( @T2.fX1 )
               MultiplyMatrixVector( @T2.fX2 )
               with T2                  
                  CheckZ(1) 
                  CheckZ(2)
               end with
            case 3               
               var T3 = ._3
               MultiplyMatrixVector( @T3.fX1 ) 
               MultiplyMatrixVector( @T3.fX2 )
               MultiplyMatrixVector( @T3.fX3 )
               with T3                  
                  CheckZ(1) 
                  CheckZ(2)
                  CheckZ(3)
               end with
            case 4               
               var T4 = ._4
               'if bMain then T4.fY1 += 4 : T4.fY2 += 4 : T4.fY3 += 4 : T4.fY4 += 4
               MultiplyMatrixVector( @T4.fX1 ) 
               MultiplyMatrixVector( @T4.fX2 )
               MultiplyMatrixVector( @T4.fX3 )
               MultiplyMatrixVector( @T4.fX4 )               
               with T4                  
                  CheckZ(1) 
                  CheckZ(2)
                  CheckZ(3) 
                  CheckZ(4)                  
               end with            
            case 5
               rem optionals
            end select
         end with
      next N
   end with   
   'now check for coordinate collisions 
   '(need to ignore Y overflows and for that need untransformed sizes as well)
   if pRoot = pPart then 
      for N as long = 0 to pPart->iPartCount-1
         if pPart->tParts(N).bType <> 1 then continue for
         'adjust the box to ignore the negative part of the base height (Y)
         var fyMin = g_tModels(pPart->tParts(N)._1.lModelIndex).pModel->tSize.yMin
         if ((fyMin-(-4)) < 0.0001) then AtPartBound(N).yMin -= fyMin         
         AtPartBound(N).xMin += .1 : AtPartBound(N).xMax -= .1
         AtPartBound(N).yMin += .1 : AtPartBound(N).yMax -= .1         
         AtPartBound(N).zMin += .1 : AtPartBound(N).zMax -= .1
      next N
      for N as long = 0 to pPart->iPartCount-1         
         if pPart->tParts(N).bType <> 1 then continue for
         for M as long = N+1 to (pPart->iPartCount-1)
            if pPart->tParts(M).bType <> 1 then continue for
            if CheckCollision( atPartBound(N) , atPartBound(M) ) then
               #if 0
                  var iI = ubound(atCollision) : redim preserve atCollision(iI+1)                  
                  GetCollisionBoundaries( atCollision(iI) , atPartBound(N) , atPartBound(M) )
               #else
                  var iI = ubound(atCollision) : redim preserve atCollision(iI+2)
                  atCollision(iI) = AtPartBound(N)
                  atCollision(iI+1) = AtPartBound(M)
               #endif
            end if
         next M
      next N
      erase AtPartBound 
   end if
   
end sub

#if defined(__Tester) orelse (not defined(DebugShadow))
   #define DbgConnect rem
#else
   #define DbgConnect printf
#endif

#ifndef Vector3
type Vector3
    as single x, y, z
end type
#endif


type SnapPV
   as Vector3 tPos      'position
   as Matrix3x3 tOriMat '.fScaleX=0 means matrix is ignored
end type
type PartSnap
   lStudCnt     as long
   lClutchCnt   as long
   lAliasCnt    as long 
   lAxleCnt     as long
   lAxleHoleCnt as long
   lBarCnt      as long
   lBarHoleCnt  as long
   lPinCnt      as long
   lPinHoleCnt  as long   
   as SnapPV ptr pStud,pClutch
end type


sub SnapAddStud( tSnap as PartSnap , iCnt as long , byval tPV as SnapPV = (0) )   
   with tSnap      
      for N as long = 0 to iCnt-1
        .lStudCnt += 1
        .pStud = reallocate(.pStud,sizeof(tPV)*.lStudCnt)
        .pStud[.lStudCnt-1] = tPV        
      next N
   end with
end sub