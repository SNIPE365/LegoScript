Type PartCollisionBox As PartSize

Sub GetCollisionBoundaries( tResult As PartCollisionBox , tA As PartCollisionBox , tB As PartCollisionBox )   
    tResult.xMin = IIf(tA.xMin > tB.xMin , tA.xMin , tB.xMin)
    tResult.xMax = IIf(tA.xMax < tB.xMax , tA.xMax , tB.xMax)
    tResult.yMin = IIf(tA.yMin > tB.yMin , tA.yMin , tB.yMin)
    tResult.yMax = IIf(tA.yMax < tB.yMax , tA.yMax , tB.yMax)
    tResult.zMin = IIf(tA.zMin > tB.zMin , tA.zMin , tB.zMin)
    tResult.zMax = IIf(tA.zMax < tB.zMax , tA.zMax , tB.zMax)
End Sub

Function CheckCollision( tA As PartSize , tB As PartSize ) As Byte    
   ' Check X overlap
   If tA.xMax < tB.xMin OrElse tA.xMin > tB.xMax Then Return False        
   ' Check Y overlap
   If tA.yMax < tB.yMin OrElse tA.yMin > tB.yMax Then Return False    
   ' Check Z overlap
   If tA.zMax < tB.zMin OrElse tA.zMin > tB.zMax Then Return False
   Return True
End Function

' =============================================================================
' VECTOR MATH HELPERS
' =============================================================================
Function vec3_Sub(v1 As Vector3, v2 As Vector3) As Vector3
    Return Type(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z)
End Function
Function vec3_Cross(v1 As Vector3, v2 As Vector3) As Vector3
    Return Type(v1.y * v2.z - v1.z * v2.y, v1.z * v2.x - v1.x * v2.z, v1.x * v2.y - v1.y * v2.x)
End Function
Function vec3_Dot(v1 As Vector3, v2 As Vector3) As Single
    Return (v1.x * v2.x + v1.y * v2.y + v1.z * v2.z)
End Function

' -----------------------------------------------------------------------------
' MID-PHASE: Triangle vs AABB bounding box check
' -----------------------------------------------------------------------------
Function CheckTriangleBox(tV0 As Vector3, tV1 As Vector3, tV2 As Vector3, box As PartCollisionBox) As Byte
    Dim As Single triMin, triMax
    
    triMin = tV0.x : triMax = tV0.x
    If tV1.x < triMin Then triMin = tV1.x : If tV1.x > triMax Then triMax = tV1.x
    If tV2.x < triMin Then triMin = tV2.x : If tV2.x > triMax Then triMax = tV2.x
    If triMax < box.xMin OrElse triMin > box.xMax Then Return 0

    triMin = tV0.y : triMax = tV0.y
    If tV1.y < triMin Then triMin = tV1.y : If tV1.y > triMax Then triMax = tV1.y
    If tV2.y < triMin Then triMin = tV2.y : If tV2.y > triMax Then triMax = tV2.y
    If triMax < box.yMin OrElse triMin > box.yMax Then Return 0

    triMin = tV0.z : triMax = tV0.z
    If tV1.z < triMin Then triMin = tV1.z : If tV1.z > triMax Then triMax = tV1.z
    If tV2.z < triMin Then triMin = tV2.z : If tV2.z > triMax Then triMax = tV2.z
    If triMax < box.zMin OrElse triMin > box.zMax Then Return 0
    
    Return 1
End Function

' -----------------------------------------------------------------------------
' NARROW-PHASE: Robust Ray-Triangle Segment Pierce Test
' -----------------------------------------------------------------------------
Function CheckRayTriangleRobust(RayOrigin As Vector3, RayEnd As Vector3, TriV0 As Vector3, TriV1 As Vector3, TriV2 As Vector3, fEpsilon As Single) As Byte
    Dim As Vector3 e1, e2, h, s, q, rayDir
    Dim As Single a, f, u, v, t, rayLen
    
    rayDir = vec3_Sub(RayEnd, RayOrigin)
    rayLen = Sqr(vec3_Dot(rayDir, rayDir))
    If rayLen < fEpsilon Then Return 0 
    
    e1 = vec3_Sub(TriV1, TriV0)
    e2 = vec3_Sub(TriV2, TriV0)
    h = vec3_Cross(rayDir, e2)
    a = vec3_Dot(e1, h)
    
    If a > -0.00001 AndAlso a < 0.00001 Then Return 0 
    
    f = 1.0 / a
    s = vec3_Sub(RayOrigin, TriV0)
    u = f * vec3_Dot(s, h)
    
    ' Shrink the target surface slightly (e.g., 2% of its area) 
    ' to ignore grazing edge touches
    Dim As Single uvTol = 0.25 
    If u < uvTol OrElse u > (1.0 - uvTol) Then Return 0
    
    q = vec3_Cross(s, e1)
    v = f * vec3_Dot(rayDir, q)
    
    If v < uvTol OrElse (u + v) > (1.0 - uvTol) Then Return 0
    
    t = f * vec3_Dot(e2, q)
    
    Dim As Single tTol = fEpsilon / rayLen
    If t > tTol AndAlso t < (1.0 - tTol) Then
        Return 1 
    End If
    
    Return 0
End Function

Function CheckTriangleTriangle(v0 As Vector3, v1 As Vector3, v2 As Vector3, u0 As Vector3, u1 As Vector3, u2 As Vector3) As Byte
    Dim As Single fEpsilon = 0.5 ' Tolerance for LDraw units 
    
    If CheckRayTriangleRobust(v0, v1, u0, u1, u2, fEpsilon) Then Return 1
    If CheckRayTriangleRobust(v1, v2, u0, u1, u2, fEpsilon) Then Return 1
    If CheckRayTriangleRobust(v2, v0, u0, u1, u2, fEpsilon) Then Return 1
    
    If CheckRayTriangleRobust(u0, u1, v0, v1, v2, fEpsilon) Then Return 1
    If CheckRayTriangleRobust(u1, u2, v0, v1, v2, fEpsilon) Then Return 1
    If CheckRayTriangleRobust(u2, u0, v0, v1, v2, fEpsilon) Then Return 1
    
    Return 0 
End Function

' -----------------------------------------------------------------------------
' EXTRACTION: Getting real world coordinates via the matrix stack
' -----------------------------------------------------------------------------
Type CollisionTri
    v1 As Vector3
    v2 As Vector3
    v3 As Vector3
End Type

Sub ExtractModelTriangles( pPart As DATFile Ptr , aTris() As CollisionTri )
    For N As Long = 0 To pPart->iPartCount - 1
        With pPart->tParts(N)
            Select Case .bType
            Case 1 
                Var pSubPart = g_tModels(._1.lModelIndex).pModel
                Dim As Single fMatrix(15) = { ._1.fA , ._1.fD , ._1.fG , 0 , _
                                              ._1.fB , ._1.fE , ._1.fH , 0 , _
                                              ._1.fC , ._1.fF , ._1.fI , 0 , _
                                              ._1.fX , ._1.fY , ._1.fZ , 1 }
                PushAndMultMatrix( @fMatrix(0) )
                ExtractModelTriangles( pSubPart , aTris() )
                PopMatrix()
                
            Case 3 
                Var T3 = ._3
                MultiplyMatrixVector( @T3.fX1 ) 
                MultiplyMatrixVector( @T3.fX2 )
                MultiplyMatrixVector( @T3.fX3 )
                Dim As Long iIdx = UBound(aTris) + 1
                ReDim Preserve aTris(iIdx)
                aTris(iIdx).v1 = Type<Vector3>(T3.fX1, T3.fY1, T3.fZ1)
                aTris(iIdx).v2 = Type<Vector3>(T3.fX2, T3.fY2, T3.fZ2)
                aTris(iIdx).v3 = Type<Vector3>(T3.fX3, T3.fY3, T3.fZ3)
                
            Case 4 
                Var T4 = ._4
                MultiplyMatrixVector( @T4.fX1 ) 
                MultiplyMatrixVector( @T4.fX2 )
                MultiplyMatrixVector( @T4.fX3 )
                MultiplyMatrixVector( @T4.fX4 )
                Dim As Long iIdx = UBound(aTris) + 1
                ReDim Preserve aTris(iIdx + 1)
                aTris(iIdx).v1   = Type<Vector3>(T4.fX1, T4.fY1, T4.fZ1)
                aTris(iIdx).v2   = Type<Vector3>(T4.fX2, T4.fY2, T4.fZ2)
                aTris(iIdx).v3   = Type<Vector3>(T4.fX3, T4.fY3, T4.fZ3)
                aTris(iIdx+1).v1 = Type<Vector3>(T4.fX1, T4.fY1, T4.fZ1)
                aTris(iIdx+1).v2 = Type<Vector3>(T4.fX3, T4.fY3, T4.fZ3)
                aTris(iIdx+1).v3 = Type<Vector3>(T4.fX4, T4.fY4, T4.fZ4)
            End Select
        End With
    Next N
End Sub

' Add this near the top of Collision.bas
Dim Shared g_DebugTris() As CollisionTri

' -----------------------------------------------------------------------------
' MAIN ENTRANCE
' -----------------------------------------------------------------------------
Sub CheckCollisionModel( pPart As DATFile Ptr , atCollision() As PartCollisionBox , pRoot As DATFile Ptr = NULL )
   If pPart = 0 Then Exit Sub
   If pRoot = NULL Then pRoot = pPart
   
   Static As PartCollisionBox AtPartBound()
   Static As PartCollisionBox Ptr ptSize
   
   #macro CheckZ( _Var )       
      If ptSize->xMax=fUnused OrElse .fX##_Var > ptSize->xMax Then ptSize->xMax = .fX##_Var 
      If ptSize->xMin=fUnused OrElse .fX##_Var < ptSize->xMin Then ptSize->xMin = .fX##_Var
      If ptSize->yMax=fUnused OrElse .fY##_Var > ptSize->yMax Then ptSize->yMax = .fY##_Var 
      If ptSize->yMin=fUnused OrElse .fY##_Var < ptSize->yMin Then ptSize->yMin = .fY##_Var
      If ptSize->zMax=fUnused OrElse .fZ##_Var > ptSize->zMax Then ptSize->zMax = .fZ##_Var 
      If ptSize->zMin=fUnused OrElse .fZ##_Var < ptSize->zMin Then ptSize->zMin = .fZ##_Var
   #endmacro
   
   If pPart=pRoot Then 
      ReDim AtPartBound(pPart->iPartCount-1)      
      ReDim atCollision(0)
      Erase g_DebugTris 'Debug ARRAY
      PushIdentityMatrix()
   End If

   With *pPart 
      If .tSize.zMax = .tSize.zMin Then         
         Dim As PartSize tSz : SizeModel( pPart , tSz ) : .tSize = tSz                  
      End If
      For N As Long = 0 To .iPartCount-1         
         If pPart=pRoot Then 
            With AtPartBound(N)
               .xMin = fUnused : .xMax = fUnused : .yMin = fUnused 
               .yMax = fUnused : .zMin = fUnused : .zMax = fUnused
            End With
            ptSize = @AtPartBound(N)       
         End If         

         With .tParts(N)            
            Select Case .bType
            Case 1                 
               With ._1
                  Var pSubPart = g_tModels(.lModelIndex).pModel
                  Dim As Single fMatrix(15) = { .fA , .fD , .fG , 0 , .fB , .fE , .fH , 0 , .fC , .fF , .fI , 0 , .fX , .fY , .fZ , 1 }
                  PushAndMultMatrix( @fMatrix(0) )
                  CheckCollisionModel( pSubPart , atCollision() , pRoot )
                  PopMatrix()                  
               End With                
            Case 2               
               Var T2 = ._2 
               MultiplyMatrixVector( @T2.fX1 ) 
               MultiplyMatrixVector( @T2.fX2 )
               With T2 
                  CheckZ(1) 
                  CheckZ(2) 
               End With
            Case 3               
               Var T3 = ._3 
               MultiplyMatrixVector( @T3.fX1 ) 
               MultiplyMatrixVector( @T3.fX2 ) 
               MultiplyMatrixVector( @T3.fX3 )
               With T3 
                  CheckZ(1) 
                  CheckZ(2) 
                  CheckZ(3) 
               End With
            Case 4               
               Var T4 = ._4 
               MultiplyMatrixVector( @T4.fX1 ) 
               MultiplyMatrixVector( @T4.fX2 ) 
               MultiplyMatrixVector( @T4.fX3 ) 
               MultiplyMatrixVector( @T4.fX4 )               
               With T4 
                  CheckZ(1) 
                  CheckZ(2) 
                  CheckZ(3) 
                  CheckZ(4) 
               End With             
            End Select
         End With
      Next N
   End With   
   
   If pRoot = pPart Then 
      #if 1
      For N As Long = 0 To pPart->iPartCount-1
         If pPart->tParts(N).bType <> 1 Then Continue For
         'adjust the box to ignore the negative part of the base height (Y)
         Var fyMin = g_tModels(pPart->tParts(N)._1.lModelIndex).pModel->tSize.yMin
         If ((fyMin-(-4)) < 0.0001) Then AtPartBound(N).yMin -= fyMin         
         AtPartBound(N).xMin += .1 : AtPartBound(N).xMax -= .1
         AtPartBound(N).yMin += .1 : AtPartBound(N).yMax -= .1         
         AtPartBound(N).zMin += .1 : AtPartBound(N).zMax -= .1
      Next N
      
      For N As Long = 0 To pPart->iPartCount-1         
         If pPart->tParts(N).bType <> 1 Then Continue For
         For M As Long = N+1 To (pPart->iPartCount-1)
            If pPart->tParts(M).bType <> 1 Then Continue For
            
            If CheckCollision( AtPartBound(N) , AtPartBound(M) ) Then
               
               ' --- BEGIN NARROW PHASE ---
               Dim As CollisionTri aTrisN(), aTrisM()
               
               With pPart->tParts(N)._1
                  Dim As Single fMatN(15) = { .fA, .fD, .fG, 0, .fB, .fE, .fH, 0, .fC, .fF, .fI, 0, .fX, .fY, .fZ, 1 }
                  PushAndMultMatrix( @fMatN(0) )
                  ExtractModelTriangles( g_tModels(.lModelIndex).pModel, aTrisN() )
                  PopMatrix()
               End With

               With pPart->tParts(M)._1
                  Dim As Single fMatM(15) = { .fA, .fD, .fG, 0, .fB, .fE, .fH, 0, .fC, .fF, .fI, 0, .fX, .fY, .fZ, 1 }
                  PushAndMultMatrix( @fMatM(0) )
                  ExtractModelTriangles( g_tModels(.lModelIndex).pModel, aTrisM() )
                  PopMatrix()
               End With
               
               Dim As Byte bExactHit = 0
               If UBound(aTrisN) >= 0 AndAlso UBound(aTrisM) >= 0 Then
                   For iN As Long = 0 To UBound(aTrisN)
                       If CheckTriangleBox(aTrisN(iN).v1, aTrisN(iN).v2, aTrisN(iN).v3, AtPartBound(M)) Then
                           For iM As Long = 0 To UBound(aTrisM)
                               If CheckTriangleTriangle(aTrisN(iN).v1, aTrisN(iN).v2, aTrisN(iN).v3, _
                                                        aTrisM(iM).v1, aTrisM(iM).v2, aTrisM(iM).v3) Then
                                   bExactHit = 1
                                   
                                   ' --- SAVE COLLIDING TRIANGLES FOR DEBUG ---
                                   Dim As Long dIdx = UBound(g_DebugTris)
                                   If dIdx < 0 Then dIdx = 0 Else dIdx += 2
                                   ReDim Preserve g_DebugTris(dIdx + 1)
                                   g_DebugTris(dIdx) = aTrisN(iN)   ' Part A tri
                                   g_DebugTris(dIdx+1) = aTrisM(iM) ' Part B tri
                                   ' ------------------------------------------
                                   
                                   Exit For, For
                               End If
                           Next iM
                       End If
                   Next iN
               End If
               
               If bExactHit Then
                   #if 0
                      Var iI = UBound(atCollision) : ReDim Preserve atCollision(iI+1)                  
                      GetCollisionBoundaries( atCollision(iI) , AtPartBound(N) , AtPartBound(M) )
                   #else
                      Var iI = UBound(atCollision) : ReDim Preserve atCollision(iI+2)                  
                      atCollision(iI) = AtPartBound(N)
                      atCollision(iI+1) = AtPartBound(M)
                   #endif
               End If
               ' --- END NARROW PHASE ---

            End If
         Next M
      Next N
      #endif
      
      Erase AtPartBound 
      PopMatrix() 
   End If
End Sub

Sub DrawCollisionDebug()
    If UBound(g_DebugTris) < 0 Then puts("no collision"): Exit Sub
    
    ' Disable depth testing so the collision triangles render ON TOP of the bricks
    'glDisable(GL_DEPTH_TEST)
    glDisable(GL_LIGHTING)
    glDisable(GL_TEXTURE_2D)
    
    ' Reset matrix to identity so we draw in absolute world coordinates
    
    'glMatrixMode(GL_MODELVIEW)
    'glPushMatrix()
    'glLoadIdentity()
    
    glBegin(GL_TRIANGLES)
    For i As Long = 0 To UBound(g_DebugTris) Step 2
        ' Part A triangle (Solid Red)
        glColor3f(1.0, 0.0, 0.0) 
        glVertex3f(g_DebugTris(i).v1.x, g_DebugTris(i).v1.y, g_DebugTris(i).v1.z)
        glVertex3f(g_DebugTris(i).v2.x, g_DebugTris(i).v2.y, g_DebugTris(i).v2.z)
        glVertex3f(g_DebugTris(i).v3.x, g_DebugTris(i).v3.y, g_DebugTris(i).v3.z)
        
        ' Part B triangle (Solid Yellow)
        glColor3f(1.0, 1.0, 0.0) 
        glVertex3f(g_DebugTris(i+1).v1.x, g_DebugTris(i+1).v1.y, g_DebugTris(i+1).v1.z)
        glVertex3f(g_DebugTris(i+1).v2.x, g_DebugTris(i+1).v2.y, g_DebugTris(i+1).v2.z)
        glVertex3f(g_DebugTris(i+1).v3.x, g_DebugTris(i+1).v3.y, g_DebugTris(i+1).v3.z)
    Next
    glEnd()
    
    'glPopMatrix()
    
    ' Restore state
    'glEnable(GL_DEPTH_TEST)
    glEnable(GL_LIGHTING)
    glEnable(GL_TEXTURE_2D)
End Sub