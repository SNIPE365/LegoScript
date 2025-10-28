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

function GetModelVertexCount( pPart as DATFile ptr , iBorders as long , lDrawPart as long = -1 , byref lCurPos as long = 0 ) as ulong
                    
   with *pPart
      for N as long = 0 to .iPartCount-1                           
         dim as byte bDoDraw = (lDrawPart<0 orelse lDrawPart=N)         
         with .tParts(N)            
            select case .bType
            case 1               
               var T1 = ._1
               with T1
                  if bDoDraw then
                     var pSubPart = g_tModels(.lModelIndex).pModel                     
                     GetModelVertexCount( pSubPart , iBorders , iif(lDrawPart=-2,-2,-1) , lCurPos )
                  end if                  
               end with               
            case 2               
               if iBorders=0 andalso lDrawPart <> N then continue for               
               lCurPos += 2               
            case 3
               if iBorders orelse bDoDraw=0 then continue for                                 
               lCurPos += 3
            case 4               
               if iBorders orelse bDoDraw=0 then continue for
               lCurPos += 6
            case 5               
               if iBorders=0 orelse bDoDraw=0 then continue for               
               lCurPos += 2
            end select
         end with
      next N                  
   end with
      
   return lCurPos
   
end function
function GenArrayModel( pPart as DATFile ptr , aVertex() as VertexStruct , iBorders as long , uCurrentColor as ulong = &h70605040 , lDrawPart as long = -1 , byref lCurPos as long = -1 , uCurrentEdge as ulong = 0 DebugPrimParm ) as ulong
   if uCurrentColor = &h70605040 then uCurrentColor = g_Colours(c_Blue) : uCurrentEdge = g_EdgeColours(c_Blue)
   
   const cBlockCnt = 1 shl 21
   
   dim as boolean bMain = false
   if lCurPos < 0 then 
      var uVtx = GetModelVertexCount( pPart , iBorders )
      redim aVertex( uVtx-1 ) : lCurPos = 0 : bMain = true
      var iSz = ((uVtx*sizeof(aVertex(0)))\1024)
      if iSz > 2047 then
         puts("Sz: " & (iSz+1023)\1024 & "mb")
      else
         puts("Sz: " & iSz & "kb")
      end if
   end if
   
   
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
                     #ifdef DebugPrimitive
                        var sName = *cptr(zstring ptr,strptr(g_sFilenames)+g_tModels(.lModelIndex).iFilenameOffset+6)
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
                     GenArrayModel( pSubPart , aVertex() , iBorders , uColor , iif(lDrawPart=-2,-2,-1) , lCurPos , uEdge DebugPrimIdent )
                     PopMatrix()
                  end if                  
               end with               
            case 2               
               if iBorders=0 andalso lDrawPart <> N then continue for
               'glPushMatrix() : glMultMatrixf( @fMatrix(0) )
               
               var T2 = ._2               
               MultiplyMatrixVector( @T2.fX1 )
               MultiplyMatrixVector( @T2.fX2 )
               SetLineNormal( T2 , @aVertex(lCurPos).tNormal )
                                             
               with T2
                  #ifdef DebugPrimitive
                  puts _
                     " fX1:" & .fX1 & " fY1:" & .fY1 & " fZ1:" & .fZ1 & _
                     " fX2:" & .fX2 & " fY2:" & .fY2 & " fZ2:" & .fZ2
                  #endif
                  
                  aVertex(lCurPos).uColor = ((uEdge shr iif(lDrawPart=-2,2,0)) and &hFF000000) or (uEdge and &hFFFFFF)                                                      
                  aVertex(lCurPos  ).tPos    = type(.fX1*cScale,.fY1*cScale,.fZ1*cScale)
                  aVertex(lCurPos+1).tPos    = type(.fX2*cScale,.fY2*cScale,.fZ2*cScale)
                  aVertex(lCurPos+1).tNormal = aVertex(lCurPos).tNormal
                  aVertex(lCurPos+1).uColor  = aVertex(lCurPos).uColor
                  
                  lCurPos += 2
                  
               end with
            case 3
               if iBorders orelse bDoDraw=0 then continue for
               var T3 = ._3               
               MultiplyMatrixVector( @T3.fX1 ) 
               MultiplyMatrixVector( @T3.fX2 )
               MultiplyMatrixVector( @T3.fX3 )
               SetTrigNormal( T3 , @aVertex(lCurPos).tNormal )
               with T3
                  #ifdef DebugPrimitive
                     puts _
                        " fX1:" & .fX1 & " fY1:" & .fY1 & " fZ1:" & .fZ1 & _
                        " fX2:" & .fX2 & " fY2:" & .fY2 & " fZ2:" & .fZ2 & _
                        " fX3:" & .fX3 & " fY3:" & .fY3 & " fZ3:" & .fZ3
                  #endif
                  
                  aVertex(lCurPos).uColor = uColor
                  aVertex(lCurPos  ).tPos    = type(.fX1*cScale,.fY1*cScale,.fZ1*cScale)
                  aVertex(lCurPos+1).tPos    = type(.fX2*cScale,.fY2*cScale,.fZ2*cScale)
                  aVertex(lCurPos+1).tNormal = aVertex(lCurPos).tNormal
                  aVertex(lCurPos+1).uColor  = aVertex(lCurPos).uColor                  
                  aVertex(lCurPos+2).tPos    = type(.fX3*cScale,.fY3*cScale,.fZ3*cScale)
                  aVertex(lCurPos+2).tNormal = aVertex(lCurPos).tNormal
                  aVertex(lCurPos+2).uColor  = aVertex(lCurPos).uColor                  
                  
                  lCurPos += 3
                  
               end with
            case 4               
               if iBorders orelse bDoDraw=0 then continue for
               var T4 = ._4               
               MultiplyMatrixVector( @T4.fX1 ) 
               MultiplyMatrixVector( @T4.fX2 )
               MultiplyMatrixVector( @T4.fX3 )
               MultiplyMatrixVector( @T4.fX4 )               
               SetQuadNormal( T4 , @aVertex(lCurPos).tNormal )
               'SetTrigNormal( *cptr( typeof(._3) ptr , @T4 ) ) 'just need the line
               with T4
                  #ifdef DebugPrimitive
                     puts _
                        " fX1:" & .fX1 & " fY1:" & .fY1 & " fZ1:" & .fZ1 & _
                        " fX2:" & .fX2 & " fY2:" & .fY2 & " fZ2:" & .fZ2 & _
                        " fX3:" & .fX3 & " fY3:" & .fY3 & " fZ3:" & .fZ3 & _
                        " fX4:" & .fX4 & " fY4:" & .fY4 & " fZ4:" & .fZ4
                  #endif
                  
                  aVertex(lCurPos  ).uColor = uColor
                  aVertex(lCurPos  ).tPos    = type(.fX1*cScale,.fY1*cScale,.fZ1*cScale)
                  aVertex(lCurPos+1).tPos    = type(.fX2*cScale,.fY2*cScale,.fZ2*cScale)
                  aVertex(lCurPos+1).tNormal = aVertex(lCurPos).tNormal
                  aVertex(lCurPos+1).uColor  = aVertex(lCurPos).uColor                  
                  aVertex(lCurPos+2).tPos    = type(.fX3*cScale,.fY3*cScale,.fZ3*cScale)
                  aVertex(lCurPos+2).tNormal = aVertex(lCurPos).tNormal
                  aVertex(lCurPos+2).uColor  = aVertex(lCurPos).uColor                  
                  aVertex(lCurPos+3).tPos    = type(.fX1*cScale,.fY1*cScale,.fZ1*cScale)                  
                  aVertex(lCurPos+3).tNormal = aVertex(lCurPos).tNormal
                  aVertex(lCurPos+3).uColor  = aVertex(lCurPos).uColor                  
                  aVertex(lCurPos+4).tPos    = type(.fX3*cScale,.fY3*cScale,.fZ3*cScale)
                  aVertex(lCurPos+4).tNormal = aVertex(lCurPos).tNormal
                  aVertex(lCurPos+4).uColor  = aVertex(lCurPos).uColor                  
                  aVertex(lCurPos+5).tPos    = type(.fX4*cScale,.fY4*cScale,.fZ4*cScale)
                  aVertex(lCurPos+5).tNormal = aVertex(lCurPos).tNormal
                  aVertex(lCurPos+5).uColor  = aVertex(lCurPos).uColor                  
                  
                  lCurPos += 6                  
                  
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
                     
                     aVertex(lCurPos  ).uColor  = rgb(0,255,0,85)
                     aVertex(lCurPos  ).tPos    = type(.fX1*cScale,.fY1*cScale,.fZ1*cScale)
                     aVertex(lCurPos+1).tPos    = type(.fX2*cScale,.fY2*cScale,.fZ2*cScale)
                     aVertex(lCurPos+1).tNormal = aVertex(lCurPos).tNormal
                     aVertex(lCurPos+1).uColor  = aVertex(lCurPos).uColor
                  
                     lCurPos += 2                     
                     
                  #endif
               end with
            end select
         end with
      next N      
      'next M
      iOnce = 1
   end with
   
   if bMain then 
     if (lCurPos-1) > ubound(aVertex) then
       puts("BUFFER OVERFLOW!")
       getchar():system
      end if
     'redim preserve aVertex(lCurPos-1)   
   end if
   return lCurPos
   
end function

function AllocateModelDrawArrays( pPart as DATFile ptr , tDraw as ModelDrawArrays , bFlags as byte = 1 ) as boolean
  const bRoot=1 , bNewPart=2 , bPart=4
  with *pPart 'include: "andalso .bHasVBO=0"
    if .bIsUnique andalso .bHasCNT=0 then .bHasCNT=1 : bFlags or= (bNewPart or bPart)
    for N as long = 0 to .iPartCount-1
      with .tParts(N)
        select case .bType
        case 1 'include
          with ._1
            var pSubPart = g_tModels(.lModelIndex).pModel
            AllocateModelDrawArrays( pSubPart , tDraw , (bFlags and bPart) )
          end with          
        case 2 'line
          if (bFlags and bPart)=0 then continue for
          if .wColour = c_Edge_Colour then
            tDraw.lBorderCnt += 2
          else
            tDraw.lColorBrdCnt += 2
          end if
        case 3 'triangle
          if (bFlags and bPart)=0 then continue for
          if .wColour = c_Main_Colour then
            tDraw.lTriangleCnt += 3
          else
            tDraw.lColorTriCnt += 3
          end if
        case 4 'quad
          if (bFlags and bPart)=0 then continue for
          if .wColour = c_Main_Colour then
            tDraw.lTriangleCnt += 6
          else
            tDraw.lColorTriCnt += 6
          end if
        case 5 'optional line
          #ifdef RenderOptionals
            if bFlags.bPart=0 then continue for
            if .wColour = c_Edge_Colour then
              tDraw.lBorderCnt += 2
            else
              tDraw.lColorBrdCnt += 2
            end if
          #endif
        end select
      end with
    next N
    if .bIsUnique then
      tDraw.lPieceCount += 1 
      if (bFlags and bNewPart) then 
        tDraw.lUniquePieces += 1 : bFlags and= (not (bNewPart or bPart))            
      end if
    end if    
  end with      
  if (bFlags and bRoot) then
    with tDraw      
      #define Init( _Member ) .p##_Member##Vtx = iif(.l##_Member##Cnt,malloc(.l##_Member##cnt * sizeof(typeof(*.p##_Member##Vtx))),NULL)
      Init( Triangle ) : Init( TransTri ) : Init( Border )
      Init( ColorTri ) : Init( TrColTri ) : Init( ColorBrd )      
      .pPieces = iif( .lPieceCount , malloc( sizeof(typeof(*.pPieces)) * (.lPieceCount) ) , NULL )
    end with
  end if    
  return true
end function
function GenModelDrawArrays( pPart as DATFile ptr , tDraw as ModelDrawArrays, uCurrentColor as ulong = 0, uCurrentEdge as ulong = 0 , bFlags as byte = 1 ) as ulong
  const bRoot=1 , bNewPart=2 , bPart=4
  static as long _lTriangleCnt , _lColorTriCnt , _lBorderCnt , _lTransTriCnt , _lTrColTriCnt , _lColorBrdCnt , _lPieceCount
  
  if (bFlags and bRoot) then
    AllocateModelDrawArrays( pPart , tDraw )        
    with tDraw 'show info
      puts("Number of Pieces: " & .lPieceCount & " Unique: " & .lUniquePieces)        
      puts("Vtx Tri: " & .lTriangleCnt & " , Vtx CTri: " & .lColorTriCnt & _
      " , Vtx Brd: " & .lBorderCnt & " , Vtx CBrd: " & .lColorBrdCnt )
        
      puts ((.lPieceCount*sizeof(DisplayPiece)+ _
        .lTriangleCnt*sizeof(VertexStructNoColor)+ _
        .lBorderCnt*sizeof(VertexStructNoColor) + _
        .lColorTriCnt*sizeof(VertexStruct)+ _
        .lColorBrdCnt*sizeof(VertexStruct) ) _
        +1023)\1024 & "kb"
        
    end with
    with tDraw 'store temp counts and reset for re-count
      _lTriangleCnt = .lTriangleCnt : _lColorTriCnt = .lColorTriCnt 
      _lBorderCnt   = .lBorderCnt   : _lTransTriCnt = .lTransTriCnt 
      _lTrColTriCnt = .lTrColTriCnt : _lColorBrdCnt = .lColorBrdCnt
      _lPieceCount  = .lPieceCount
      .lTriangleCnt = 0 : .lColorTriCnt = 0 : .lBorderCnt   = 0
      .lTransTriCnt = 0 : .lTrColTriCnt = 0 : .lColorBrdCnt = 0 
      .lPieceCount = 0
    end with
    uCurrentColor = g_Colours(c_Blue) : uCurrentEdge = g_EdgeColours(c_Blue)
  end if   
  
  var uEdge = uCurrentEdge  
         
  with *pPart    
    'if it's a unique piece then start storing a new piece
    if .bIsUnique then       
      with tDraw.pPieces[tDraw.lPieceCount]        
        .pModel  = pPart
        .tMatrix = tCurrentMatrix()
        .lBaseColor = uCurrentColor
        .lBaseEdge  = uCurrentEdge
      end with
      if .bHasCNT then
        .bHasCNT = 0 : .bHasVBO = 1 : bFlags or= (bNewPart or bPart)
        with .tVBO          
          .lTriangleOff = tDraw.lTriangleCnt
          .lColorTriOff = tDraw.lColorTriCnt
          .lTransTriOff = tDraw.lTransTriCnt 
          .lTrColTriOff = tDraw.lTrColTriCnt 
          .lBorderOff   = tDraw.lBorderCnt   
          .lColorBrdOff = tDraw.lColorBrdCnt 
        end with
      end if
      PushIdentityMatrix()
    end if
    
    for N as long = 0 to .iPartCount-1
      dim as ulong uColor = any', uEdge = any
      with .tParts(N)
        var wColour = .wColour
        if .wColour = c_Main_Colour then 'inherit
          uColor = uCurrentColor ': uEdge = uCurrentEdge
        elseif .wColour <> c_Edge_Colour then
          if .wColour > ubound(g_Colours) then
            puts("Bad Color: " & .wColour)
          end if
          uColor = g_Colours(.wColour)
        end if      
        select case .bType
        case 1 'includes
          'if wColour <> c_Main_Colour then printf("@")
          'uEdge = rgb(rnd*255,rnd*255,rnd*255)
          uEdge = ((uColor and &hFEFEFE) shr 1) or (uColor and &hFF000000)
          'g_EdgeColours(.wColour)
          var T1 = ._1
          with T1          
            var pSubPart = g_tModels(.lModelIndex).pModel            
            #ifdef DebugPrimitive
              var sName = *cptr(zstring ptr,strptr(g_sFilenames)+g_tModels(.lModelIndex).iFilenameOffset+6)
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
            GenModelDrawArrays( pSubPart , tDraw, uColor , uEdge , (bFlags and bPart) )
            PopMatrix()        
          end with               
        case 2 'line
          if (bFlags and bPart)=0 then continue for
          var T2 = ._2 , bIsDefaultColor = (.wColour = c_Edge_Colour)
          MultiplyMatrixVector( @T2.fX1 )
          MultiplyMatrixVector( @T2.fX2 )
          dim as Vertex3 tNormal = any
          SetLineNormal( T2 , @tNormal )                                       
          with T2
            #ifdef DebugPrimitive
            puts _
               " fX1:" & .fX1 & " fY1:" & .fY1 & " fZ1:" & .fZ1 & _
               " fX2:" & .fX2 & " fY2:" & .fY2 & " fZ2:" & .fZ2
            #endif
            
            if bIsDefaultColor then
              var pVtx = tDraw.pBorderVtx+tDraw.lBorderCnt : tDraw.lBorderCnt += 2
              pVtx[0].tPos    = type(.fX1*cScale,.fY1*cScale,.fZ1*cScale)              
              pVtx[0].tNormal = tNormal
              pVtx[1].tPos    = type(.fX2*cScale,.fY2*cScale,.fZ2*cScale)
              pVtx[1].tNormal = pVtx[0].tNormal              
            else
              var pVtx = tDraw.pColorBrdVtx+tDraw.lColorBrdCnt : tDraw.lColorBrdCnt += 2                                        
              pVtx[0].tPos    = type(.fX1*cScale,.fY1*cScale,.fZ1*cScale)
              pVtx[0].tNormal = tNormal
              pVtx[0].uColor = ((uEdge shr 2) and &hFF000000) or (uEdge and &hFFFFFF)
              pVtx[1].tPos    = type(.fX2*cScale,.fY2*cScale,.fZ2*cScale)
              pVtx[1].tNormal = tNormal
              pVtx[1].uColor  = pVtx[0].uColor
            end if
            
          end with
        case 3 'triangle
          if (bFlags and bPart)=0 then continue for
          var T3 = ._3 , bIsDefaultColor = (.wColour = c_Main_Colour)
          MultiplyMatrixVector( @T3.fX1 ) 
          MultiplyMatrixVector( @T3.fX2 )
          MultiplyMatrixVector( @T3.fX3 )
          dim as vertex3 tNormal = any
          SetTrigNormal( T3 , @tNormal )
          
          with T3
            #ifdef DebugPrimitive
               puts _
                  " fX1:" & .fX1 & " fY1:" & .fY1 & " fZ1:" & .fZ1 & _
                  " fX2:" & .fX2 & " fY2:" & .fY2 & " fZ2:" & .fZ2 & _
                  " fX3:" & .fX3 & " fY3:" & .fY3 & " fZ3:" & .fZ3
            #endif            
            if bIsDefaultColor then
              var pVtx = tDraw.pTriangleVtx+tDraw.lTriangleCnt : tDraw.lTriangleCnt += 3
              pVtx[0].tPos    = type(.fX1*cScale,.fY1*cScale,.fZ1*cScale)
              pVtx[0].tNormal = tNormal              
              pVtx[1].tPos    = type(.fX2*cScale,.fY2*cScale,.fZ2*cScale)
              pVtx[1].tNormal = tNormal              
              pVtx[2].tPos    = type(.fX3*cScale,.fY3*cScale,.fZ3*cScale)
              pVtx[2].tNormal = tNormal              
            else
              var pVtx = tDraw.pColorTriVtx+tDraw.lColorTriCnt : tDraw.lColorTriCnt += 3              
              pVtx[0].tPos    = type(.fX1*cScale,.fY1*cScale,.fZ1*cScale)
              pVtx[0].tNormal = tNormal
              pVtx[0].uColor  = uColor
              pVtx[1].tPos    = type(.fX2*cScale,.fY2*cScale,.fZ2*cScale)
              pVtx[1].tNormal = tNormal
              pVtx[1].uColor  = uColor
              pVtx[2].tPos    = type(.fX3*cScale,.fY3*cScale,.fZ3*cScale)
              pVtx[2].tNormal = tNormal
              pVtx[2].uColor  = uColor
            end if            
          end with
        case 4 'quad
          if (bFlags and bPart)=0 then continue for
          var T4 = ._4 , bIsDefaultColor = (.wColour = c_Main_Colour)              
          MultiplyMatrixVector( @T4.fX1 ) 
          MultiplyMatrixVector( @T4.fX2 )
          MultiplyMatrixVector( @T4.fX3 )
          MultiplyMatrixVector( @T4.fX4 )               
          dim as vertex3 tNormal = any
          SetQuadNormal( T4 , @tNormal )          
          with T4
            #ifdef DebugPrimitive
               puts _
                  " fX1:" & .fX1 & " fY1:" & .fY1 & " fZ1:" & .fZ1 & _
                  " fX2:" & .fX2 & " fY2:" & .fY2 & " fZ2:" & .fZ2 & _
                  " fX3:" & .fX3 & " fY3:" & .fY3 & " fZ3:" & .fZ3 & _
                  " fX4:" & .fX4 & " fY4:" & .fY4 & " fZ4:" & .fZ4
            #endif
            
            if bIsDefaultColor then
              var pVtx = tDraw.pTriangleVtx+tDraw.lTriangleCnt : tDraw.lTriangleCnt += 6
              pVtx[0].tPos    = type(.fX1*cScale,.fY1*cScale,.fZ1*cScale)
              pVtx[0].tNormal = tNormal
              pVtx[1].tPos    = type(.fX2*cScale,.fY2*cScale,.fZ2*cScale)
              pVtx[1].tNormal = tNormal
              pVtx[2].tPos    = type(.fX3*cScale,.fY3*cScale,.fZ3*cScale)
              pVtx[2].tNormal = tNormal
              pVtx[3].tPos    = type(.fX1*cScale,.fY1*cScale,.fZ1*cScale)
              pVtx[3].tNormal = tNormal
              pVtx[4].tPos    = type(.fX3*cScale,.fY3*cScale,.fZ3*cScale)
              pVtx[4].tNormal = tNormal
              pVtx[5].tPos    = type(.fX4*cScale,.fY4*cScale,.fZ4*cScale)
              pVtx[5].tNormal = tNormal              
            else
              var pVtx = tDraw.pColorTriVtx+tDraw.lColorTriCnt : tDraw.lColorTriCnt += 6
              pVtx[0].uColor  = uColor
              pVtx[0].tPos    = type(.fX1*cScale,.fY1*cScale,.fZ1*cScale)
              pVtx[0].tNormal = tNormal
              pVtx[1].tPos    = type(.fX2*cScale,.fY2*cScale,.fZ2*cScale)
              pVtx[1].tNormal = tNormal
              pVtx[1].uColor  = uColor
              pVtx[2].tPos    = type(.fX3*cScale,.fY3*cScale,.fZ3*cScale)
              pVtx[2].tNormal = tNormal
              pVtx[2].uColor  = uColor
              pVtx[3].tPos    = type(.fX1*cScale,.fY1*cScale,.fZ1*cScale)
              pVtx[3].tNormal = tNormal
              pVtx[3].uColor  = uColor
              pVtx[4].tPos    = type(.fX3*cScale,.fY3*cScale,.fZ3*cScale)
              pVtx[4].tNormal = tNormal
              pVtx[4].uColor  = uColor
              pVtx[5].tPos    = type(.fX4*cScale,.fY4*cScale,.fZ4*cScale)
              pVtx[5].tNormal = tNormal
              pVtx[5].uColor  = uColor
            end if
            
          end with
        case 5 'opt line
          #ifdef RenderOptionals
            if (bFlags and bPart)=0 then continue for
            var T5 = ._5 , bIsDefaultColor = (.wColour = c_Edge_Colour)              
            MultiplyMatrixVector( @T5.fX1 )
            MultiplyMatrixVector( @T5.fX2 )
            #ifdef DebugPrimitive
               puts _
                  " fX1:" & .fX1 & " fY1:" & .fY1 & " fZ1:" & .fZ1 & _
                  " fX2:" & .fX2 & " fY2:" & .fY2 & " fZ2:" & .fZ2 & _
                  " fXA:" & .fX3 & " fYA:" & .fY3 & " fZA:" & .fZ3 & _
                  " fXB:" & .fX4 & " fYB:" & .fY4 & " fZB:" & .fZ4
            #endif
            dim as Vertex3 tNormal = any
            SetLineNormal( *cptr( typeof(._2) ptr , @T5 ) , @tNormal )
            with T5
              #ifdef DebugPrimitive
              puts _
                 " fX1:" & .fX1 & " fY1:" & .fY1 & " fZ1:" & .fZ1 & _
                 " fX2:" & .fX2 & " fY2:" & .fY2 & " fZ2:" & .fZ2
              #endif
              
              if bIsDefaultColor then
                var pVtx = tDraw.pBorderVtx+tDraw.lBorderCnt : tDraw.lBorderCnt += 2
                pVtx[0].tPos    = type(.fX1*cScale,.fY1*cScale,.fZ1*cScale)              
                pVtx[0].tNormal = tNormal
                pVtx[1].tPos    = type(.fX2*cScale,.fY2*cScale,.fZ2*cScale)
                pVtx[1].tNormal = pVtx[0].tNormal              
              else
                var pVtx = tDraw.pColorBrdVtx+tDraw.lColorBrdCnt : tDraw.lColorBrdCnt += 2                                        
                pVtx[0].tPos    = type(.fX1*cScale,.fY1*cScale,.fZ1*cScale)
                pVtx[0].tNormal = tNormal
                pVtx[0].uColor = ((uEdge shr 2) and &hFF000000) or (uEdge and &hFFFFFF)
                pVtx[1].tPos    = type(.fX2*cScale,.fY2*cScale,.fZ2*cScale)
                pVtx[1].tNormal = tNormal
                pVtx[1].uColor  = pVtx[0].uColor
              end if
              
            end with
          #endif
        end select
      end with
    next N
    
    if .bIsUnique then
      if (bFlags and bNewPart) then
        bFlags and= (not (bNewPart or bPart))
        with .tVBO
          .lTriangleCnt = tDraw.lTriangleCnt-.lTriangleOff
          .lColorTriCnt = tDraw.lColorTriCnt-.lColorTriOff
          .lTransTriCnt = tDraw.lTransTriCnt-.lTransTriOff
          .lTrColTriCnt = tDraw.lTrColTriCnt-.lTrColTriOff
          .lBorderCnt   = tDraw.lBorderCnt  -.lBorderOff
          .lColorBrdCnt = tDraw.lBorderCnt  -.lColorBrdOff
        end with
      end if
      PopMatrix()
      tDraw.lPieceCount += 1
    end if    
    
  end with
  
  if (bFlags and bRoot) then
    with tDraw
      var bFailed = 0
      if _lTriangleCnt <> .lTriangleCnt then puts "mismatch Triangle: " & _lTriangleCnt & " <> " & .lTriangleCnt : bFailed = 1
      if _lColorTriCnt <> .lColorTriCnt then puts "mismatch ColorTri: " & _lColorTriCnt & " <> " & .lColorTriCnt : bFailed = 1
      if _lBorderCnt   <> .lBorderCnt   then puts "mismatch Border..: " & _lBorderCnt   & " <> " & .lBorderCnt   : bFailed = 1
      if _lTransTriCnt <> .lTransTriCnt then puts "mismatch TransTri: " & _lTransTriCnt & " <> " & .lTransTriCnt : bFailed = 1
      if _lTrColTriCnt <> .lTrColTriCnt then puts "mismatch TrColTri: " & _lTrColTriCnt & " <> " & .lTrColTriCnt : bFailed = 1
      if _lColorBrdCnt <> .lColorBrdCnt then puts "mismatch ColorBrd: " & _lColorBrdCnt & " <> " & .lColorBrdCnt : bFailed = 1
      if _lPieceCount  <> .lPieceCount  then puts "mismatch Pieces..: " & _lPieceCount  & " <> " & .lPieceCount  : bFailed = 1
      if bFailed then getchar()
    end with        
  end if
  
  return tDraw.lPieceCount
   
end function

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
   
   #ifdef DebugShadow
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
                                       #ifdef DebugShadow
                                       DrawMaleShape( __Position__ , p->wFixRadius/100 , p->bLength , bRound , "" & iMale )
                                       #endif
                                    #endif
                                 'end if
                              else
                                 'if lDrawPart <> -2 then 
                                    iFemale += 1
                                    #ifndef __NoRender
                                       #ifdef DebugShadow
                                          DrawFemaleShape( __Position__ , p->wFixRadius/100 , p->bLength , bRound , "" & iFemale ) '*(pMat->fScaleY)
                                       #endif
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

#macro DrawColorVBO( _vbo , _type , _count )
   glBindBuffer(GL_ARRAY_BUFFER, _vbo )          
   glEnableClientState(GL_VERTEX_ARRAY)
   glEnableClientState(GL_NORMAL_ARRAY)
   glEnableClientState(GL_COLOR_ARRAY)         
   glVertexPointer(3, GL_FLOAT        , sizeof(VertexStruct), cast(any ptr,offsetof(VertexStruct,tPos   )) )
   glNormalPointer(   GL_FLOAT        , sizeof(VertexStruct), cast(any ptr,offsetof(VertexStruct,tNormal)) )
   glColorPointer (4, GL_UNSIGNED_BYTE, sizeof(VertexStruct), cast(any ptr,offsetof(VertexStruct,uColor )) )
   glDrawArrays(_type, 0, _count )
   glDisableClientState(GL_COLOR_ARRAY)
   glDisableClientState(GL_NORMAL_ARRAY)
   glDisableClientState(GL_VERTEX_ARRAY)
#endmacro
#macro DrawVBO( _vbo , _type , _count )   
   glBindBuffer(GL_ARRAY_BUFFER, _vbo )          
   glEnableClientState(GL_VERTEX_ARRAY)
   glEnableClientState(GL_NORMAL_ARRAY)
   'glEnableClientState(GL_COLOR_ARRAY)         
   glVertexPointer(3, GL_FLOAT        , sizeof(VertexStruct), cast(any ptr,offsetof(VertexStruct,tPos   )) )
   glNormalPointer(   GL_FLOAT        , sizeof(VertexStruct), cast(any ptr,offsetof(VertexStruct,tNormal)) )
   'glColorPointer (4, GL_UNSIGNED_BYTE, sizeof(VertexStruct), cast(any ptr,offsetof(VertexStruct,uColor )) )
   glDrawArrays(_type, 0, _count )
   'glDisableClientState(GL_COLOR_ARRAY)
   glDisableClientState(GL_NORMAL_ARRAY)
   glDisableClientState(GL_VERTEX_ARRAY)
#endmacro

#macro DrawPieces( __name , _type , _UseColor )
  #if #__name = "TransTri"
    _DrawPieces( Triangle , _type , _UseColor , true )
  #else
    _DrawPieces( __name , _type , _UseCOlor , false )
  #endif
#endmacro
#macro _DrawPieces( _name , _type , _UseColor , _Transparency )                  
  if .l##_name##Cnt then
    glBindBuffer(GL_ARRAY_BUFFER, i##_name##VBO )
    #if _UseColor                      
      const cVtxSz = sizeof(VertexStruct)
      glEnableClientState(GL_COLOR_ARRAY)
      glVertexPointer(3, GL_FLOAT        , cVtxSz, cast(any ptr,offsetof(VertexStruct,tPos   )) )
      glNormalPointer(   GL_FLOAT        , cVtxSz, cast(any ptr,offsetof(VertexStruct,tNormal)) )                  
      glColorPointer (4, GL_UNSIGNED_BYTE, cVtxSz, cast(any ptr,offsetof(VertexStruct,uColor )) )
    #else
      const cVtxSz = sizeof(VertexStructNoColor)
      glDisableClientState(GL_COLOR_ARRAY)                    
      glVertexPointer(3, GL_FLOAT        , cVtxSz, cast(any ptr,offsetof(VertexStructNoColor,tPos   )) )
      glNormalPointer(   GL_FLOAT        , cVtxSz, cast(any ptr,offsetof(VertexStructNoColor,tNormal)) )                    
    #endif                                                            
    for N as long = 0 to .lPieceCount-1
      with .pPieces[N]                        
        if .pModel andalso .pModel->tVBO.l##_name##Cnt then
          #if #_name = "Triangle"
            #if _Transparency
              if (.lBaseColor and &hFF000000) = &hFF000000 then continue for
            #else                          
              if (.lBaseColor and &hFF000000) <> &hFF000000 then continue for
            #endif
          #endif                          
          glPushMatrix()
          glMultMatrixf( @.tMatrix.m(0) )
          #if _type = GL_LINES
            'var lColor = ((.lBaseColor shr 2) and &hFF000000) or (.lBaseColor and &hFFFFFF)                          
            glColor4ubv( cast(ubyte ptr,@.lBaseEdge) )
          #else
            glColor4ubv( cast(ubyte ptr,@.lBaseColor) )
          #endif                          
          with .pModel->tVBO                            
            glDrawArrays( _type, .l##_name##Off , .l##_name##Cnt )                            
          end with
          glPopMatrix()
        end if
      end with                      
    next N                    
  end if
#endmacro

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