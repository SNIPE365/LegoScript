#ifndef __Main
  #error " Don't compile this one"
#endif  

#ifndef GiveUp
  #define GiveUp(_N) sleep : end (_N)
#endif

'type Matrix4x4
'   m(15) as single
'end type   
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
function PushAndMultMatrix( pIn as const single ptr ) as boolean
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
function MultCurrentMatrix( pIn as const single ptr ) as boolean
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
sub PushIdentityMatrix()
   g_CurrentMatrix += 1   
   tMatrixStack( g_CurrentMatrix ) = g_tIdentityMatrix 'tMatrixStack( 0 )
end sub
sub PopMatrix()
   if g_CurrentMatrix>0 then g_CurrentMatrix -= 1
end sub   
sub MultiplyMatrixVector( pVec as single ptr , pMatrix as Matrix4x4 ptr = 0 )
   dim as single fX = pVec[0] , fY = pVec[1] , fZ = pVec[2]
   if pMatrix=0 then pMatrix = @tMatrixStack(g_CurrentMatrix)
   with *pMatrix
      pVec[0] = .m(0) * fX + .m(4) * fY + .m( 8) * fZ + .m(12)
      pVec[1] = .m(1) * fX + .m(5) * fY + .m( 9) * fZ + .m(13)
      pVec[2] = .m(2) * fX + .m(6) * fY + .m(10) * fZ + .m(14)
   end with
end sub
function IsMatrixIdentity() as boolean
   with tMatrixStack( g_CurrentMatrix )
      for N as long = 0 to 15
         if abs(.m(N)-g_tIdentityMatrix.m(N)) > .0001 then return false
      next N      
   end with
   return true
end function   
sub PrintCurrentMatrix()
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

#ifndef __NoRender
#if 0
sub glLoadCurrentMatrix()
   'with tMatrixStack(g_CurrentMatrix)
   'glLoadMatrixf( @tMatrixStack(g_CurrentMatrix).m(0) )
   glMultMatrixf( @tMatrixStack(g_CurrentMatrix).m(0) )   
end sub
#endif
#endif

sub MultMatrix4x4WithVector3x3( tmOut as Matrix4x4 , tmIn as Matrix4x4 , pIn as const single ptr )
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

sub MultMatrix4x4(byref result as Matrix4x4, byref a as Matrix4x4, byref b as Matrix4x4)
    dim as integer i=any, j=any, k=any
    for j = 0 to 3 ' Columns of the result
        for i = 0 to 3 ' Rows of the result
            result.m(j * 4 + i) = 0.0
            for k = 0 to 3
                ' The indexing here is different
                result.m(j * 4 + i) += a.m(k * 4 + i) * b.m(j * 4 + k)
            next k
        next i
    next j    
end sub

#if 0
sub MultMatrix4x4_RowMajor(byref result as Matrix4x4, byref a as Matrix4x4, byref b as Matrix4x4)
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
sub MultMatrix4x4_ColumnMajor(byref result as Matrix4x4, byref a as Matrix4x4, byref b as Matrix4x4)
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
sub Matrix4x4RotateX( tmOut as Matrix4x4 , tmIn as Matrix4x4 , fAngle as single )      
   dim as single sMat(15) = { _
      1 ,      0       ,      0      , 0 , _
      0 ,  cos(fAngle) , sin(fAngle) , 0 , _
      0 , -sin(fAngle) , cos(fAngle) , 0 , _
      0 ,      0       ,      0      , 1 _
   }   
   MultMatrix4x4( tmOut , tmIn , *cptr(Matrix4x4 ptr,@sMat(0)) ) 'MultMatrix4x4WithVector3x3( tmOut , tmIn , @sMat(0) )
end sub
sub Matrix4x4RotateY( tmOut as Matrix4x4 , tmIn as Matrix4x4 , fAngle as single )      
   dim as single sMat(15) = { _
      cos(fAngle) , 0 , -sin(fAngle) , 0 , _
          0       , 1 ,     0        , 0 , _
      sin(fAngle) , 0 ,  cos(fAngle) , 0 , _
         0        , 0 ,     0        , 1 _
   }
   'MultMatrix4x4WithVector3x3( tmOut , tmIn , @sMat(0) )
   MultMatrix4x4( tmOut , tmIn , *cptr(Matrix4x4 ptr,@sMat(0)) )
end sub
sub Matrix4x4RotateZ( tmOut as Matrix4x4 , tmIn as Matrix4x4 , fAngle as single )      
   dim as single sMat(15) = { _
      cos(fAngle) , -sin(fAngle) , 0 , 0 , _
      sin(fAngle) ,  cos(fAngle) , 0 , 0 , _
          0       ,      0       , 1 , 0 , _
          0       ,      0       , 0 , 1 _
   }   
   'MultMatrix4x4WithVector3x3( tmOut , tmIn , @sMat(0) )
   MultMatrix4x4( tmOut , tmIn , *cptr(Matrix4x4 ptr,@sMat(0)) )
end sub
sub Matrix4x4Translate( tmInOut as Matrix4x4 , fDX as single , fDY as single , fDZ as single )
   var tMat = g_tIdentityMatrix
   tMat.fPosX = fDX : tMat.fPosY = fDY : tMat.fPosZ = fDZ
   MultMatrix4x4( tmInOut , tMat , tmInOut )
   'MultMatrix4x4( tmInOut , tmInOut , tMat )
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
sub MultMatrix3x3(byref tmOut as Matrix3x3, byref tmA as Matrix3x3, byref tmB as Matrix3x3)
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
function InvertMatrix3x3(byref tmOut as Matrix3x3, byref tmIn as Matrix3x3) as boolean

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
sub Matrix3x3RotateX(byref tmOut as Matrix3x3, byref tmIn as Matrix3x3, fAngle as single)
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
sub Matrix3x3RotateY(byref tmOut as Matrix3x3, byref tmIn as Matrix3x3, fAngle as single)
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
sub Matrix3x3RotateZ(byref tmOut as Matrix3x3, byref tmIn as Matrix3x3, fAngle as single)
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
function Vector3_Transform(byref inVec as Vector3, byref inMat as Matrix3x3) as Vector3
    dim as Vector3 outVec

    outVec.x = inMat.m(0) * inVec.x + inMat.m(1) * inVec.y + inMat.m(2) * inVec.z
    outVec.y = inMat.m(3) * inVec.x + inMat.m(4) * inVec.y + inMat.m(5) * inVec.z
    outVec.z = inMat.m(6) * inVec.x + inMat.m(7) * inVec.y + inMat.m(8) * inVec.z
    
    return outVec
end function
' Adds two vectors together (V = A + B)
sub Vector3_Add(byref vec1 as Vector3, byref vec2 as Vector3)    
   with vec1
      .x += vec2.x
      .y += vec2.y
      .z += vec2.z
   end with
end sub
function Vector3_AddEx(byref vec1 as Vector3, byref vec2 as Vector3) as Vector3
    dim as Vector3 outVec
    
    outVec.x = vec1.x + vec2.x
    outVec.y = vec1.y + vec2.y
    outVec.z = vec1.z + vec2.z
    
    return outVec
end function
' Subtracts two vectors together (V = A + B)
sub Vector3_Sub(byref vec1 as Vector3, byref vec2 as Vector3)    
   with vec1
      .x -= vec2.x
      .y -= vec2.y
      .z -= vec2.z
   end with
end sub
function Vector3_SubEx(byref vec1 as Vector3, byref vec2 as Vector3) as Vector3
    dim as Vector3 outVec
    
    outVec.x = vec1.x - vec2.x
    outVec.y = vec1.y - vec2.y
    outVec.z = vec1.z - vec2.z
    
    return outVec
end function
