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

dim shared as Matrix4x4 g_tIdentityMatrix = ( _
   { 1, 0, 0, 0,  _
     0, 1, 0, 0,  _
     0, 0, 1, 0,  _
     0, 0, 0, 1 } _
)
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
#define MultMatrix4x4( _Out , _In , _pMul ) MultMatrix4x4WithVector3x3( _Out , _In , cptr(const single ptr,(_pMul)) )

sub MatrixRotateX( tmOut as Matrix4x4 , tmIn as Matrix4x4 , fAngle as single )      
   dim as single sMat(15) = { _
      1 ,      0       ,      0      , 0 , _
      0 ,  cos(fAngle) , sin(fAngle) , 0 , _
      0 , -sin(fAngle) , cos(fAngle) , 0 , _
      0 ,      0       ,      0      , 1 _
   }   
   MultMatrix4x4WithVector3x3( tmOut , tmIn , @sMat(0) )
end sub
sub MatrixRotateY( tmOut as Matrix4x4 , tmIn as Matrix4x4 , fAngle as single )      
   dim as single sMat(15) = { _
      cos(fAngle) , 0 , -sin(fAngle) , 0 , _
          0       , 1 ,     0        , 0 , _
      sin(fAngle) , 0 ,  cos(fAngle) , 0 , _
         0        , 0 ,     0        , 1 _
   }
   MultMatrix4x4WithVector3x3( tmOut , tmIn , @sMat(0) )
end sub
sub MatrixRotateZ( tmOut as Matrix4x4 , tmIn as Matrix4x4 , fAngle as single )      
   dim as single sMat(15) = { _
      cos(fAngle) , -sin(fAngle) , 0 , 0 , _
      sin(fAngle) ,  cos(fAngle) , 0 , 0 , _
          0       ,      0       , 0 , 0 , _
          0       ,      0       , 0 , 1 _
   }   
   MultMatrix4x4WithVector3x3( tmOut , tmIn , @sMat(0) )
end sub

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
sub glLoadCurrentMatrix()
   'with tMatrixStack(g_CurrentMatrix)
   'glLoadMatrixf( @tMatrixStack(g_CurrentMatrix).m(0) )
   glMultMatrixf( @tMatrixStack(g_CurrentMatrix).m(0) )   
end sub
#endif
