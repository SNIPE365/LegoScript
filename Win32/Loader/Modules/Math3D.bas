#ifndef __Main
  #error " Don't compile this one"
#endif  

'Function to compute the dot product of two vectors
private function dot_product(pU as single ptr, pV as single ptr) as single
    return pU[0]*pV[0] + pU[1]*pV[1] + pU[2]*pV[2]
end function
private function dot_productV(pU as Vertex3, pV as Vertex3) as single
    return pU.fX*pV.fX + pU.fY*pV.fY + pU.fZ*pV.fZ
end function


'Function to compute the cross product of two vectors
private sub crossProduct(v1 as single ptr, v2 as single ptr, result as single ptr)
    result[0] = v1[1] * v2[2] - v1[2] * v2[1]
    result[1] = v1[2] * v2[0] - v1[0] * v2[2]
    result[2] = v1[0] * v2[1] - v1[1] * v2[0]
end sub

'Function to normalize a vector
private sub normalize(v  as single ptr)
    dim as single length = sqr(v[0] * v[0] + v[1] * v[1] + v[2] * v[2])
    if (length <> 0.0f) then
        v[0] /= length
        v[1] /= length
        v[2] /= length
    end if
end sub
