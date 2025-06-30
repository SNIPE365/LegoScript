type fbStr
   pzText as zstring ptr
   iLen as integer
   iSize as integer
end type

dim as string sTemp(199) = { _
   "One","Two","Three","Four","Five","Six","Seven","Eight","Nine","Ten", _
   "Eleven","Twelve","Thirteen","Fourteen","Fifteen","Sixteen","Seventeen","Eighteen","Nineteen","Twenty" }
  
sleep

'for N as long = 0 to 19 : print sTemp(N) : next N : sleep : cls
dim as double dTMR = timer
for I as long = 0 to 99999999

   sTemp(10)=""
   for N as long = 10 to 199-1
      *cptr(fbStr ptr,@sTemp(N)) = *cptr(fbStr ptr,@sTemp(N+1))
   next N   
   
   'for N as long = 0 to 18 : print sTemp(N) : next N : sleep : cls
      
   for N as long = 199-1 to 10 step -1
      *cptr(fbStr ptr,@sTemp(N+1)) = *cptr(fbStr ptr,@sTemp(N))
   next N
   clear *(@sTemp(10)),0,sizeof(fbStr)
   sTemp(10)="Eleven"
   
   'for N as long = 0 to 19 : print sTemp(N) : next N : sleep : cls

next I
print cint((timer-dTMR)*1000),"header move"

sleep

dTMR = timer
for I as long = 0 to 999999

   for N as long = 10 to 199-1
      sTemp(N) = sTemp(N+1)
   next N
   sTemp(199)=""
   
   'for N as long = 0 to 18 : print sTemp(N) : next N : sleep : cls
      
   for N as long = 199-1 to 10 step -1
      sTemp(N+1) = sTemp(N)
   next N
   sTemp(10)="Eleven"
   
   'for N as long = 0 to 19 : print sTemp(N) : next N : sleep : cls
   
next I
print cint((timer-dTMR)*1000),"string move"

sleep

