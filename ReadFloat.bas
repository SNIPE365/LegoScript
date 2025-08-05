function ReadFloat( pFile as ubyte ptr , byref fFloat as single ) as long
   dim as long iResu=0,iDecimal=0,iDecMask=1,iRead, iHasDigits=0,iHasDot,iSign=1
   do
      select case pFile[iRead]
      case asc("0") to asc("9")      'add a digit to the number
         if iHasDot=0 then            
            iResu=iResu*10+(pFile[iRead]-asc("0"))
         else
            iDecimal=iDecimal*10+(pFile[iRead]-asc("0"))
            iDecMask *= 10
         end if
         iHasDigits = 1
      case asc(" "),9                'skip spaces/tab
         if iHasDigits then exit do
      case asc(!"\r")               'skip the \r in case EOL is \r\n
         rem nothing to do here
      case asc(!"\n"),0  'if it's EOL/EOF then we assume it was read 0
         iHasDigits = 1 : exit do      
      case asc(".")         
         if iHasDot then exit do
         iHasDot=1 : iHasDigits=1                  
      case asc("-")
         if iSign=1 andalso iHasDigits=0 then iSign=-1 else exit do
      case else
         exit do
      end select 
      iRead += 1
   loop   
   'we're done processing digits, but did we read a number at all?
   if iHasDigits=0 then fFloat=pFile[iRead] : return -1
   fFloat = iResu*iSign+iDecimal/iDecMask
   return iRead
end function

dim as single fNum
dim as zstring*32 pzNum = ".432"
if ReadFloat( @pzNum , fNum )<0 then print "Error" else print fNum
sleep