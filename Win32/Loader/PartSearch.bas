#ifndef __Main
  #error " Don't compile this one"
#endif  

#include once "crt.bi"
#include once "Include\PartPaths.bas"

#ifndef GiveUp
  #define GiveUp(_N) sleep : end (_N)
#endif

#macro ForEachPartFlag(_Do)   
   _Do(Donor      ,  0 ) 'what is donor parts
   _Do(Alias      ,  1 ) 'alias to another part
   _Do(PreColored ,  2 ) 'have predefined color(s)
   _Do(Path       ,  3 ) 
   _Do(Shortcut   ,  4 ) 
   _Do(MultiColor ,  5 ) 
   _Do(Template   ,  6 ) 
   _Do(Printed    ,  7 ) 
   _Do(Stickered  ,  8 ) 
   _Do(Moulded    ,  9 ) 
   _Do(Sticker    , 10 ) 
   _Do(Helper     , 11 ) 
   _Do(Inverted   , 14 )
   _Do(Hidden     , 15 ) 'last one for generically hide the parts
#endmacro  

enum PartFlags
   #define DeclarePartFlag( _Name , _Bit ) wIs##_Name = 1 shl (_Bit)
   ForEachPartFlag( DeclarePartFlag )
   #undef DeclarePartFlag
end enum   
enum PartTypes
   ptUnknown
   ptBrick
   ptPlate
end enum

type SearchPartStruct   
   iPartIndex as ulong
   iPrev      as ulong
   qData      as ulongint
   wFlags     as ushort
   iFolder    as ubyte   
   bType      as ubyte   
   zDesc      as zstring*108   'piece description (first line)
   zName      as zstring*65535 'name limit
end type
#if __FB_EVAL__(offsetof(SearchPartStruct,zName)) <> 128  
   #print __FB_EVAL__( offsetof(SearchPartStruct,zName) )
   #error " SearchPartStruct have bad size"
#endif  

static shared as ulong g_lHashList(65535), g_lPartCount
redim shared as ulong g_lPartIndex(0)
dim shared as any ptr g_pPartsNames

#define PartStructFromIndex(_Idx) cptr( SearchPartStruct ptr , g_pPartsNames+g_lPartIndex(_Idx) )

function HashName( sName as string ) as ushort
   var iHash = 65535
   dim as long I
   do
      if sName[I]=0 then return (iHash+I) and 65535
      iHash = iHash*19 + (sName[I] or 32)-asc("0")
      I += 1
   loop   
end function
function ComparePartNames( pbA as ubyte ptr , pbB as ubyte ptr ) as long    
  if pbA=0 orelse pbB=0 then
    if pbA=0 andalso pbB=0 then return 0
    if pbA=0 then return -1
    return 1
  end if
  do
    var iA = *pbA or 32 , iB = *pbB or 32
    if iA <> iB then return clng(iA)-clng(iB)
    if *pbA = 0 then return 0
    pbA += 1 : pbB += 1
  loop
end function   
function ComparePartialNames( pbA as ubyte ptr , pbB as ubyte ptr ) as long
  if pbA=0 orelse pbB=0 then
    if pbA=0 andalso pbB=0 then return 0
    if pbA=0 then return -1
    return 1
  end if   
  do
    var iA = *pbA or 32 , iB = *pbB or 32      
    if *pbA = 0 then return 0
    if iA <> iB then return clng(iA)-clng(iB)      
    pbA += 1 : pbB += 1
  loop
end function   
function FindPart( sName as string ) as SearchPartStruct ptr
   var iHash = HashName( sName )   
   var iOffset = g_lHashList( iHash )
   var sNameL = sName+".dat" , pbName = cptr(ubyte ptr,strptr(sNameL))
   'walk trough the conflicts to validate   
   while iOffset
      with *cptr(SearchPartStruct ptr,g_pPartsNames+iOffset)
         'if name matches  then we found         
         if ComparePartNames( pbName , cptr(ubyte ptr,@.zName) ) = 0 then return g_pPartsNames+iOffset
         iOffset = .iPrev
      end with
   wend
   'if reaching here means it didnt found
   return NULL
end function
function CompareIndexedPartName cdecl ( pA as const any ptr , pB as const any ptr ) as long   
   #define t(_N) cptr( SearchPartStruct ptr , g_pPartsNames+*cptr( ulong ptr , _N) )
   var pbA = cptr(ubyte ptr, @(t(pA)->zName))
   var pbB = cptr(ubyte ptr, @(t(pB)->zName))
   var iResu = ComparePartNames( pbA , pBB )
   if iResu=0 then return t(pA)->iFolder - t(pB)->iFolder
   return ComparePartNames( pbA , pBB )
end function
function FindPartIndex( sName as string ) as long
   dim as long uFirst=0,uLast=g_lPartCount-1',uPrevMid
   var sNameL = sName+".dat" , pName = cptr(ubyte ptr,strptr(sNameL))
   do 'cptr( SearchPartStruct ptr , g_pPartsNames+g_lPartIndex(uMid)
      var uMid = (uFirst+uLast)\2
      'if uMid = uPrevMid then return -1
      var pbB = cptr(ubyte ptr, @( PartStructFromIndex(uMid)  )->zName)      
      var uCmp = ComparePartNames( pName , pbB )
      'print *cptr(zstring ptr,pName),*cptr(zstring ptr,pbB),uCmp
      if uCmp=0 then return uMid
      if uFirst = uLast then return -1
      if uCmp>0 then uFirst = uMid+1 else uLast = uMid-1
      if uFirst > uLast then return -1
   loop
end function
function SearchPart( sName as string , iPrev as long = -1 ) as long
   dim as long uFirst=0,uLast=g_lPartCount-1,uMid=any ',uPrevMid
   if len(sName)=0 then return -1
   var sNameL = sName , pName = cptr(ubyte ptr,strptr(sNameL))
   'printf(!"{First=%i Last=%i} Name='%s' Prev=%i\n",uFirst,uLast,sName,iPrev)
   if iPrev < 0 then
      do 
         uMid = (uFirst+uLast)\2      
         var pbB = cptr(ubyte ptr, @( PartStructFromIndex(uMid)  )->zName)
         var uCmp = ComparePartialNames( pName , pbB )
         'print *cptr(zstring ptr,pName),*cptr(zstring ptr,pbB),uCmp
         if uCmp=0 then exit do 
         if uFirst = uLast then return -1
         if uCmp>0 then uFirst = uMid+1 else uLast = uMid-1
         if uFirst > uLast then return -1
      loop
      'get first that matches
      'printf(!"First=%i Mid=%i Last=%i\n",uFirst,uLast,uMid)
      while uMid > 0 andalso ComparePartialNames( pName , cptr(ubyte ptr, @( PartStructFromIndex(uMid-1)  )->zName) )=0
         uMid -= 1
      wend
      return uMid
   else
      if ComparePartialNames( pName , cptr(ubyte ptr, @( PartStructFromIndex(iPrev+1)  )->zName) ) then return -1
      return iPrev+1
   end if            
end function

function instrWhole( sText as string , sSearch as string ) as long
   var iResu = instr(sText,sSearch)
   if iResu=0 then return 0   
   select case sText[iResu+len(sSearch)-1]
   case asc("0") to asc("9"), asc("A") to asc("Z"), asc("a") to asc("z")
      return 0
   end select
   return iResu
end function
function LoadPartNames() as long
   
   var f = freefile()
   dim as ulong uPartNamesSize = sizeof(ulong)
   
   if open(exepath+"\PartCache.bin" for binary access read as #f) then   
      puts("parts cache not found, so recreating the cache")
      if g_pPartsNames then deallocate(g_pPartsNames)
      g_pPartsNames = allocate(uPartNamesSize)
      
      for N as long = 1 to ubound(g_sPathList)
         var sPath = g_sPathList(N) & "\"
         if lcase(right(sPath,7)) <> "\parts\" then continue for
         'if instr(sPath,"\p\") then exit for 'exits when subparts/primatives start   
         var sName = dir( sPath & "*.dat")
         
         #ifdef DebugLoading
            puts "-- '" +sPath+"' --"
         #endif
         
         var iLen = len(sName), sDesc = ""
         while iLen
            'opening the file to extract metadata
            var f = freefile(), iGotComment=0, sLine = "",wFlags=0
            var bDetectedType=ptUnknown
            open sPath & sName for input as #f         
            do until eof(f) 'get first line containing '0 comment'
               line input #f, sLine               
               sLine = lcase(trim(sLine))         'ignore leading spaces and simplify casing
               if len(sLine)=0 then continue do   'ignore if empty line
               if sLine[0]<>asc("0") then exit do 'stop at the first non comment line
               'if instr(sLine,"!help")                 then wFlags or= wIsHelper
               if sLine[2] = asc("~")                  then wFlags or= wIsShortcut
               if instr(sLine,"helper")                then wFlags or= wIsHelper
               if instr(sLine,"unofficial_part alias") then wFlags or= wIsAlias
               if instr(sLine,"unofficial_shortcut")   then wFlags or= wIsShortCut
               if instr(sLine,"sticker")               then wFlags or= wIsStickered               
               if instrWhole(sLine," print")            then wFlags or= wIsHidden
               if instrWhole(sLine," pattern")          then wFlags or= wIsHidden
               if iGotComment=0 then 
                  if sLine[2] = asc("=")               then wFlags or= wIsAlias
                  if instrWhole(sLine," brick") then bDetectedType = ptBrick
                  if instrWhole(sLine," plate") then bDetectedType = ptPlate
                  sDesc = sLine : iGotComment=1
               end if               
            loop         
            close #f
            if iGotComment=0 then
               puts "WARNING: couldnt obtain comment for '"+sName+"'"
            end if                        
            
            'hashing the partID without extension
            var iChar = sName[iLen-4] : sName[iLen-4]=0
            var iHash = HashName( sName ) : sName[iLen-4] = iChar
            
            'if instr(ucase(sName),"BEAD") then print sName,iHash
            'if iHash = 21488 then end
            'size of the new part aligned to 4 bytes.
            var iSize = ((offsetof(SearchPartStruct,zName)+iLen+1) or 3)+1      
            g_pPartsNames = reallocate( g_pPartsNames , uPartNamesSize+iSize )
            if g_pPartsNames = NULL then
               puts "Failed reallocate"
               GiveUp(2)
            end if
            
            with *cptr( SearchPartStruct ptr , g_pPartsNames+uPartNamesSize )
               .iPartIndex = 0 : .iFolder = N
               .iPrev  = g_lHashList(iHash)
               .wFlags = wFlags
               .bType  = bDetectedType
               .zDesc  = mid(sDesc,3)
               .zName  = sName               
            end with      
            if (g_lPartCount and 1023)=0 then redim preserve g_lPartIndex(g_lPartCount+1023)            
            g_lHashList(iHash)=uPartNamesSize
            g_lPartIndex(g_lPartCount)=uPartNamesSize
            g_lPartCount += 1
            uPartNamesSize += iSize
            sName = dir() : iLen = len(sName)
         wend
      next N
      redim preserve g_lPartIndex(g_lPartCount-1)
      qsort( @g_lPartIndex(0) , g_lPartCount , sizeof(long) , @CompareIndexedPartName )
            
      if open(exepath+"\PartCache.bin" for binary access write as #f) then
         puts "ERROR: failed to open file to write cache file"
      else
         put #f,,g_lPartCount
         put #f,,uPartNamesSize
         put #f,,g_lHashList()
         put #f,,g_lPartIndex()
         put #f,,*cptr(ubyte ptr,g_pPartsNames),uPartNamesSize
         close #f
      end if
          
   else 'quickly loading the cache
      get #f,,g_lPartCount
      get #f,,uPartNamesSize
      redim g_lPartIndex(g_lPartCount-1)
      get #f,,g_lHashList()
      get #f,,g_lPartIndex(0),g_lPartCount
      g_pPartsNames = allocate(uPartNamesSize)
      if g_pPartsNames=0 then puts "ERROR: Failed to allocate memory for parts cache"
      get #f,,*cptr(ubyte ptr,g_pPartsNames),uPartNamesSize
      close #f
   end if
      
   #ifdef DebugLoading
      puts "Parts: " &  g_lPartCount
      puts "Name sizes: " & uPartNamesSize\1024 & "kb"
    #endif
   return true
end function

LoadPartNames()

#if 0 'show all parts descriptions and names
   for N as long = 0 to g_lPartCount-1
      with *cptr(SearchPartStruct ptr, g_pPartsNames+g_lPartIndex(N))
         print left(.zDesc+space(87),87) &  " " & .zName
      end with
   next
   sleep
#endif
#if 0 'showing parts with names containing
   for N as long = 0 to g_lPartCount-1
      with *cptr(SearchPartStruct ptr, g_pPartsNames+g_lPartIndex(N))
         if instr(.zName,"3024") then
            print N, .zName         
         end if
      end with
   next N
   sleep
#endif
#if 0 'test part search
   print "----"
   print FindPart("BEAD004")
   print g_pPartsNames+g_lPartIndex(FindPartIndex("BEAD004"))
   sleep
#endif
#if 0 'test searching for all parts
   dim as double dTMR = timer
   for N as long = 0 to g_lPartCount-1
      var sName = cptr(SearchPartStruct ptr, g_pPartsNames+g_lPartIndex(N))->zName   
      cptr(ulong ptr,@sName)[1] -= 4 : sName[cptr(ulong ptr,@sName)[1]]=0   
      if FindPart( sName )=0 then print "FindPart Error!"
   next N
   dTMR = timer-dTMR
   print "FindPart.....: ";cint(dTMR*1000);"ms"
   dTMR = timer
   for N as long = 0 to g_lPartCount-1
      var sName = cptr(SearchPartStruct ptr, g_pPartsNames+g_lPartIndex(N))->zName
      cptr(ulong ptr,@sName)[1] -= 4 : sName[cptr(ulong ptr,@sName)[1]]=0
      if FindPartIndex( sName )<0 then print "FindPartIndex Error!"
   next N
   dTMR = timer-dTMR
   print "FindPartIndex: ";cint(dTMR*1000);"ms"
   print "Done."
   sleep
#endif
#if 0 'test how many searches per second
   dim as SearchPartStruct ptr pPart

   dim as double dTime = timer
   dim as long iPerSec
   do
     for N as long = 0 to 986
      pPart = FindPart("3024")
     next N
     iPerSec += 987
   loop until (timer-dTime)>1
     
   print "Searches per second: ";iPerSec
   if pPart = NULL then
      print "Part not found" : sleep : system
   end if   
   with *pPart
      print *g_pzPaths(.iFolder)+"\"+.zName
   end with
   sleep
#endif