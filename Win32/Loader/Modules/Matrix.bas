#ifndef __Main
  #error " Don't compile this one"
#endif  

#ifndef GiveUp
  #define GiveUp(_N) sleep : end (_N)
#endif

enum ModelQuality
  ModelQuality_Low    = 1
  ModelQuality_Normal
  ModelQuality_High
end enum

'type Matrix4x4
'   m(15) as single
'end type   

type vec3
  as single X,Y,Z
end type
type vec4
  as single X,Y,Z,W
end type

type Matrix4x4
   union
      m(15) as single
      type
         as single fScaleX ,   f_1   ,  f_2    , f0_3
         as single  f_4    , fScaleY ,  f_6    , f0_7
         as single  f_8    ,   f_9   , fScaleZ , f0_11
         as single  fPosX  ,  fPosY  ,  fPosZ  , f1_15
      end type
   end union
end type

static shared as Matrix4x4 tMatrixStack(1023)
static shared as long g_CurrentMatrix

#define tCurrentMatrix() tMatrixStack( g_CurrentMatrix )

static shared as Matrix4x4 g_tIdentityMatrix '= ( _
  '   { 1, 0, 0, 0,  _
  '     0, 1, 0, 0,  _
  '     0, 0, 1, 0,  _
  '     0, 0, 0, 1 } _
  ')
g_tIdentityMatrix.fScaleX=1  : g_tIdentityMatrix.fScaleY=1
g_tIdentityMatrix.fScaleZ=1  : g_tIdentityMatrix.m(15)=1

dim shared as Matrix4x4 g_tBlankMatrix
tMatrixStack( 0 ) = g_tIdentityMatrix
private function PushAndMultMatrix( pIn as const single ptr ) as boolean
   var pCur = cast(single ptr,@tMatrixStack(g_CurrentMatrix))
   g_CurrentMatrix += 1
   if g_CurrentMatrix > 1023 then
      puts("MATRIX STACK OVERFLOW!!!!")
      GiveUp(1)
   end if
         
   'var pOut = cast(Matrix4x4 ptr,@tMatrixStack(g_CurrentMatrix))
   '*pOut = *cast(Matrix4x4 ptr,pIn)
   
   var pOut = cast(single ptr,@tMatrixStack(g_CurrentMatrix))
   for row as long = 0 to 3
      for col as long = 0 to 3
         pOut[row+col*4] = _            
            pCur[row + 0 * 4] * piN[0 + col * 4] + _
            pCur[row + 1 * 4] * piN[1 + col * 4] + _
            pCur[row + 2 * 4] * piN[2 + col * 4] + _
            pCur[row + 3 * 4] * piN[3 + col * 4]
      next col
   next row   
   return true
end function
private function MultCurrentMatrix( pIn as const single ptr ) as boolean
   var pCur = cast(single ptr,@tMatrixStack(g_CurrentMatrix))   
   if g_CurrentMatrix >= 1023 then
      puts("MATRIX STACK OVERFLOW!!!!")
      GiveUp(1)
   end if
         
   'var pOut = cast(Matrix4x4 ptr,@tMatrixStack(g_CurrentMatrix))
   '*pOut = *cast(Matrix4x4 ptr,pIn)
   
   var pOut = cast(single ptr,@tMatrixStack(g_CurrentMatrix+1))
   for row as long = 0 to 3
      for col as long = 0 to 3
         pOut[row+col*4] = _            
            pCur[row + 0 * 4] * piN[0 + col * 4] + _
            pCur[row + 1 * 4] * piN[1 + col * 4] + _
            pCur[row + 2 * 4] * piN[2 + col * 4] + _
            pCur[row + 3 * 4] * piN[3 + col * 4]
      next col
   next row 
   
   memcpy( pCur , pOut , 16*sizeof(single) )
   return true
   
end function
private sub PushIdentityMatrix()
   g_CurrentMatrix += 1   
   tMatrixStack( g_CurrentMatrix ) = g_tIdentityMatrix 'tMatrixStack( 0 )
end sub
private sub PopMatrix()
   if g_CurrentMatrix>0 then g_CurrentMatrix -= 1
end sub   
private sub MultiplyMatrixVector( pVec as single ptr , pMatrix as Matrix4x4 ptr = 0 )
   dim as single fX = pVec[0] , fY = pVec[1] , fZ = pVec[2]
   if pMatrix=0 then pMatrix = @tMatrixStack(g_CurrentMatrix)
   with *pMatrix
      pVec[0] = .m(0) * fX + .m(4) * fY + .m( 8) * fZ + .m(12)
      pVec[1] = .m(1) * fX + .m(5) * fY + .m( 9) * fZ + .m(13)
      pVec[2] = .m(2) * fX + .m(6) * fY + .m(10) * fZ + .m(14)
   end with
end sub
private function IsMatrixIdentity() as boolean
   with tMatrixStack( g_CurrentMatrix )
      for N as long = 0 to 15
         if abs(.m(N)-g_tIdentityMatrix.m(N)) > .0001 then return false
      next N      
   end with
   return true
end function   
private sub PrintCurrentMatrix()
   with tMatrixStack( g_CurrentMatrix )
      var pMat = @.m(0)
      for Y as long = 0 to 3
         for X as long = 0 to 3
            printf("%s%.1f",space(1-(*pMat>=0)-(abs(*pMat)<10)),*pMat) : pMat += 1
         next X
         puts("")
      next Y
   end with
end sub

#define glLoadCurrentMatrix() glLoadMatrixf( @tMatrixStack(g_CurrentMatrix).m(0) )

private sub MultMatrix4x4WithVector3x3( byref tmOut as Matrix4x4 , tmIn as const Matrix4x4 , pIn as const single ptr )
   var pCur = cast(single ptr,@tmIn)               
   var pOut = cast(single ptr,@tmOut)
   dim as Matrix4x4 tTempIn = any
   
   'multiplying by itself wont work, so make input a temp copy
   if pOut = pCur then tTempIn = tmIn : pCur = cast(single ptr,@tTempIn)
   
   for row as long = 0 to 3
      for col as long = 0 to 3
         pOut[row+col*4] = _            
            pCur[row + 0 * 4] * piN[0 + col * 4] + _
            pCur[row + 1 * 4] * piN[1 + col * 4] + _
            pCur[row + 2 * 4] * piN[2 + col * 4] + _
            pCur[row + 3 * 4] * piN[3 + col * 4]
      next col
   next row
   
end sub
'#define MultMatrix4x4( _Out , _In , _pMul ) MultMatrix4x4WithVector3x3( _Out , _In , cptr(const single ptr,(_pMul)) )
' A safe and correct function for row-major 4x4 matrix multiplication.

private sub MultiplyMat4x4WithVec3( byref vOut as Vec4 , m as const Matrix4x4 , v as const Vec3 )
  with m
    vOut.x = .m(0)*v.x + .m(4)*v.y + .m( 8)*v.z + .m(12)'*v.w;
    vOut.y = .m(1)*v.x + .m(5)*v.y + .m( 9)*v.z + .m(13)'*v.w;
    vOut.z = .m(2)*v.x + .m(6)*v.y + .m(10)*v.z + .m(14)'*v.w;
    vOut.w = .m(3)*v.x + .m(7)*v.y + .m(11)*v.z + .m(15)'*v.w;
  end with
end sub

private sub MultMatrix4x4 (byref result as Matrix4x4, byref a as const Matrix4x4, byref b as const Matrix4x4)
  dim as integer i=any, j=any, k=any
  if @result.m(0) = @a.m(0) then
    dim as Matrix4x4 tTemp = any
    for j = 0 to 3 ' Columns of the result
      for i = 0 to 3 ' Rows of the result
        tTemp.m(j * 4 + i) = 0.0
        for k = 0 to 3
          ' The indexing here is different
          tTemp.m(j * 4 + i) += a.m(k * 4 + i) * b.m(j * 4 + k)
        next k
      next i
    next j
    result = tTemp  
  else
    for j = 0 to 3 ' Columns of the result
      for i = 0 to 3 ' Rows of the result
        result.m(j * 4 + i) = 0.0
        for k = 0 to 3
          ' The indexing here is different
          result.m(j * 4 + i) += a.m(k * 4 + i) * b.m(j * 4 + k)
        next k
      next i
    next j
  end if
end sub

#if 0
private sub MultMatrix4x4_RowMajor( byref result as Matrix4x4, byref a as const Matrix4x4, byref b as const Matrix4x4)
    dim as integer i, j, k
    dim as Matrix4x4 tempResult
    for i = 0 to 3 ' Rows
        for j = 0 to 3 ' Columns
            tempResult.m(i * 4 + j) = 0.0
            for k = 0 to 3
                tempResult.m(i * 4 + j) += a.m(i * 4 + k) * b.m(k * 4 + j)
            next k
        next j
    next i
    result = tempResult
end sub
private sub MultMatrix4x4_ColumnMajor( byref result as Matrix4x4, byref a as const Matrix4x4, byref b as const Matrix4x4)
    dim as integer i, j, k
    dim as Matrix4x4 tempResult
    for j = 0 to 3 ' Columns of the result
        for i = 0 to 3 ' Rows of the result
            tempResult.m(j * 4 + i) = 0.0
            for k = 0 to 3
                ' The indexing here is different
                tempResult.m(j * 4 + i) += a.m(k * 4 + i) * b.m(j * 4 + k)
            next k
        next i
    next j
    result = tempResult
end sub
#endif
private sub Matrix4x4RotateX( byref tmOut as Matrix4x4 , tmIn as const Matrix4x4 , fAngle as const single )      
   dim as single sMat(15) = { _
      1 ,      0       ,      0      , 0 , _
      0 ,  cos(fAngle) , sin(fAngle) , 0 , _
      0 , -sin(fAngle) , cos(fAngle) , 0 , _
      0 ,      0       ,      0      , 1 _
   }   
   MultMatrix4x4( tmOut , tmIn , *cptr(Matrix4x4 ptr,@sMat(0)) ) 'MultMatrix4x4WithVector3x3( tmOut , tmIn , @sMat(0) )
end sub
private sub Matrix4x4RotateY( byref tmOut as Matrix4x4 , tmIn as const Matrix4x4 , fAngle as const single )      
   dim as single sMat(15) = { _
      cos(fAngle) , 0 , -sin(fAngle) , 0 , _
          0       , 1 ,     0        , 0 , _
      sin(fAngle) , 0 ,  cos(fAngle) , 0 , _
         0        , 0 ,     0        , 1 _
   }
   'MultMatrix4x4WithVector3x3( tmOut , tmIn , @sMat(0) )
   MultMatrix4x4( tmOut , tmIn , *cptr(Matrix4x4 ptr,@sMat(0)) )
end sub
private sub Matrix4x4RotateZ( byref tmOut as Matrix4x4 , tmIn as const Matrix4x4 , fAngle as const single )      
   dim as single sMat(15) = { _
      cos(fAngle) , -sin(fAngle) , 0 , 0 , _
      sin(fAngle) ,  cos(fAngle) , 0 , 0 , _
          0       ,      0       , 1 , 0 , _
          0       ,      0       , 0 , 1 _
   }   
   'MultMatrix4x4WithVector3x3( tmOut , tmIn , @sMat(0) )
   MultMatrix4x4( tmOut , tmIn , *cptr(Matrix4x4 ptr,@sMat(0)) )
end sub
#if 0
private sub Matrix4x4Translate( byref tmInOut as Matrix4x4 , fDX as const single , fDY as const single , fDZ as const single )
   var tMat = g_tIdentityMatrix
   tMat.fPosX = fDX : tMat.fPosY = fDY : tMat.fPosZ = fDZ
   'MultMatrix4x4( tmInOut , tMat , tmInOut )
   MultMatrix4x4( tmInOut , tmInOut , tMat )
end sub
#else
private sub Matrix4x4Translate( byref tmInOut as Matrix4x4 , fDX as const single , fDY as const single , fDZ as const single )
  with tmInOut
    .m(12) += .m(0)*fDX + .m(4)*fDY + .m( 8)*fDZ
    .m(13) += .m(1)*fDX + .m(5)*fDY + .m( 9)*fDZ
    .m(14) += .m(2)*fDX + .m(6)*fDY + .m(10)*fDZ
  end with
end sub
#endif
private sub Matrix4x4Scale( byref tmInOut as Matrix4x4 , fSX as const single , fSY as const single , fSZ as const single )
  with tmInOut
    .m(0) *= fSX : .m(1) *= fSX : .m( 2) *= fSX : .m( 3) *= fSX
    .m(4) *= fSY : .m(5) *= fSY : .m( 6) *= fSY : .m( 7) *= fSY
    .m(8) *= fSZ : .m(9) *= fSZ : .m(10) *= fSZ : .m(11) *= fSZ
  end with
end sub

#define _6( _t , _p1 , _p2 , _p3 , _p4 , _p5 , _p6 , _p7 , _p8 , _p9 ) _p1 as _t, _p2 as _t, _p3 as _t, _p4 as _t, _p5 as _t, _p6 as _t, _p7 as _t, _p8 as _t , _p9 as _t
private sub Matrix4x4LookAt( byref tmInOut as Matrix4x4 , _6(const single,eyeX,eyeY,eyeZ,centerX,centerY,centerZ,upX,upY,upZ) )
  
  dim as single fx = centerX - eyeX
  dim as single fy = centerY - eyeY
  dim as single fz = centerZ - eyeZ
  dim as single rlf = 1.0f / sqrtf(fx*fx + fy*fy + fz*fz)
  fx *= rlf: fy *= rlf: fz *= rlf
  
  dim as single sx = fy*upZ - fz*upY
  dim as single sy = fz*upX - fx*upZ
  dim as single sz = fx*upY - fy*upX
  dim as single rls = 1.0f / sqrtf(sx*sx + sy*sy + sz*sz)
  sx *= rls: sy *= rls: sz *= rls
  
  dim as single ux = sy*fz - sz*fy
  dim as single uy = sz*fx - sx*fz
  dim as single uz = sx*fy - sy*fx
  
  dim as Matrix4x4 tTemp = any
  with tTemp
    .m(0) =  sx : .m(4) =  sy : .m( 8) =  sz : .m(12) = -(sx*eyeX + sy*eyeY + sz*eyeZ)
    .m(1) =  ux : .m(5) =  uy : .m( 9) =  uz : .m(13) = -(ux*eyeX + uy*eyeY + uz*eyeZ)
    .m(2) = -fx : .m(6) = -fy : .m(10) = -fz : .m(14) =  (fx*eyeX + fy*eyeY + fz*eyeZ)
    .m(3) =   0 : .m(7) =   0 : .m(11) =   0 : .m(15) = 1
  end with
  MultMatrix4x4( tmInOut , tmInOut , tTemp )
  
end sub

#ifndef Vector3
type Vector3
    as single x, y, z
end type
#endif

type Matrix3x3
    union
        as single m(0 to 8)
        type            
            as single fScaleX , f_1     , f_2            
            as single f_3     , fScaleY , f_5            
            as single f_6     , f_7     , fScaleZ
        end type
    end union
end type

static shared as Matrix3x3 g_tIdentityMatrix3x3
g_tIdentityMatrix3x3.fScaleX=1  : g_tIdentityMatrix3x3.fScaleY=1
g_tIdentityMatrix3x3.fScaleZ=1

' Helper function to multiply two 3x3 matrices and store the result.
private sub MultMatrix3x3(byref tmOut as Matrix3x3, byref tmA as Matrix3x3, byref tmB as Matrix3x3)
    dim as integer i, j, k
    dim as Matrix3x3 tempMat

    for i = 0 to 2
        for j = 0 to 2
            tempMat.m(i * 3 + j) = 0.0
            for k = 0 to 2
                tempMat.m(i * 3 + j) += tmA.m(i * 3 + k) * tmB.m(k * 3 + j)
            next k
        next j
    next i
    tmOut = tempMat
end sub
private function InvertMatrix3x3(byref tmOut as Matrix3x3, byref tmIn as Matrix3x3) as boolean

    dim as single det, invDet
    dim as Matrix3x3 adj

    ' 1. Calculate the determinant of the 3x3 matrix
    ' det = a(ei - fh) - b(di - fg) + c(dh - eg)
    det = tmIn.m(0) * (tmIn.m(4) * tmIn.m(8) - tmIn.m(5) * tmIn.m(7)) - _
          tmIn.m(1) * (tmIn.m(3) * tmIn.m(8) - tmIn.m(5) * tmIn.m(6)) + _
          tmIn.m(2) * (tmIn.m(3) * tmIn.m(7) - tmIn.m(4) * tmIn.m(6))

    ' 2. Check if the matrix is invertible
    if (abs(det) < 0.000001) then ' Use a small tolerance for floating point numbers
        ' The matrix is singular and cannot be inverted
        return false
    end if

    invDet = 1.0 / det

    ' 3. Calculate the adjugate matrix (transpose of the cofactor matrix)
    adj.m(0) = (tmIn.m(4) * tmIn.m(8) - tmIn.m(5) * tmIn.m(7))
    adj.m(1) = -(tmIn.m(1) * tmIn.m(8) - tmIn.m(2) * tmIn.m(7))
    adj.m(2) = (tmIn.m(1) * tmIn.m(5) - tmIn.m(2) * tmIn.m(4))
    
    adj.m(3) = -(tmIn.m(3) * tmIn.m(8) - tmIn.m(5) * tmIn.m(6))
    adj.m(4) = (tmIn.m(0) * tmIn.m(8) - tmIn.m(2) * tmIn.m(6))
    adj.m(5) = -(tmIn.m(0) * tmIn.m(5) - tmIn.m(2) * tmIn.m(3))
    
    adj.m(6) = (tmIn.m(3) * tmIn.m(7) - tmIn.m(4) * tmIn.m(6))
    adj.m(7) = -(tmIn.m(0) * tmIn.m(7) - tmIn.m(1) * tmIn.m(6))
    adj.m(8) = (tmIn.m(0) * tmIn.m(4) - tmIn.m(1) * tmIn.m(3))

    ' 4. Multiply the adjugate matrix by the inverse of the determinant
    tmOut.m(0) = adj.m(0) * invDet
    tmOut.m(1) = adj.m(1) * invDet
    tmOut.m(2) = adj.m(2) * invDet
    tmOut.m(3) = adj.m(3) * invDet
    tmOut.m(4) = adj.m(4) * invDet
    tmOut.m(5) = adj.m(5) * invDet
    tmOut.m(6) = adj.m(6) * invDet
    tmOut.m(7) = adj.m(7) * invDet
    tmOut.m(8) = adj.m(8) * invDet

    return true

end function

' Rotates a matrix around the X-axis
private sub Matrix3x3RotateX(byref tmOut as Matrix3x3, byref tmIn as Matrix3x3, fAngle as single)
    'dim as single radians = fAngle * (3.14159265 / 180.0)
    dim as single c = cos(fAngle)
    dim as single s = sin(fAngle)
    dim as Matrix3x3 rotateMat = g_tIdentityMatrix3x3

    ' Create the rotation matrix for the X-axis
    rotateMat.m(4) = c : rotateMat.m(5) = -s
    rotateMat.m(7) = s : rotateMat.m(8) = c

    ' Multiply the input matrix by the rotation matrix
    MultMatrix3x3(tmOut, tmIn, rotateMat)
end sub
' Rotates a matrix around the Y-axis
private sub Matrix3x3RotateY(byref tmOut as Matrix3x3, byref tmIn as Matrix3x3, fAngle as single)
    'dim as single radians = fAngle * (3.14159265 / 180.0)
    dim as single c = cos(fAngle)
    dim as single s = sin(fAngle)
    dim as Matrix3x3 rotateMat = g_tIdentityMatrix3x3

    ' Create the rotation matrix for the Y-axis
    rotateMat.m(0) = c : rotateMat.m(2) = s
    rotateMat.m(6) = -s : rotateMat.m(8) = c

    ' Multiply the input matrix by the rotation matrix
    MultMatrix3x3(tmOut, tmIn, rotateMat)
end sub
' Rotates a matrix around the Z-axis
private sub Matrix3x3RotateZ(byref tmOut as Matrix3x3, byref tmIn as Matrix3x3, fAngle as single)
    'dim as single radians = fAngle * (3.14159265 / 180.0)
    dim as single c = cos(fAngle)
    dim as single s = sin(fAngle)
    dim as Matrix3x3 rotateMat = g_tIdentityMatrix3x3

    ' Create the rotation matrix for the Z-axis
    rotateMat.m(0) = c : rotateMat.m(1) = -s
    rotateMat.m(3) = s : rotateMat.m(4) = c

    ' Multiply the input matrix by the rotation matrix
    MultMatrix3x3(tmOut, tmIn, rotateMat)
end sub
' Performs a vector-matrix multiplication (V' = M * V)
' This rotates a local vector using a parent's matrix
private function Vector3_Transform(byref inVec as Vector3, byref inMat as Matrix3x3) as Vector3
    dim as Vector3 outVec

    outVec.x = inMat.m(0) * inVec.x + inMat.m(1) * inVec.y + inMat.m(2) * inVec.z
    outVec.y = inMat.m(3) * inVec.x + inMat.m(4) * inVec.y + inMat.m(5) * inVec.z
    outVec.z = inMat.m(6) * inVec.x + inMat.m(7) * inVec.y + inMat.m(8) * inVec.z
    
    return outVec
end function
' Adds two vectors together (V = A + B)
private sub Vector3_Add(byref vec1 as Vector3, byref vec2 as Vector3)    
   with vec1
      .x += vec2.x
      .y += vec2.y
      .z += vec2.z
   end with
end sub
private function Vector3_AddEx(byref vec1 as Vector3, byref vec2 as Vector3) as Vector3
    dim as Vector3 outVec
    
    outVec.x = vec1.x + vec2.x
    outVec.y = vec1.y + vec2.y
    outVec.z = vec1.z + vec2.z
    
    return outVec
end function
' Subtracts two vectors together (V = A + B)
private sub Vector3_Sub(byref vec1 as Vector3, byref vec2 as Vector3)    
   with vec1
      .x -= vec2.x
      .y -= vec2.y
      .z -= vec2.z
   end with
end sub
private function Vector3_SubEx(byref vec1 as Vector3, byref vec2 as Vector3) as Vector3
    dim as Vector3 outVec
    
    outVec.x = vec1.x - vec2.x
    outVec.y = vec1.y - vec2.y
    outVec.z = vec1.z - vec2.z
    
    return outVec
end function

private sub BuildNormalMatrix( byref tmIn as Matrix4x4, byref tmOut as Matrix3x3 )
    ' M() = 16 elements of 4x4 modelview (column-major, OpenGL style)
    ' N() = 9 elements (3x3) to receive the inverse-transposed matrix

    dim as single a00 = tmIn.M(0), a01 = tmIn.M(4), a02 = tmIn.M(8)
    dim as single a10 = tmIn.M(1), a11 = tmIn.M(5), a12 = tmIn.M(9)
    dim as single a20 = tmIn.M(2), a21 = tmIn.M(6), a22 = tmIn.M(10)

    ' Compute determinant
    dim as single det = a00*(a11*a22 - a12*a21) - a01*(a10*a22 - a12*a20) + a02*(a10*a21 - a11*a20)
    if det = 0 then det = 1e-9
    det = 1.0 / det

    ' Compute inverse and transpose in one go
    tmOut.M(0) =  (a11*a22 - a12*a21) * det
    tmOut.M(1) =  (a12*a20 - a10*a22) * det
    tmOut.M(2) =  (a10*a21 - a11*a20) * det

    tmOut.M(3) =  (a02*a21 - a01*a22) * det
    tmOut.M(4) =  (a00*a22 - a02*a20) * det
    tmOut.M(5) =  (a01*a20 - a00*a21) * det

    tmOut.M(6) =  (a01*a12 - a02*a11) * det
    tmOut.M(7) =  (a02*a10 - a00*a12) * det
    tmOut.M(8) =  (a00*a11 - a01*a10) * det
end sub

Function Mat3_RotX(angle As Single) As Matrix3x3
    Dim As Matrix3x3 R
    Dim As Single c = Cos(angle), s = Sin(angle)

    ' row-major:
    ' [ 1  0  0 ]
    ' [ 0  c -s ]
    ' [ 0  s  c ]

    R.m(0) = 1 : R.m(1) = 0 : R.m(2) = 0
    R.m(3) = 0 : R.m(4) = c : R.m(5) = -s
    R.m(6) = 0 : R.m(7) = s : R.m(8) =  c

    Return R
End Function
Function Mat3_RotY(angle As Single) As Matrix3x3
    Dim As Matrix3x3 R
    Dim As Single c = Cos(angle), s = Sin(angle)

    ' row-major:
    ' [  c  0  s ]
    ' [  0  1  0 ]
    ' [ -s  0  c ]

    R.m(0) =  c : R.m(1) = 0 : R.m(2) = s
    R.m(3) =  0 : R.m(4) = 1 : R.m(5) = 0
    R.m(6) = -s : R.m(7) = 0 : R.m(8) = c

    Return R
End Function
Function Mat3_RotZ(pi As Single) As Matrix3x3
    Dim As Matrix3x3 R
    Dim As Single c = Cos(pi), s = Sin(pi)

    R.m(0)=c : R.m(1)=-s : R.m(2)=0
    R.m(3)=s : R.m(4)= c : R.m(5)=0
    R.m(6)=0 : R.m(7)= 0 : R.m(8)=1

    Return R
End Function

#if 0
' Generates a rotation matrix that aligns the model's Y-axis with the TargetUp vector.
' WorldForward is an optional vector to define the "twist" around TargetUp.
Function MatrixFromUpVector(Byref TargetUp As Vector3, Byref WorldForward As Vector3) As Matrix3x3
    Dim As Matrix3x3 R
    Dim As Vector3 NewY, NewX, NewZ
    
    ' 1. The new Y-axis (Up) is the normalized target vector.
    NewY = VectorNormalize(TargetUp)
    
    ' 2. Calculate the new X-axis (Right)
    '    It must be perpendicular to both the new Y (TargetUp) and WorldForward.
    '    We use the cross product: X' = WorldForward x Y'
    '    This ensures X' and Y' are perpendicular.
    NewX = VectorCross(WorldForward, NewY)
    
    ' Handle the degenerate case where WorldForward is parallel to TargetUp (cross product is zero)
    Dim As Single xlen = VectorLength(NewX)
    If xlen < 0.00001 Then
        ' WorldForward and TargetUp are parallel.
        ' Pick an arbitrary, non-parallel vector (e.g., world (1, 0, 0)) to define the right axis.
        ' This prevents the matrix generation from failing.
        Dim As Vector3 ArbitraryForward = {0, 0, 1} ' World Z-axis
        NewX = VectorCross(ArbitraryForward, NewY)
        xlen = VectorLength(NewX)
        
        ' If it's STILL zero, TargetUp is (0,0,1) or (0,0,-1). Use World X-axis.
        If xlen < 0.00001 Then 
            Dim As Vector3 ArbitraryRight = {1, 0, 0}
            NewX = VectorCross(ArbitraryRight, NewY)
        End If
    End If
    
    NewX = VectorNormalize(NewX)
    
    ' 3. Calculate the new Z-axis (Forward)
    '    It must be perpendicular to both NewX and NewY.
    '    We use the cross product: Z' = Y' x X'
    NewZ = VectorCross(NewY, NewX)
    ' NewZ must be normalized due to floating point inaccuracies, 
    ' even though NewX and NewY are normalized and perpendicular.
    NewZ = VectorNormalize(NewZ) 

    ' 4. Construct the 3x3 Rotation Matrix (Column-Major Convention)
    ' The column vectors of the rotation matrix are the new basis vectors (X', Y', Z').
    
    ' Column 0 (New X-axis / Right)
    R.m(0, 0) = NewX.x : R.m(1, 0) = NewX.y : R.m(2, 0) = NewX.z
    
    ' Column 1 (New Y-axis / Up)
    R.m(0, 1) = NewY.x : R.m(1, 1) = NewY.y : R.m(2, 1) = NewY.z
    
    ' Column 2 (New Z-axis / Forward)
    R.m(0, 2) = NewZ.x : R.m(1, 2) = NewZ.y : R.m(2, 2) = NewZ.z
    
    Return R
End Function
#endif
