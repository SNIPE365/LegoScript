#ifndef __Main
  #error " Don't compile this one"
#endif  

static shared as double g_TotalLoadFileTime

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
        if iDecimal < 100000000 then
          iDecimal=iDecimal*10+(pFile[iRead]-asc("0"))
          iDecMask *= 10
        end if
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
#define ReadLine ReadFilename
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
function LoadFile( sFile as string , byref sFileContents as string , bAddPathToSearch as boolean = true ) as boolean
   dim as double dLoadTime = timer
   #ifdef DebugLoading
      printf "Loading '"+sFile+"' "
   #endif
   #ifdef g_sLog
   g_sLog += "Loading '"+sFile+"' "
   #endif
   if bAddPathToSearch then 'extract file path and set as one of the search folders
      var iPathLen = instrrev(sFile,"\") , iPathLen2 = instrrev(sFile,"/")
      if iPathLen2 > iPathLen then iPathLen = iPathLen2
      if iPathLen then
         g_sPathList(0) = left(sFile,iPathLen-1)
         dim as long N = any
         for N = 0 to g_iExtraPathCount-1
            if g_sExtraPathList(N) = g_sPathList(0) then exit for
         next N
         if N = g_iExtraPathCount then
            redim preserve g_sExtraPathList(g_iExtraPathCount)
            g_sExtraPathList(g_iExtraPathCount) = g_sPathList(0)
            g_iExtraPathCount += 1
         end if         
      else
         g_sPathList(0) = ""
      end if
   end if
   
   #ifdef IgnoreStudSubparts
     if instr(lcase(sFile),"stud") then 
       sFileContents = " ": return true
     end if
   #endif
   
   var f = freefile()
   if open(sFile for input as #f) then
      puts "Failed to open file '"+sFile+"'": getchar():system
      return false
   end if
   'puts "load file: '" & sFile & "'"
   
   dim as uinteger uFileSize = lof(f)   
   if uFileSize < (1024*1024) then
      #ifdef DebugLoading
         printf(!"%s\n",csng(uFileSize/(1024)) & "kb")
      #endif
      #ifdef g_sLog
         g_sLog &= csng(uFileSize/(1024)) & !"kb\n"
      #endif
   else
      #ifdef DebugLoading
         printf(!"%s\n",csng(uFileSize/(1024*1024)) & "mb")
      #endif
      #ifdef g_sLog
         g_sLog &= csng(uFileSize/(1024*1024)) & !"mb\n"
      #endif
   end if   
   sFileContents = string( uFileSize , 0 )
   get #f,,sFileContents
   close #f
   g_TotalLoadFileTime += timer-dLoadTime
   return true
end function
function FindFile( sFile as string ) as long   
   if len(sFile)=0 then return FALSE
   const cPathLastIndex = ubound(g_sPathList)
   dim as byte bTried( cPathLastIndex )
   for N as long = g_LoadQuality to 3
      for I as long = cPathLastIndex to 0 step -1
         if g_bPathQuality(I) > N then continue for
         if bTried(I) then continue for else bTried(I)=1
         var sFullPathFile = g_sPathList(I)
         if sFile[0] <> asc("\") then sFullPathFile += "\"
         sFullPathFile += sFile
         'puts("#" & I & ": " & sFullPathFile)         
         if FileExists( sFullPathFile ) then
            sFile = lcase(sFullPathFile) : return TRUE         
         end if
      next I
   next N
   for N as long = 0 to g_iExtraPathCount-1      
      var sFullPathFile = g_sExtraPathList(N)
      if sFile[0] <> asc("\") then sFullPathFile += "\"
      sFullPathFile += sFile
      'puts("#" & N & ": " & sFullPathFile)
      if FileExists( sFullPathFile ) then
         sFile = lcase(sFullPathFile) : return TRUE         
      end if
   next N
   return FALSE
end function
function FindShadowFile( sFile as string ) as long
   for I as long = 0 to ubound(g_sShadowPathList)               
      var sFullPathFile = g_sShadowPathList(I)
      if sFile[0] <> asc("\") then sFullPathFile += "\"
      sFullPathFile += sFile
      'print sFullPathFile
      if FileExists( sFullPathFile ) then
         sFile = sFullPathFile : return TRUE         
      end if
   next I
   return FALSE
end function
function ReadBracketOption( pFile as ubyte ptr , sName as string , sParms as string ) as long
   dim as long iRead=0, iSize=0
   dim as zstring ptr pzName=0, pzParms=0
   dim as byte bOpen, bSpace
   dim as ubyte bPrevious = any
   do
      select case pFile[iRead]
      case asc(" "),9 'spaces may be ignored
         if bOpen then 'we're reading the name/parms
            if iSize=0 then 'ignore leading spaces/tabs
               iSize -= 1 : if pzParms=0 then pzName += 1 else pzParms += 1
            else
               bSpace += 1 : iSize -= 1 'ignore ending spaces in name
            end if
         end if
      case asc("[")   'name/parms pairs are inside a single bracket
         if bOpen then return -1 'syntax error (recursive brackets not allowed)
         pzName = pFile+iRead+1 : bOpen = 1 
         iSize = -1 : bSpace = 0
      case asc("=")   'delimiter from name/parms
         if bOpen=0 then return -1 'syntax error (unexpected character out of place)
         if pzParms then return -1 'syntax error (can't have = as part of parameters)
         bPrevious = (*pzName)[iSize]
         (*pzName)[iSize] = 0 'set as string terminator for the zstring
         sName = *pzName 'creating the return string from the zstring
         (*pzName)[iSize] = bPrevious 'restore previous character
         pzParms = pFile+iRead+1 'now reading parameters
         iSize=-1 : bSpace = 0 'reset size/spaces
      case asc("]")   'end of name/parms pair
         if pzName=0 or pzParms=0 then return -1 'syntax error (name or parms not found)
         if bOpen=0 then return -1 'syntax error (close bracket without opening)
         'printf(!"!%i|%i!\n",iSize)
         bPrevious = (*pzParms)[iSize]
         (*pzParms)[iSize] = 0 'set as string terminator for the zstring
         sParms = *pzParms 'creating the return string from the zstring
         (*pzParms)[iSize] = bPrevious 'restore previous character
         iRead += 1 : exit do
      case asc(!"\r"),asc(!"\n"),0 'end of line/file
         if bOpen then return -1 'if inside brackets then it was premature, so... syntax error
         sName = "" 'if no more parms then name is empty
         exit do
      case else 'every other character
         if bSpace then
            if pzParms=0 then 
               return -1 'syntax error (space in middle of name)
            else
               iSize += bSpace 'account ignored spaces
            end if
            bSpace = 0
         end if         
         if bOpen=0 then return -1 'syntax error (characters only inside brackets)
      end select
      iRead += 1 : iSize += 1
   loop   
   'success
   return iRead
end function

'add filename to list of loaded files as well it's model index
'returns offset into the list where it was loaded
function LoadedList_AddFile( sFilename as string , iModelIndex as long ) as long
   function = len(g_sFilenames)            
   g_sFilenames += chr(255)+mkl(iModelIndex)+chr(0)+lcase(sFilename)+chr(0)
   exit function
end function
'checks if the file was on the loaded list and return it's offset
function LoadedList_IsFileLoaded( sFile as string ) as long
   var sFileL = lcase(sFile)+chr(0)
   return instr(g_sFilenames,chr(0)+sFileL)
end function
'return index of model from offset into loaded list
function LoadedList_IndexFromOffset( iOffset as long ) as long
   return *cptr(ulong ptr,strptr(g_sFilenames)+iOffset-(1+sizeof(ulong))) 
end function

'add a filename to the list of files that need to be loaded
sub QueueList_AddFile( sFile as string )
   g_sFilesToLoad += sFile+chr(0)
end sub

