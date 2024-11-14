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
function GetPartName( pPart as DATFile ptr ) as string
   for I as long = 0 to g_ModelCount-1
      with g_tModels(I)
         if .pModel = pPart then
            return *cptr(zstring ptr,strptr(g_sFilenames)+.iFilenameOffset+6)
         end if
      end with
   next I
end function

sub RenderModel( pPart as DATFile ptr , iBorders as long , uCurrentColor as ulong = &h70605040 , uCurrentEdge as ulong = 0 DebugPrimParm )
   if uCurrentColor = &h70605040 then uCurrentColor = g_Colours(c_Blue) : uCurrentEdge = g_EdgeColours(c_Blue)
   
   var uEdge = uCurrentEdge
   static as integer iOnce
           
   with *pPart      
      'for M as long = 0 to 1
      for N as long = 0 to .iPartCount-1
         dim as ulong uColor = any', uEdge = any
         with .tParts(N)
            #ifdef DebugPrimitive
               'printf sIdent+"(" & .bType & ") Color=" & .wColour & " (Current=" & hex(uCurrentColor,8) & ")"
               'sleep
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
                  
                  RenderModel( pSubPart , iBorders , uColor , uEdge DebugPrimIdent )
                  PopMatrix()
                  
               end with               
            case 2               
               if iBorders=0 then continue for
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
                  
                  glColor4ubv( cast(ubyte ptr,@uEdge) )
                                    
                  glBegin GL_LINES                  
                  glVertex3f .fX1*cScale , .FY1*cScale , .fZ1*cScale
                  glVertex3f .fX2*cScale , .FY2*cScale , .fZ2*cScale
                  glEnd
               end with
            case 3
               if iBorders then continue for
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
               if iBorders then continue for
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
               if iBorders=0 then continue for
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
                  glColor4f( 0 , 1 , 0 , .33 )
                  
                  glBegin GL_LINES                  
                  glVertex3f .fX1*cScale , .FY1*cScale , .fZ1*cScale
                  glVertex3f .fX2*cScale , .FY2*cScale , .fZ2*cScale
                  glEnd                  
               end with
            end select
         end with
      next N      
      'next M
      iOnce = 1
   end with   
end sub

type PartSize
   as single xMin , xMax
   as single yMin , yMax
   as single zMin , zMax
end type
static shared as long g_TotalLines , g_TotalOptis , g_TotalTrigs , g_TotalQuads
sub SizeModel( pPart as DATFile ptr , tSize as PartSize , pRoot as DATFile ptr = NULL )
   
   if pRoot = NULL then pRoot = pPart
   
   #macro CheckZ( _Var ) 
      if .fX##_Var > tSize.xMax then tSize.xMax = .fX##_Var 
      if .fX##_Var < tSize.xMin then tSize.xMin = .fX##_Var
      
      if .fY##_Var > tSize.yMax then tSize.yMax = .fY##_Var 
      if .fY##_Var < tSize.yMin then tSize.yMin = .fY##_Var
      
      if .fZ##_Var > tSize.zMax then tSize.zMax = .fZ##_Var 
      if .fZ##_Var < tSize.zMin then tSize.zMin = .fZ##_Var      
   #endmacro
        
   with *pPart            
      for N as long = 0 to .iPartCount-1         
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
                  
                  SizeModel( pSubPart , tSize , pRoot )
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
end sub

#ifdef __Tester
   #define DbgConnect rem
#else
   #define DbgConnect printf
#endif

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
end type
sub SnapModel( pPart as DATFile ptr , tSnap as PartSnap , pRoot as DATFile ptr = NULL )
         
   if pRoot = NULL then pRoot = pPart        
   with *pPart
      if .iShadowCount then
         #ifndef __Tester
         printf(!"Shadow Entries=%i (%s)\n",.iShadowCount,GetPartName(pPart))
         #endif
         var iIdent = 2, iPrevRec = 0         
         var pMat = @tMatrixStack(g_CurrentMatrix)
         var fYScale = pMat->fScaleY , YScale = cint(fYScale)
         
         for N as long = 0 to .iShadowCount-1
            with .paShadow[N]
               select case .bType
               case sit_Include
                  iIdent += 2
               case sit_Cylinder
                  static as zstring ptr pzCaps(...)={@"none",@"one",@"two",@"A",@"B"}
                  if iPrevRec>.bRecurse then iIdent -= 2
                  iPrevRec=.bRecurse '4
                  #ifndef __Tester
                  printf(!"%sSecs=%i Gender=%s Caps=%s HasGrid=%s GridX=%i GridZ=%i (Pos=%g,%g,%g)",space(iIdent), _
                  .bSecCnt , iif(.bFlagMale,"M","F") , pzCaps(.bCaps) , iif(.bFlagHasGrid,"Yes","No") , _
                  abs(.tGrid.xCnt) , abs(.tGrid.zCnt) , .fPosX+pMat->fPosX , .fPosY+pMat->fPosY , .fPosZ+pMat->fPosZ )
                  #endif                  
                  for I as long = 0 to .bSecCnt-1
                     static as zstring ptr pzSecs(...)={@"Invalid",@"Round",@"Axle",@"Square",@"FlexPrev",@"FlexNext"}                     
                     with .tSecs(I)
                        #ifndef __Tester 
                        printf(" %s(%g %g)",pzSecs(.bShape),.wFixRadius/100,.bLength*fYScale)
                        #endif
                     end with
                  next I      
                  #ifndef __Tester
                  puts("")
                  #endif                  
                  
                  '>>>>> Detect Shape type (stud,clutch,alias,etc...) >>>>>
                  scope
                     var iConCnt = 1 , bConType = spUnknown , bSecs = .bSecCnt , bSides = 1
                     select case .bCaps
                     case sc_None : bSides = 2
                     case sc_One  : bSides = 1
                     case sc_Two  : puts("!!!!! CHECK TWO CAPS!!!!!")
                     end select
                     
                     'negative xCnt/zCnt are "centered"
                     if .bFlagHasGrid then iConCnt = abs(.tGrid.xCnt)*abs(.tGrid.zCnt)                                           
                     if .bFlagMale then 
                        var iIgnore = 0
                        if iConCnt > 1 then puts("!!!!!! MALE GRID FOUND !!!!!")
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
                              tSnap.lPinCnt += iConCnt : bSecs -= 1  'PIN // bConType = spPin : exit for
                              'bSecs -= 1: 'continuation of the pin must be ignored
                              'puts("Pin" & bSecs)
                           case sss_Round
                              if .tSecs(I).wFixRadius = 800 then
                                 bSecs -= 1 'STOPPER? Ignoring it for now
                                 'puts("Stopper" & bSecs)
                              elseif .tSecs(I).wFixRadius = 400 then
                                 DbgConnect(!"Bar += %i\n",iConCnt)
                                 tSnap.lBarCnt += iConCnt : bSecs -= 1 'BARHOLE
                                 'puts("Bar" & bSecs)
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
                              if .tSecs(I).bLength*YScale = 1 then
                                 puts("Length 1 section ignored")
                                 bSecs -= 1 : continue for 'ignore length=1 sections
                              end if
                              select case .tSecs(I).bShape 
                              case sss_Axle                                 
                                 DbgConnect(!"AxleHole += %i (Axle slide)\n",iConCnt*bSides)
                                 if bDidAxleHole=0 then bDidAxleHole=1 : tSnap.lAxleHoleCnt += iConCnt*bSides 
                                 'AXLEHOLE //bConType = spAxleHole: exit for 
                                 'if there's an axlehole then it can't be a pinhole, and it can't have dual clutches
                                 bSecs -= 1 : iMaybePins=-999 : bSides = 1
                              case sss_Square   
                                 DbgConnect(!"Clutch += %i (Square slide)\n",iConCnt)
                                 DbgConnect(!"BarHole += %i (Square slide)\n",iConCnt*bSides)
                                 if bDidClutch=0  then bDidClutch=1  : tSnap.lClutchCnt  += iConCnt
                                 if bDidBarHole=0 then bDidBarHole=1 : tSnap.lBarHoleCnt += iConCnt*bSides
                                 bSecs -= 1 'BARHOLE //bConType = spBarHole: exit for
                              case sss_Round
                                 select case .tSecs(I).wFixRadius
                                 case 800: bSecs -= 1 '???? (anti-stopper??)
                                 case 600: iMaybePins += 1 
                                 case 400
                                    DbgConnect(!"BarHole += %i (Round slide)\n",iConCnt*bSides)
                                    if bDidBarHole=0 then bDidBarHole=1 : tSnap.lBarHoleCnt += iConCnt*bSides 
                                    bSecs -= 1 'BARHOLE
                                 end select                                 
                              end select
                           next I
                           if iMaybePins>0 then 
                              DbgConnect(!"Clutch += %i (round slide from pin?)\n",iConCnt*iMaybePins*bSides )
                              DbgConnect(!"PinHole += %i (round slide )\n", iConCnt*iMaybePins)
                              tSnap.lClutchCnt += iConCnt*iMaybePins*bSides 
                              tSnap.lPinHoleCnt += iConCnt*iMaybePins : bSecs -= iMaybePins 'PINHOLE
                           end if
                        else 'BARHOLE / CLUTCH / KingPin (fat)
                           dim as byte bDidPinHole,bDidBarHole
                           for I as long = 0 to .bSecCnt-1                              
                              'if .tSecs(I).wFixRadius > 600 then bConType = spPinHole : exit for
                              select case .tSecs(I).bShape
                              case sss_Axle
                                 puts("Axle hole without slide??????")
                              case sss_FlexPrev
                                 DbgConnect(!"PinHole += %i (FlexPrev)\n",iConCnt)
                                 if bDidPinHole=0 then bDidPinHole=1 : tSnap.lPinHoleCnt += iConCnt 
                                 bSecs -= 1: 'bConType = spPinHole
                              case sss_Round 'barholes have radius of 4.0
                                 if .tSecs(I).wFixRadius = 400 then 
                                    DbgConnect(!"BarHole += %i (Round)\n",iConCnt*bSides)
                                    if bDidBarHole=0 then bDidBarHole = 1 : tSnap.lBarHoleCnt += iConCnt*bSides 
                                    bSecs -= 1 'bConType = spBarhole : exit for 'BARHOLE
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
                           DbgConnect(!"Stud += %i (Fallback)\n",iConCnt)
                           tSnap.lStudCnt     += iConCnt
                           '#ifndef __Tester
                           'puts("!!! FALLBACK STUD !!!")
                           '#endif
                        case spClutch  
                           'printf(!"Sides=%i\n",bSides)
                           DbgConnect(!"Clutch += %i (Fallback)\n",iConCnt)
                           tSnap.lClutchCnt   += iConCnt '*bSides 
                           '#ifndef __Tester
                           'puts("!!! FALLBACK CLUTCH !!!")
                           '#endif
                        case spAlias   
                           DbgConnect(!"Alias += %i (Fallback)\n",iConCnt)
                           tSnap.lAliasCnt    += iConCnt
                        case spBar     
                           DbgConnect(!"Bar += %i (Fallback)\n",iConCnt)
                           tSnap.lBarCnt      += iConCnt
                        case spBarHole : tSnap.lBarHoleCnt  += iConCnt*bSides
                           DbgConnect(!"BarHole += %i (Fallback)\n",iConCnt)
                        case spPin     : tSnap.lPinCnt      += iConCnt 
                           DbgConnect(!"Pin += %i (Fallback)\n",iConCnt)
                        case spPinHole 
                           DbgConnect(!"PinHole += %i (Fallback)\n",iConCnt)
                           tSnap.lPinHoleCnt  += iConCnt
                           '#ifndef __Tester
                           'puts("!!! FALLBACK PINHOLE !!!")
                           '#endif
                        case spAxle    
                           DbgConnect(!"Axle += %i (Fallback)\n",iConCnt)
                           tSnap.lAxleCnt     += iConCnt
                        case spAxleHole
                           DbgConnect(!"AxleHole += %i (Fallback)\n",iConCnt)
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
                  'var sName = *cptr(zstring ptr,strptr(g_sFilenames)+g_tModels(.lModelIndex).iFilenameOffset+6)
                  
                  dim as single fMatrix(15) = { _
                    .fA , .fD , .fG , 0 , _ 'X scale ,    0?   ,   0?    , 0 
                    .fB , .fE , .fH , 0 , _ '  0?    , Y Scale ,   0?    , 0 
                    .fC , .fF , .fI , 0 , _ '  0?    ,    0?   , Z Scale , 0 
                    .fX , .fY , .fZ , 1 }   ' X Pos  ,  Y Pos  ,  Z Pos  , 1 
                  
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
