#ifndef __Main
  #error " Don't compile this one"
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

scope
   dim as Matrix4x4 tIdentityMatrix = ( _
      { 1, 0, 0, 0,  _
        0, 1, 0, 0,  _
        0, 0, 1, 0,  _
        0, 0, 0, 1 } _
   )
   tMatrixStack( 0 ) = tIdentityMatrix
end scope
sub PushAndMultMatrix( pIn as const single ptr )
   var pCur = cast(single ptr,@tMatrixStack(g_CurrentMatrix))
   g_CurrentMatrix += 1
   if g_CurrentMatrix > 1023 then
      puts("MATRIX STACK OVERFLOW!!!!")
      sleep : system
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
   
end sub
sub PopMatrix()
   if g_CurrentMatrix>0 then g_CurrentMatrix -= 1
end sub   
sub MultiplyMatrixVector( pVec as single ptr )
   dim as single fX = pVec[0] , fY = pVec[1] , fZ = pVec[2]
   with tMatrixStack(g_CurrentMatrix)
      pVec[0] = .m(0) * fX + .m(4) * fY + .m( 8) * fZ + .m(12)
      pVec[1] = .m(1) * fX + .m(5) * fY + .m( 9) * fZ + .m(13)
      pVec[2] = .m(2) * fX + .m(6) * fY + .m(10) * fZ + .m(14)
   end with
end sub
sub glLoadCurrentMatrix()
   'with tMatrixStack(g_CurrentMatrix)
   'glLoadMatrixf( @tMatrixStack(g_CurrentMatrix).m(0) )
   glMultMatrixf( @tMatrixStack(g_CurrentMatrix).m(0) )   
end sub
