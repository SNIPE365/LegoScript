#cmdline "-gen gcc -O 1"

type MyStruct
   x as long
   y as long
   z as long
   w as long
end type
  
dim as ulong uIndex(65535)
dim as MyStruct tStruct(255)
for N as long = 0 to 65535
   uIndex(N) = int(rnd*256)   
next N
for N as long = 0 to 255
   with tStruct( N )
      .x = rnd*65536
      .y = rnd*65536
      .z = rnd*65536
   end with
next N

dim as long sum
dim as double TMR = timer
for K as long = 0 to 9999
   for N as long = 0 to 65535
      with tStruct( uIndex(N) )
         sum += .x
      end with
   next N
next K
print timer-TMR

sleep