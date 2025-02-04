dim as double dTIME = timer
var f = freefile()
if open("%userprofile%\Desktop\n\datsville_rev002.013_inlined_n_boxed_f.mpd" for input as #f) then
   print "Failed to open file": sleep:system
 end if
 dim as uinteger uFileSize = lof(f)
 print csng(uFileSize/(1024*1024));"mb"
#if 0
dim as string sLine
while not eof(f)
   line input #f, sLine
   'parse them
wend
#endif
dim as string sFile = string( lof(f) , 0 )
get #f,,sFile
#if 0
   var iLineStart = 1
   do
      var iPos = instr( iLineStart , sFile , !"\n" )   
      if iPos=0 then exit do
      iLineStart = iPos+1
   loop
#endif

dim as long iLineCount
for N as long = 0 to uFileSize-1
   select case sFile[N]
   case asc(!"\n")
      iLineCount += 1
   end select
next N
print timer-dTIME
sleep