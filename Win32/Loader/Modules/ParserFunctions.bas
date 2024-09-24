function ReadHex( pFile as ubyte ptr , byref iInt as long ) as long
   dim as long iResu = 0, iRead, iHasDigits=0   
   do      
      select case pFile[iRead]
      case asc("0") to asc("9")      'add a digit to the number
         iResu=iResu*16+(pFile[iRead]-asc("0"))
         iHasDigits = 1
      case asc("a") to asc("f")
         iResu=iResu*16+(pFile[iRead]-asc("a")+10)
         iHasDigits = 1
      case asc("A") to asc("F")
         iResu=iResu*16+(pFile[iRead]-asc("A")+10)
         iHasDigits = 1
      case asc(" "),9                'skip spaces/tab
         if iHasDigits then exit do
      case asc(!"\r")               'skip the \r in case EOL is \r\n
         rem nothing to do here
      case asc(!"\n"),0  'if it's EOL/EOF then we assume it was read 0
         iHasDigits = 1 : exit do      
      case else
         exit do
      end select 
      iRead += 1
   loop   
   'we're done processing digits, but did we read a number at all?
   if iHasDigits=0 then iInt=pFile[iRead] : return -1
   iInt = iResu
   return iRead
end function
function ReadInt( pFile as ubyte ptr , byref iInt as long ) as long
   dim as long iResu = 0, iRead, iHasDigits=0, iSign=1   
   do
      select case pFile[iRead]
      case asc("0") to asc("9")      'add a digit to the number
         iResu=iResu*10+(pFile[iRead]-asc("0"))
         iHasDigits = 1
      case asc(" "),9                'skip spaces/tab
         if iHasDigits then exit do
      case asc(!"\r")               'skip the \r in case EOL is \r\n
         rem nothing to do here
      case asc(!"\n"),0  'if it's EOL/EOF then we assume it was read 0
         iHasDigits = 1 : exit do
      case asc("-")
         if iSign=1 andalso iHasDigits=0 then iSign=-1 else exit do
      case asc("x"),asc("X")
         if iHasDigits andalso iResu=0 andalso iSign=1 then 
            iResu = ReadHex( pFile+iRead+1 , iInt )            
            if iResu <> 7 orelse (iInt shr 24)<>2 then return -1 'failed to read hex colour
            return iResu+iRead+1
         end if
         exit do
      case else
         exit do
      end select 
      iRead += 1
   loop   
   'we're done processing digits, but did we read a number at all?
   if iHasDigits=0 then iInt=pFile[iRead] : return -1
   iInt = iResu*iSign
   return iRead
end function
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
      case asc("E"),asc("e") 'scientific notation
         iRead += 1
         dim as long iExpoent = any, iExtra = any
         iExtra = ReadInt( pFile+iRead , iExpoent )
         if iExtra < 0 then return -1
         var fTemp = iResu*iSign+iDecimal/iDecMask
         if iExpoent < 0 then 'negative expoent
            while iExpoent <= -5 : fTemp = fTemp/100000 : iExpoent += 5 : wend   
            for N as long = 1 to -iExpoent : fTemp = fTemp/10 : next N
         else 'positive expoent
            while iExpoent >= 5 : fTemp = fTemp*100000 : iExpoent -= 5 : wend   
            for N as long = 1 to iExpoent : fTemp = fTemp*10 : next N
         end if
         fFloat = fTemp
         return iRead+iExtra
      case else
         exit do
      end select 
      iRead += 1
   loop   
   'we're done processing digits, but did we read a number at all?
   if iHasDigits=0 then fFloat=pFile[iRead] : return -1   
   fFloat = (iResu+iDecimal/iDecMask)*iSign
   return iRead
end function
function ReadFilename( pFile as ubyte ptr , byref sString as string ) as long
   dim as long iRead, iSize
   var pzStart = cptr( zstring ptr , pFile )
   do
      select case pFile[iRead]
      case asc(" "),9 'ignore leading spaces/tabs
         if iSize=0 then iSize -= 1 : pzStart += 1         
      case asc(!"\r"),asc(!"\n"),0
         exit do
      end select
      iRead += 1 : iSize += 1
   loop
   'ignore ending spaces/tabs
   while iSize andalso (*pzStart)[iSize-1] = asc(" ") orelse (*pzStart)[iSize-1] = 9
      iSize -= 1
   wend
   dim as ubyte bPrevious = pzStart[iSize]
   pzStart[iSize] = 0 'set as string terminator for the zstring
   sString = *pzStart 'creating the return string from the zstring
   pzStart[iSize] = bPrevious 'restore previous character
   return iRead
end function
function ReadToken( pFile as ubyte ptr , byref sString as string ) as long
   dim as long iRead, iSize
   var pzStart = cptr( zstring ptr , pFile )   
   do
      select case pFile[iRead]
      case asc(" "),9 'ignore leading spaces/tabs
         if iSize=0 then iSize -= 1 : pzStart += 1 else exit do
      case asc(!"\r"),asc(!"\n"),0
         exit do
      end select
      iRead += 1 : iSize += 1
   loop   
   dim as ubyte bPrevious = pzStart[iSize]
   pzStart[iSize] = 0 'set as string terminator for the zstring
   sString = *pzStart 'creating the return string from the zstring
   pzStart[iSize] = bPrevious 'restore previous character
   return iRead
end function

function LoadFile( sFile as string , byref sFileContents as string ) as boolean
   
   #ifdef DebugLoading
      print "Loading '"+sFile+"' ";      
   #endif
   #ifdef g_sLog
   g_sLog += "Loading '"+sFile+"' "
   #endif
   scope 'extract file path and set as one of the search folders
      var iPathLen = instrrev(sFile,"\") , iPathLen2 = instrrev(sFile,"/")
      if iPathLen2 > iPathLen then iPathLen = iPathLen2
      if iPathLen then
         g_sPathList(0) = left(sFile,iPathLen-1)
      else
         g_sPathList(0) = ""
      end if
   end scope
   
   var f = freefile()
   if open(sFile for input as #f) then
      print "Failed to open file '"+sFile+"'": sleep:system
      return false
   end if
   dim as uinteger uFileSize = lof(f)   
   if uFileSize < (1024*1024) then
      #ifdef DebugLoading
         print csng(uFileSize/(1024)) & "kb"
      #endif
      #ifdef g_sLog
         g_sLog &= csng(uFileSize/(1024)) & !"kb\n"
      #endif
   else
      #ifdef DebugLoading
         print csng(uFileSize/(1024*1024)) & "mb"
      #endif
      #ifdef g_sLog
         g_sLog &= csng(uFileSize/(1024*1024)) & !"mb\n"
      #endif
   end if   
   sFileContents = string( uFileSize , 0 )
   get #f,,sFileContents
   close #f
   return true
end function
function FindFile( sFile as string ) as long
   for I as long = 0 to ubound(g_sPathList)               
      var sFullPathFile = g_sPathList(I)
      if sFile[0] <> asc("\") then sFullPathFile += "\"
      sFullPathFile += sFile
      'print sFullPathFile
      if FileExists( sFullPathFile ) then
         sFile = sFullPathFile : return TRUE         
      end if
   next I
   return FALSE
end function
