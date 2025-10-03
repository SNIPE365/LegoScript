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
      crossProduct(@edge1(0), @edge2(0), @normal(0))
   
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
      crossProduct(@edge1(0), @edge2(0), @normal(0))
      
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
