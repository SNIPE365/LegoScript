#ifndef __Main
  #error " Don't compile this one"
#endif  

private sub SetLineNormal( byref tLine as LineType2Struct , ptNormal as Vertex3 ptr = NULL )
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
private sub SetTrigNormal( byref tTrig as LineType3Struct , ptNormal as Vertex3 ptr = NULL )
  with tTrig
    dim as single edge1(3-1)=any, edge2(3-1)=any, normal(3-1)=any
        
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
    
    #if 0
      dim as single center(3-1) = any , tocenter(3-1) = any, dotp = any
      'Compute centroid
      center(0) = (.fX1 + .fX2 + .fX3) / 3
      center(1) = (.fY1 + .fY2 + .fY3) / 3
      center(2) = (.fZ1 + .fZ2 + .fZ3) / 3
      
      'Vector from origin to centroid
      tocenter(0) = center(0)
      tocenter(1) = center(1)
      tocenter(2) = center(2)
      normalize(@tocenter(0))
      
      'Flip normal if facing inward
      dotp = normal(0)*tocenter(0) + normal(1)*tocenter(1) + normal(2)*tocenter(2)
      if dotp < 0 then
        normal(0) = -normal(0)
        normal(1) = -normal(1)
        normal(2) = -normal(2)
        'swap .fX2,.fX3 : swap .fY2,.fY3 : swap .fZ2,.fZ3
      end if
    #endif

    if ptNormal then
      *ptNormal = type<vertex3>( normal(0) , normal(1) , normal(2) )
      'ptNormal->fX = normal(0)
      'ptNormal->fY = normal(1)
      'ptNormal->fZ = normal(2)
    else      
      glNormal3fv(@normal(0))
    end if
  end with
end sub
private sub SetQuadNormal( byref tQuad as LineType4Struct , ptNormal as Vertex3 ptr = NULL )
  with tQuad
    dim as single edge1(3-1)=any, edge2(3-1)=any, normal(3-1)=any
    
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
    
    #if 0
      dim as single center(3-1), tocenter(3-1), dotp
      'Centroid (all 4 vertices)
      center(0) = (.fX1 + .fX2 + .fX3 + .fX4) / 4
      center(1) = (.fY1 + .fY2 + .fY3 + .fY4) / 4
      center(2) = (.fZ1 + .fZ2 + .fZ3 + .fZ4) / 4
      
      'Vector from origin to centroid
      tocenter(0) = center(0)
      tocenter(1) = center(1)
      tocenter(2) = center(2)
      normalize(@tocenter(0))      
      
      'Flip normal if inward
      dotp = normal(0)*tocenter(0) + normal(1)*tocenter(1) + normal(2)*tocenter(2)
      if dotp < 0 then
        normal(0) = -normal(0)
        normal(1) = -normal(1)
        normal(2) = -normal(2)
        'swap .fX2,.fX4 : swap .fY2,.fY4 : swap .fZ2,.fZ4
      end if
    #endif
    
    if ptNormal then
      *ptNormal = type<vertex3>( normal(0) , normal(1) , normal(2) )
      'ptNormal->fX = normal(0) : ptNormal->fY = normal(1) : ptNormal->fZ = normal(2)
    else
      glNormal3fv(@normal(0))
    end if
    
  end with
end sub

private sub TransformNormal(  byref tNormal as Vertex3 , tMatIn as const Matrix3x3 )
  dim as single x = tNormal.fX, y = tNormal.fY, z = tNormal.fZ
  tNormal.fX = tMatIn.M(0)*x + tMatIn.M(3)*y + tMatIn.M(6)*z
  tNormal.fY = tMatIn.M(1)*x + tMatIn.M(4)*y + tMatIn.M(7)*z
  tNormal.fZ = tMatIn.M(2)*x + tMatIn.M(5)*y + tMatIn.M(8)*z
  
  Normalize( @tNormal.fX )
end sub

#if 0
private sub SetVtxTrigNormal( ptVtx as VertexCubeMap ptr )
  
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

private sub SetVtxTrigNormal( ptVtx as VertexCubeMap ptr )
  
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