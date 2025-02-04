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
         dim as byte bDoDraw
         if (lDrawPart<0 orelse lDrawPart=N) then bDoDraw = 1
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
   
   if pRoot = NULL then pRoot = pPart
   
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

type SnapPV
   as float fPX,fPY,fPZ 'position
   as float fVX,fVy,fVZ 'direction vector
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
sub DrawMaleShape( fX as single , fY as single , fZ as single , fRadius as single , fLength as single , bRound as byte )
   'dim as single fVec(2) = {fX_,fY_,fZ_}
   'MultiplyMatrixVector( @fVec(0) )
   '#define FX fVec(0)
   '#define FY fVec(1)
   '#define FZ fVec(2)
   
   glEnable( GL_POLYGON_STIPPLE )
   glPushMatrix()   
   glLoadCurrentMatrix()
   glTranslatef( fX , fY-fLength/2.0 , fZ )
   glRotatef( 90 , 1,0,0 )      
   glPolygonStipple(	cptr(glbyte ptr,@MaleStipple(0)) )   
   glColor3f( 1 , 1 , 0 )   
   if bRound then
      glScalef( 8/7 , 8/7 , (fLength/fRadius)*(5/7) ) 'cylinder
      glutSolidSphere( fRadius , 18 , 7 ) 'male round (.5,.5,N\2)
   else
      glScalef( 2 , 2 , (fLength/fRadius) ) 'square
      glutSolidCube(fRadius) 'male square (1,1,N)
   end if
   glPopMatrix()
   glDisable( GL_POLYGON_STIPPLE )
end sub
sub DrawFemaleShape( fX as single , fY as single , fZ as single , fRadius as single , fLength as single , bRound as byte )   
   'dim as single fVec(2) = {fX_,fY_,fZ_}
   'MultiplyMatrixVector( @fVec(0) )
   '#define FX fVec(0)
   '#define FY fVec(1)
   '#define FZ fVec(2)   
   glEnable( GL_POLYGON_STIPPLE )
   glPushMatrix()   
   glLoadCurrentMatrix()
   glTranslatef( fX , fY-fLength/2.0 , fZ )   
   glRotatef( 90 , 1,0,0 )   
   glPolygonStipple(	cptr(glbyte ptr,@FeMaleStipple(0)) )
   glColor3f( 1 , 0 , 0 )   
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

sub SnapModel( pPart as DATFile ptr , tSnap as PartSnap , bDraw as byte = false , pRoot as DATFile ptr = NULL )
   #ifdef __NoRender
   bDraw=false
   #endif
   if pRoot = NULL then pRoot = pPart        
   with *pPart      
      if .tSize.zMax = .tSize.zMin then         
         dim as PartSize tSz : SizeModel( pPart , tSz )
         .tSize = tSz         
      end if
      if .iShadowCount then
         #ifndef __Tester
            #ifdef DebugShadow
               if bDraw=0 then printf(!"Shadow Entries=%i (%s)\n",.iShadowCount,GetPartName(pPart))
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
                  if bDraw=0 then puts("sit_Include")
                  #endif
                  iIdent += 2
               case sit_Cylinder
                  static as zstring ptr pzCaps(...)={@"none",@"one",@"two",@"A",@"B"}
                  if iPrevRec>.bRecurse then iIdent -= 2
                  iPrevRec=.bRecurse '4
                  
                  #ifndef __Tester                   
                  #ifndef __NoRender
                  if bDraw then
                     
                     if .bFlagOriMat then                        
                        dim as single fMatrix(15) = { _                           
                          .fOri(0) , .fOri(3) , .fOri(6) , 0 , _ 'X scale ,    0?   ,   0?    , 0 
                          .fOri(1) , .fOri(4),  .fOri(7) , 0 , _ '  0?    , Y Scale ,   0?    , 0 
                          .fOri(2) , .fOri(5) , .fOri(8) , 0 , _ '  0?    ,    0?   , Z Scale , 0 
                            0      ,    0    ,    0     , 1 }
                          '-.fPosX  ,  -.fPosY , -.fPosZ  , 1 }   ' X Pos  ,  Y Pos  ,  Z Pos  , 1 
                        PushAndMultMatrix( @fMatrix(0) )
                        #ifndef __Tester
                        puts("Origin!")
                        #endif
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
                                 DrawMaleShape( __Position__ , p->wFixRadius/100 , p->bLength , bRound ) 
                                 
                              else
                                 DrawFemaleShape( __Position__ , p->wFixRadius/100 , p->bLength , bRound ) '*(pMat->fScaleY)
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
                              if bDraw=0 then printf(" %s(%g %g)",pzSecs(.bShape),.wFixRadius/100,.bLength*(pMat->fScaleY))
                           #endif
                        #endif
                     end with
                  next I      
                  #ifndef __Tester
                     #ifdef DebugShadow
                        if bDraw=0 then puts("")
                     #endif
                  #endif                  
                  
                  '>>>>> Detect Shape type (stud,clutch,alias,etc...) >>>>>
                  scope
                     var iConCnt = 1 , bConType = spUnknown , bSecs = .bSecCnt , bSides = 1
                     select case .bCaps
                     case sc_None : bSides = 2
                     case sc_One  : bSides = 1
                     #ifndef __Tester
                     case sc_Two  : if bDraw=0 then puts("!!!!! CHECK TWO CAPS!!!!!")
                     #endif
                     end select
                     
                     'negative xCnt/zCnt are "centered"
                     if .bFlagHasGrid then iConCnt = abs(.tGrid.xCnt)*abs(.tGrid.zCnt)
                     if .bFlagMale then 
                        var pMat = @tMatrixStack(g_CurrentMatrix)
                        var iIgnore = 0
                        #ifndef __Tester
                        if iConCnt > 1 andalso bDraw=0 then puts("!!!!!! MALE GRID FOUND !!!!!")
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
                              if bDraw=0 then 
                                 DbgConnect(!"Axle += %i\n",iConCnt)
                              end if
                              tSnap.lAxleCnt += iConCnt : bSecs -= 1 'AXLEHOLE //bConType = spAxleHole: exit for 
                              'puts("Axle " & bSecs)
                           case sss_FlexNext
                              bSecs -= 1 'other side of pin?
                              'puts("Pin Mirror " & bSecs)
                           case sss_FlexPrev
                              if bDraw=0 then 
                                 DbgConnect(!"Pin += %i\n",iConCnt)
                              end if
                              tSnap.lPinCnt += iConCnt : bSecs -= 1  'PIN // bConType = spPin : exit for
                              'bSecs -= 1: 'continuation of the pin must be ignored
                              'puts("Pin" & bSecs)
                           case sss_Round                              
                              if .tSecs(I).wFixRadius = 800 then
                                 bSecs -= 1 'STOPPER? Ignoring it for now
                                 'puts("Stopper" & bSecs)
                              elseif .tSecs(I).wFixRadius = 400 then
                                 if bDraw=0 then 
                                    DbgConnect(!"Bar += %i\n",iConCnt)
                                 end if
                                 tSnap.lBarCnt += iConCnt : bSecs -= 1 'BARHOLE
                                 'puts("Bar" & bSecs)
                              elseif .tSecs(I).wFixRadius = 600 then 'stud
                                 if bDraw=0 then
                                    DbgConnect(!"Stud += %i\n",iConCnt)
                                    'var p = pPart
                                    with *pMat
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
                                    if bDraw=0 then puts("Unknown male round cylinder?")
                                    #endif
                                 end if
                              end if
                           case else
                              if bDraw=0 then puts("Unknown male?")
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
                                 if bDraw=0 then puts("Length 1 section ignored")
                                 #endif
                                 bSecs -= 1 : continue for 'ignore length=1 sections
                              end if
                              select case .tSecs(I).bShape 
                              case sss_Axle                                 
                                 if bDraw=0 then 
                                    DbgConnect(!"AxleHole += %i (Axle slide)\n",iConCnt*bSides)
                                 end if
                                 if bDidAxleHole=0 then bDidAxleHole=1 : tSnap.lAxleHoleCnt += iConCnt*bSides 
                                 'AXLEHOLE //bConType = spAxleHole: exit for 
                                 'if there's an axlehole then it can't be a pinhole, and it can't have dual clutches
                                 bSecs -= 1 : iMaybePins=-999 : bSides = 1
                              case sss_Square   
                                 if bDraw=0 then
                                    if bDidClutch=0 then
                                       bDidClutch=1
                                       with *pMat
                                          SnapAddClutch( tSnap , iConCnt , type(fPX+.fPosX , fPY+.fPosY , fPZ+.fPosZ) )                                       
                                       end with
                                    end if
                                    DbgConnect(!"Clutch += %i (Square slide)\n",iConCnt)
                                    DbgConnect(!"BarHole += %i (Square slide)\n",iConCnt*bSides)
                                 end if
                                 'if bDidClutch=0  then bDidClutch=1  : tSnap.lClutchCnt  += iConCnt
                                 if bDidBarHole=0 then bDidBarHole=1 : tSnap.lBarHoleCnt += iConCnt*bSides
                                 bSecs -= 1 'BARHOLE //bConType = spBarHole: exit for
                              case sss_Round                                 
                                 select case .tSecs(I).wFixRadius
                                 case 800: bSecs -= 1 '???? (anti-stopper??)
                                 case 600: iMaybePins += 1 
                                 case 400
                                    if bDraw=0 then 
                                       DbgConnect(!"BarHole += %i (Round slide)\n",iConCnt*bSides)
                                    end if
                                    if bDidBarHole=0 then bDidBarHole=1 : tSnap.lBarHoleCnt += iConCnt*bSides 
                                    bSecs -= 1 'BARHOLE
                                 end select                                 
                              end select
                           next I
                           if iMaybePins>0 then 
                              if bDraw=0 then
                                 DbgConnect(!"Clutch += %i (round slide from pin?)\n",iConCnt*iMaybePins*bSides )
                                 DbgConnect(!"PinHole += %i (round slide )\n", iConCnt*iMaybePins)
                                 #ifndef __Tester
                                 puts("ERROR: unimplemented clutches were not added")
                                 #endif
                              end if
                              'tSnap.lClutchCnt += iConCnt*iMaybePins*bSides 
                              tSnap.lPinHoleCnt += iConCnt*iMaybePins : bSecs -= iMaybePins 'PINHOLE
                           end if
                        else 'BARHOLE / CLUTCH / KingPin (fat)
                           dim as byte bDidPinHole,bDidBarHole
                           for I as long = 0 to .bSecCnt-1                              
                              'if .tSecs(I).wFixRadius > 600 then bConType = spPinHole : exit for
                              select case .tSecs(I).bShape
                              case sss_Axle
                                 #ifndef __Tester
                                 if bDraw=0 then puts("Axle hole without slide??????")
                                 #endif
                              case sss_FlexPrev
                                 if bDraw=0 then 
                                    DbgConnect(!"PinHole += %i (FlexPrev)\n",iConCnt)
                                 end if
                                 if bDidPinHole=0 then bDidPinHole=1 : tSnap.lPinHoleCnt += iConCnt 
                                 bSecs -= 1: 'bConType = spPinHole
                              case sss_Round 'barholes have radius of 4.0
                                 if .tSecs(I).wFixRadius = 400 then 
                                    if bDraw=0 then 
                                       DbgConnect(!"BarHole += %i (Round)\n",iConCnt*bSides)
                                    end if
                                    if bDidBarHole=0 then bDidBarHole = 1 : tSnap.lBarHoleCnt += iConCnt*bSides 
                                    bSecs -= 1 'bConType = spBarhole : exit for 'BARHOLE
                                 elseif .tSecs(I).wFixRadius = 600 then 'clutch?
                                    if bDraw=0 then 
                                       DbgConnect(!"Clutch += %i (Round)\n",iConCnt)
                                       with *pMat                                       
                                          for iGX as long = 0 to xCnt
                                             for iGZ as long = 0 to zCnt
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
                     if bDraw=0 then 
                        if bSecs < 0 then puts("ERROR: remaining section counter is negative")
                        if bSecs > 1 then puts("ERROR: Too many unhandled sections!")
                     end if
                     if bSecs > 0 then 'remaining sects (fallback)
                        select case bConType                           
                        case spStud    
                           if bDraw=0 then 
                              'DbgConnect(!"Stud += %i (Fallback)\n",iConCnt)
                              #ifndef __Tester
                              printf(!"Stud += %i (Fallback)\n",iConCnt)
                              #endif
                           end if
                           tSnap.lStudCnt     += iConCnt
                           '#ifndef __Tester
                           'puts("!!! FALLBACK STUD !!!")
                           '#endif
                        case spClutch  
                           'printf(!"Sides=%i\n",bSides)
                           if bDraw=0 then
                              with *pMat
                                 SnapAddClutch( tSnap , iConCnt , type(fPX+.fPosX , fPY+.fPosY , fPZ+.fPosZ) )                                       
                              end with
                              DbgConnect(!"Clutch += %i (Fallback)\n",iConCnt)
                              #ifndef __Tester
                              if iConCnt > 1 then printf(!"WARNING: %i clutches added as fallback\n",iConCnt)
                              #endif
                              'printf(!"Clutch += %i (Fallback)\n",iConCnt)
                           end if
                           
                           'tSnap.lClutchCnt   += iConCnt '*bSides 
                           
                           '#ifndef __Tester
                           'puts("!!! FALLBACK CLUTCH !!!")
                           '#endif
                        case spAlias   
                           if bDraw=0 then 
                              DbgConnect(!"Alias += %i (Fallback)\n",iConCnt)
                           end if
                           tSnap.lAliasCnt    += iConCnt
                        case spBar     
                           if bDraw=0 then 
                              DbgConnect(!"Bar += %i (Fallback)\n",iConCnt)
                           end if
                           tSnap.lBarCnt      += iConCnt
                        case spBarHole : tSnap.lBarHoleCnt  += iConCnt*bSides
                           if bDraw=0 then 
                              DbgConnect(!"BarHole += %i (Fallback)\n",iConCnt)
                           end if
                        case spPin     : tSnap.lPinCnt      += iConCnt 
                           if bDraw=0 then 
                              DbgConnect(!"Pin += %i (Fallback)\n",iConCnt)
                           end if
                        case spPinHole 
                           if bDraw=0 then 
                              DbgConnect(!"PinHole += %i (Fallback)\n",iConCnt)
                           end if
                           tSnap.lPinHoleCnt  += iConCnt
                           '#ifndef __Tester
                           'puts("!!! FALLBACK PINHOLE !!!")
                           '#endif
                        case spAxle
                           if bDraw=0 then 
                              DbgConnect(!"Axle += %i (Fallback)\n",iConCnt)
                           end if
                           tSnap.lAxleCnt     += iConCnt
                        case spAxleHole
                           if bDraw=0 then 
                              DbgConnect(!"AxleHole += %i (Fallback)\n",iConCnt)
                           end if
                           tSnap.lAxleHoleCnt += iConCnt
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
                  SnapModel( pSubPart , tSnap , bDraw , pRoot )
                  PopMatrix()
               end with               
            end if
         end with
      next N
   end with   
end sub

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