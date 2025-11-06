#ifndef __Main
  #error " Don't compile this one"
#endif  

sub SetLineNormal( byref tLine as LineType2Struct , ptNormal as Vertex3 ptr = NULL )
   with tLine
      '// Compute direction vector of the line
      dim as single direction(3-1)=any
      direction(0) = .fX2 - .fX1
      direction(1) = .fY2 - .fY1
      direction(2) = .fZ2 - .fZ1
      
      '// Reference vector for cross product (Y-axis, for example)
      dim as single ref(3-1) = {0.0f, 1.0f, 0.0f}
      
      '// Compute the normal using the cross product
      dim as single normal(3-1)
      crossProduct(@direction(0), @ref(0), @normal(0))
      
      '// Normalize the normal
      normalize(@normal(0))
      
      '// Scale the normal for visibility
      const normalScale = 0.5f
      if ptNormal then
         ptNormal->fX = (normal(0) * normalScale)
         ptNormal->fY = (normal(1) * normalScale)
         ptNormal->fZ = (normal(2) * normalScale)
      else
         normal(0) *= normalScale
         normal(1) *= normalScale
         normal(2) *= normalScale
         glNormal3fv( @normal(0) )
      end if
   end with
end sub

#if 0
sub SetTrigNormal( byref tTrig as LineType3Struct , ptNormal as Vertex3 ptr = NULL )
   with tTrig
      'normalize triangle
      dim as single edge1(3-1) = any, edge2(3-1) = any, normal(3-1) = any

      'Compute edge vectors
      edge1(0) = .fX2 - .fX1
      edge1(1) = .fY2 - .fY1
      edge1(2) = .fZ2 - .fZ1
   
      edge2(0) = .fX3 - .fX1
      edge2(1) = .fY3 - .fY1
      edge2(2) = .fZ3 - .fZ1
   
      '// Compute normal
      crossProduct(@edge2(0), @edge1(0) , @normal(0))
   
      '// Normalize the normal vector
      normalize(@normal(0))
      
      if ptNormal then
         ptNormal->fX = normal(0)
         ptNormal->fY = normal(1)
         ptNormal->fZ = normal(2)
      else         
         glNormal3fv( @normal(0) )
      end if
   
      
   end with
end sub   
sub SetQuadNormal( byRef tQuad as LineType4Struct , ptNormal as Vertex3 ptr = NULL )
   with tQuad
      dim as single  edge1(3-1)=any, edge2(3-1)=any, normal(3-1)=any, cc(3-1)=any
      
      '// Compute edge vectors for one triangle of the quad (v1, v2, v3)
      'check with inverse culling
      edge1(0) = .fX3 - .fX4
      edge1(1) = .fY3 - .fY4
      edge1(2) = .fZ3 - .fZ4
      
      edge2(0) = .fX2 - .fX4
      edge2(1) = .fY2 - .fY4
      edge2(2) = .fZ2 - .fZ4      
      
      '// Compute normal for the first triangle
      crossProduct(@edge2(0),@edge1(0), @normal(0))
      
      '// Normalize the normal
      normalize(@normal(0))
      
      'ccw detect
      'Vector3 aview = subtract(A, camera_position);
      #define aview edge1      
      aview(0) = .fX1' - 0
      aview(1) = .fY1' - 0
      aview(2) = .fZ1 - 10000 '?
      var dot = dot_product( @normal(0) , @aview(0) )

      '// If dot product is positive, it's CCW; if negative, it's CW
      if dot < 0 then
       'if it's CCW (we're checking for CW, but it's inverted) means it was not inverted
       'so then calculate the normal the same way as for a triangle
       SetTrigNormal( *cptr(LineType3Struct ptr,@tQuad) , ptNormal )
       exit sub
      end if        
      
      if ptNormal then
         ptNormal->fX = normal(0)
         ptNormal->fY = normal(1)
         ptNormal->fZ = normal(2)
      else
         '// Set normal for the quad
         glNormal3fv( @normal(0) )
      end if      
      
   end with
end sub
#else
sub SetTrigNormal( byref tTrig as LineType3Struct , ptNormal as Vertex3 ptr = NULL )
   with tTrig
      dim as single edge1(3-1), edge2(3-1), normal(3-1)
      dim as single center(3-1), tocenter(3-1), dotp

      'Compute edge vectors
      edge1(0) = .fX2 - .fX1
      edge1(1) = .fY2 - .fY1
      edge1(2) = .fZ2 - .fZ1

      edge2(0) = .fX3 - .fX1
      edge2(1) = .fY3 - .fY1
      edge2(2) = .fZ3 - .fZ1

      'Compute normal (CCW)
      crossProduct(@edge2(0), @edge1(0), @normal(0))
      normalize(@normal(0))

      'Compute centroid
      center(0) = (.fX1 + .fX2 + .fX3) / 3
      center(1) = (.fY1 + .fY2 + .fY3) / 3
      center(2) = (.fZ1 + .fZ2 + .fZ3) / 3

      'Vector from origin to centroid
      tocenter(0) = center(0)
      tocenter(1) = center(1)
      tocenter(2) = center(2)
      normalize(@tocenter(0))
      
      '.fX1 = 0 : .fY1 = 0 : .fZ1 = 0
      '.fX2 = 0 : .fY2 = 0 : .fZ2 = 0
      '.fX3 = 0 : .fY3 = 0 : .fZ3 = 0

      'Flip normal if facing inward
      dotp = normal(0)*tocenter(0) + normal(1)*tocenter(1) + normal(2)*tocenter(2)
      if dotp < 0 then
         normal(0) = -normal(0)
         normal(1) = -normal(1)
         normal(2) = -normal(2)
         'swap .fX2,.fX3 : swap .fY2,.fY3 : swap .fZ2,.fZ3
      end if

      if ptNormal then
         ptNormal->fX = normal(0)
         ptNormal->fY = normal(1)
         ptNormal->fZ = normal(2)
      else
         glNormal3fv(@normal(0))
      end if
   end with
end sub
sub SetQuadNormal( byref tQuad as LineType4Struct , ptNormal as Vertex3 ptr = NULL )
   with tQuad
      dim as single edge1(3-1), edge2(3-1), normal(3-1)
      dim as single center(3-1), tocenter(3-1), dotp

      'Compute edges using first 3 vertices
      edge1(0) = .fX2 - .fX1
      edge1(1) = .fY2 - .fY1
      edge1(2) = .fZ2 - .fZ1

      edge2(0) = .fX3 - .fX1
      edge2(1) = .fY3 - .fY1
      edge2(2) = .fZ3 - .fZ1

      'Compute normal (CCW)
      crossProduct(@edge2(0), @edge1(0), @normal(0))
      normalize(@normal(0))

      'Centroid (all 4 vertices)
      center(0) = (.fX1 + .fX2 + .fX3 + .fX4) / 4
      center(1) = (.fY1 + .fY2 + .fY3 + .fY4) / 4
      center(2) = (.fZ1 + .fZ2 + .fZ3 + .fZ4) / 4

      'Vector from origin to centroid
      tocenter(0) = center(0)
      tocenter(1) = center(1)
      tocenter(2) = center(2)
      normalize(@tocenter(0))
      
      '.fX1 = 0 : .fY1 = 0 : .fZ1 = 0
      '.fX2 = 0 : .fY2 = 0 : .fZ2 = 0
      '.fX3 = 0 : .fY3 = 0 : .fZ3 = 0
      '.fX4 = 0 : .fY4 = 0 : .fZ4 = 0

      'Flip normal if inward
      dotp = normal(0)*tocenter(0) + normal(1)*tocenter(1) + normal(2)*tocenter(2)
      if dotp < 0 then
         normal(0) = -normal(0)
         normal(1) = -normal(1)
         normal(2) = -normal(2)
         'swap .fX2,.fX4 : swap .fY2,.fY4 : swap .fZ2,.fZ4
      end if

      if ptNormal then
         ptNormal->fX = normal(0)
         ptNormal->fY = normal(1)
         ptNormal->fZ = normal(2)
      else
         glNormal3fv(@normal(0))
      end if
   end with
end sub
#endif

#if 0
sub SetVtxTrigNormal( ptVtx as VertexCubeMap ptr )
  
  dim as Vertex3 tEdge1, tEdge2, tNormal, tCenter
  
  'Compute edges
  tEdge1.fX = ptVtx[1].tPos.fX - ptVtx[0].tPos.fX
  tEdge1.fY = ptVtx[1].tPos.fY - ptVtx[0].tPos.fY
  tEdge1.fZ = ptVtx[1].tPos.fZ - ptVtx[0].tPos.fZ
  
  tEdge2.fX = ptVtx[2].tPos.fX - ptVtx[0].tPos.fX
  tEdge2.fY = ptVtx[2].tPos.fY - ptVtx[0].tPos.fY
  tEdge2.fZ = ptVtx[2].tPos.fZ - ptVtx[0].tPos.fZ
  
  'Compute cross (assuming CCW, adjust later if needed)
  crossProduct(@tEdge1.fX, @tEdge2.fX, @tNormal.fX)
  normalize(@tNormal.fX)
  
  'Compute triangle center
  tCenter.fX = (ptVtx[0].tPos.fX + ptVtx[1].tPos.fX + ptVtx[2].tPos.fX) / 3
  tCenter.fY = (ptVtx[0].tPos.fY + ptVtx[1].tPos.fY + ptVtx[2].tPos.fY) / 3
  tCenter.fZ = (ptVtx[0].tPos.fZ + ptVtx[1].tPos.fZ + ptVtx[2].tPos.fZ) / 3
  
  'Vector from origin (or model center) to triangle
  dim as Vertex3 tToCenter
  tToCenter = tCenter
  normalize(@tToCenter.fX)
  
  'If normal points inward, flip it
  dim as single dotp = tToCenter.fX * tNormal.fX + _
                       tToCenter.fY * tNormal.fY + _
                       tToCenter.fZ * tNormal.fZ
  
  if dotp < 0 then
     tNormal.fX = -tNormal.fX
     tNormal.fY = -tNormal.fY
     tNormal.fZ = -tNormal.fZ
  end if
  
  'Assign the normal to all three vertices
  ptVtx[0].tNormal = tNormal
  ptVtx[1].tNormal = tNormal
  ptVtx[2].tNormal = tNormal

end sub
#endif

sub SetVtxTrigNormal( ptVtx as VertexCubeMap ptr )
  
  'normalize triangle
  dim as Vertex3 tEdge1=any, tEdge2=any , tNormal = any
  
  'Compute edge vectors
  tEdge1.fX = ptVtx[1].tPos.fX - ptVtx[0].tPos.fX
  tEdge1.fY = ptVtx[1].tPos.fY - ptVtx[0].tPos.fY
  tEdge1.fZ = ptVtx[1].tPos.fZ - ptVtx[0].tPos.fZ
  
  tEdge2.fX = ptVtx[2].tPos.fX - ptVtx[0].tPos.fX
  tEdge2.fY = ptVtx[2].tPos.fY - ptVtx[0].tPos.fY
  tEdge2.fZ = ptVtx[2].tPos.fZ - ptVtx[0].tPos.fZ
  
  '// Compute normal
  crossProduct( @tEdge2.fX , @tEdge1.fX , @tNormal.fX )
  
  '// Normalize the normal vector
  normalize( @tNormal.fX )
  
  ptVtx[0].tNormal = tNormal
  ptVtx[1].tNormal = tNormal
  ptVtx[2].tNormal = tNormal      

end sub

#if 0
  Function VectorLength(v As Single Ptr) As Single
      ' Calculates the magnitude (length) of a 3D vector.
      Return Sqr(v[0] * v[0] + v[1] * v[1] + v[2] * v[2])
  End Function
  Function Dot_Product(pU As Single Ptr, pV As Single Ptr) As Single
      ' Calculates the dot product of two 3D vectors.
      ' pU and pV must point to 3 consecutive Single values (x, y, z).
      Return pU[0] * pV[0] + pU[1] * pV[1] + pU[2] * pV[2]
  End Function
  Sub CrossProduct(v1 As Single Ptr, v2 As Single Ptr, result As Single Ptr)
      ' Calculates the cross product (v1 x v2) and stores it in 'result'.
      ' The resulting vector 'result' is perpendicular to both v1 and v2.
      Dim As Single tempX, tempY, tempZ
  
      tempX = v1[1] * v2[2] - v1[2] * v2[1]
      tempY = v1[2] * v2[0] - v1[0] * v2[2]
      tempZ = v1[0] * v2[1] - v1[1] * v2[0]
  
      result[0] = tempX
      result[1] = tempY
      result[2] = tempZ
  End Sub
  Sub Normalize(v As Single Ptr)
      ' Converts the vector 'v' into a unit vector (length 1).
      Dim As Single length = VectorLength(v)
      If length > 0 Then
          v[0] /= length
          v[1] /= length
          v[2] /= length
      End If
  End Sub
#endif

#if 1
static shared as single g_DesiredNormal(...) = {0,0,0}
Sub Matrix3x3VectorMultiply(pM As Single Ptr, pV_in As Single Ptr, pV_out As Single Ptr)
    ' Multiplies a 3-component vector pV_in by the 3x3 rotation/scale part
    ' of a 4x4 matrix pM and stores the result in pV_out.
    ' We assume pM is a 4x4 matrix in column-major order (standard for OpenGL/DirectX).
    ' Matrix indices:
    ' | M[0] M[4] M[8] M[12] |
    ' | M[1] M[5] M[9] M[13] |
    ' | M[2] M[6] M[10] M[14] |
    ' | M[3] M[7] M[11] M[15] |
    
    Dim As Single x = pV_in[0]
    Dim As Single y = pV_in[1]
    Dim As Single z = pV_in[2]

    pV_out[0] = pM[0] * x + pM[4] * y + pM[8] * z
    pV_out[1] = pM[1] * x + pM[5] * y + pM[9] * z
    pV_out[2] = pM[2] * x + pM[6] * y + pM[10] * z
End Sub
  #if 1
  Sub CheckAndFlipQuadWinding(ByRef Quad As LineType4Struct , pDummy as single ptr) ', pDesiredNormal As Single Ptr)
    exit sub
      
      #define pDesiredNormal @g_DesiredNormal(0)
      ' This function checks the winding of the quad (P1, P2, P3, P4)
      ' by calculating the surface normal and comparing it to a reference
      ' direction (pDesiredNormal). If the winding is opposite, it flips
      ' the order by swapping P3 and P4 coordinates.
  
      ' Pointers for convenience (P1, P2, P3)
      Dim As Single P1(0 To 2) = {Quad.fX1, Quad.fY1, Quad.fZ1}
      Dim As Single P2(0 To 2) = {Quad.fX2, Quad.fY2, Quad.fZ2}
      Dim As Single P3(0 To 2) = {Quad.fX3, Quad.fY3, Quad.fZ3}
  
      ' Vector declarations for vector math
      Dim As Single VectorA(0 To 2)   ' A = P2 - P1 (Edge vector)
      Dim As Single VectorB(0 To 2)   ' B = P3 - P1 (Diagonal vector, non-consecutive edge for cross product)
      Dim As Single Normal(0 To 2)    ' N = A x B (Surface Normal)
  
      ' 1. Calculate the two basis vectors for the plane (A and B)
      ' Vector A = P2 - P1
      VectorA(0) = P2(0) - P1(0)
      VectorA(1) = P2(1) - P1(1)
      VectorA(2) = P2(2) - P1(2)
  
      ' Vector B = P3 - P1
      VectorB(0) = P3(0) - P1(0)
      VectorB(1) = P3(1) - P1(1)
      VectorB(2) = P3(2) - P1(2)
  
      ' 2. Calculate the surface normal N = A x B
      CrossProduct(@VectorA(0), @VectorB(0), @Normal(0))
  
      ' 3. Normalize the vectors (optional, but ensures consistent dot product interpretation)
      Normalize(@Normal(0))
      ' The Desired Normal (pDesiredNormal) should ideally be normalized too, 
      ' but we only rely on the sign of the dot product.
  
      ' 4. Check the Winding Order using the Dot Product
      ' If Dot(N, DesiredNormal) > 0, the normal faces the desired direction (Correct Winding, e.g., CCW).
      ' If Dot(N, DesiredNormal) < 0, the normal faces opposite to the desired direction (Wrong Winding, e.g., CW).
      Dim As Single dotResult = Dot_Product(@Normal(0), pDesiredNormal)
  
      If dotResult < 0 Then
          ' The current winding order (P1, P2, P3) produces a normal
          ' pointing away from the desired direction. We need to flip it.
  
          ' 5. Flip the winding by swapping two adjacent vertices.
          ' Swapping P3 and P4 changes the winding from (P1, P2, P3, P4) to (P1, P2, P4, P3).
          
          Dim As Single tempX, tempY, tempZ
  
          swap Quad.fX3 , Quad.fX4
          swap Quad.fY3 , Quad.fY4
          swap Quad.fZ3 , Quad.fZ4
          
          'Print "Winding Flipped (P3 <-> P4 swap)."
      Else
          'Print "Winding OK. Normal matches desired direction."
      End If
  End Sub
  #else
  Sub CheckAndFlipQuadWinding(ByRef Quad As LineType4Struct, pModelViewMatrix As Single Ptr) ', pLocalNormal As Single Ptr)
      #define pLocalNormal @g_DesiredNormal(0) 
      ' This function checks the winding of the quad (P1, P2, P3, P4)
      ' by calculating the surface normal and comparing it to a dynamically
      ' transformed desired normal. If the winding is opposite, it flips
      ' the order by swapping P3 and P4 coordinates.
  
      ' NOTE on Normal Transformation: 
      ' For normals, the correct transformation matrix is the Inverse Transpose 
      ' of the ModelView Matrix. If your ModelView only contains ROTATION and 
      ' TRANSLATION (no non-uniform scale or shear), the top-left 3x3 of the 
      ' ModelView Matrix itself can be used to transform the normal, which 
      ' is the simplification used here for ease of implementation.
      
      ' Local array to hold the Desired Normal in World/View space
      Dim As Single DesiredNormal(0 To 2)
  
      ' 1. Transform the Local Normal using the ModelView Matrix (3x3 part)
      Matrix3x3VectorMultiply(pModelViewMatrix, pLocalNormal, @DesiredNormal(0))
      Normalize(@DesiredNormal(0))
      
      'Print "Transformed Desired Normal (World/View): ("; DesiredNormal(0); ","; DesiredNormal(1); ","; DesiredNormal(2); ")"
      
      ' Pointers for convenience (P1, P2, P3)
      Dim As Single P1(0 To 2) = {Quad.fX1, Quad.fY1, Quad.fZ1}
      Dim As Single P2(0 To 2) = {Quad.fX2, Quad.fY2, Quad.fZ2}
      Dim As Single P3(0 To 2) = {Quad.fX3, Quad.fY3, Quad.fZ3}
  
      ' Vector declarations for vector math
      Dim As Single VectorA(0 To 2)   ' A = P2 - P1
      Dim As Single VectorB(0 To 2)   ' B = P3 - P1
      Dim As Single Normal(0 To 2)    ' N = A x B (Surface Normal in World/View space)
  
      ' 2. Calculate the two basis vectors for the plane (A and B)
      VectorA(0) = P2(0) - P1(0)
      VectorA(1) = P2(1) - P1(1)
      VectorA(2) = P2(2) - P1(2)
  
      VectorB(0) = P3(0) - P1(0)
      VectorB(1) = P3(1) - P1(1)
      VectorB(2) = P3(2) - P1(2)
  
      ' 3. Calculate the surface normal N = A x B
      CrossProduct(@VectorA(0), @VectorB(0), @Normal(0))
      Normalize(@Normal(0))
      
      'Print "Calculated Surface Normal: ("; Normal(0); ","; Normal(1); ","; Normal(2); ")"
  
      ' 4. Check the Winding Order using the Dot Product
      ' We compare the calculated N to the dynamically transformed DesiredNormal.
      Dim As Single dotResult = Dot_Product(@Normal(0), @DesiredNormal(0))
  
      If dotResult < 0 Then
          ' The current winding order produces a normal pointing away 
          ' from the desired direction. Flip it.
  
          ' 5. Flip the winding by swapping P3 and P4 coordinates.
          'Dim As Single tempX, tempY, tempZ
          'tempX = Quad.fX3 : Quad.fX3 = Quad.fX4 : Quad.fX4 = tempX
          'tempY = Quad.fY3 : Quad.fY3 = Quad.fY4 : Quad.fY4 = tempY
          'tempZ = Quad.fZ3 : Quad.fZ3 = Quad.fZ4 : Quad.fZ4 = tempZ
                  
          'Print "Winding Flipped (P3 <-> P4 swap)."
          
      Else
          'Print "Winding OK. Normal matches desired direction."
    End If
    
    swap Quad.fX2 , Quad.fX4
    swap Quad.fY2 , Quad.fY4
    swap Quad.fZ2 , Quad.fZ4
    
  End Sub
  #endif
#endif
