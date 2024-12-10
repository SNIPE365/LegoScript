#include once "windows.bi"
#include once "fbgfx.bi"

#define __Main
#define __NoRender

#include once "Loader\PartSearch.bas"
#include once "Loader\LoadLDR.bas"   
#include once "Loader\Modules\Matrix.bas"
#include once "Loader\Modules\Model.bas"

#if 0
   var sFile = "3001.dat"
   dim as string sModel
   FindFile(sFile)
   if LoadFile( sFile , sModel ) = 0 then
      print "Failed to load '"+sFile+"'"
      sleep : system
   end if

   var pModel = LoadModel( strptr(sModel) , sFile )
   var pSnap = cptr(PartSnap ptr,pModel->pData)
   *pSnap = new PartSnap
   SnapModel( pModel , *pSnap )
   with *pSnap
      printf(!"Studs=%i Clutchs=%i Aliases=%i Axles=%i Axlehs=%i Bars=%i Barhs=%i Pins=%i Pinhs=%i\n", _
      .lStudCnt , .lClutchCnt , .lAliasCnt , .lAxleCnt , .lAxleHoleCnt ,.lBarCnt , .lBarHoleCnt , .lPinCnt , .lPinHoleCnt )
      puts("---------- stud ----------")
      for N as long = 0 to .lStudCnt-1
         with .pStud[N]
            printf(!"#%i %g %g %g\n",N+1,.fPX,.fPY,.fPZ)
         end with
      next N
      puts("--------- clutch ---------")
      for N as long = 0 to .lClutchCnt-1
         with .pClutch[N]
            printf(!"#%i %g %g %g\n",N+1,.fPX,.fPY,.fPZ)
         end with
      next N
   end with'
#endif

'puts("3001 B1 #2 s7 = 3001 B2 #2 c1;")
'puts("")
'puts("3001 B1 s7 = 3001 B2 c1;")
'puts("1 0 40 -24 -20 1 0 0 0 1 0 0 0 1 3001.dat")
'puts("1 0 0 0 0 1 0 0 0 1 0 0 0 1 3001.dat")

enum SeparatorType
   stNone
   stToken    = 1
   stOperator = 2
end enum
enum ErrorCodes
   ecNotFound       = -999
   ecFailedToLoad
   ecFailedToParse
   ecAlreadyExist
   ecSuccess        = 0
end enum   

type PartStructLS
   sName       as string
   sPrimative  as string
   iColor      as long
   iModelIndex as long
   bFoundPart  as byte
end type
type PartConnLS
   iLeftPart  as long
   iRightPart as long
   iLeftNum   as short
   iRightNum  as short
   iLeftType  as byte   
   iRightType as byte
   bResv(1)   as byte
end type
   
static shared as byte g_bSeparators(255)
static shared as PartStructLS g_tPart(1023)
static shared as PartConnLS   g_tConn(2047)
static shared as long g_iPartCount , g_iConnCount = 0

scope
   var sSeparators = !"\9 \r\n"   
   for N as long = 0 to len(sSeparators)-1
      g_bSeparators( sSeparators[N] ) or= stToken
   next N
   var sOperators  = !"="
   for N as long = 0 to len(sOperators)-1
      g_bSeparators( sOperators[N] ) or= stOperator
   next N
end scope

#define ErrInfo( _N ) (_N)

function IsTokenNumeric( sToken as string ) as long
   for N as long = 0 to len(sToken)-1
      if (cuint(sToken[N])-asc("0")) > 9 then return false
   next N
   return true
end function
function IsPrimative( sToken as string ) as long
   if len(sToken)=0 then return false
   for N as long = 0 to len(sToken)-1
      select case sToken[0]
      case asc("a") to asc("z"),asc("0") to asc("9"),asc("_")
         rem valid chars for primatives
      case else
         return false
      end select
   next N
   return true
end function
function IsValidPartName( sToken as string ) as long   
   if len(sToken)=0 then return false
   select case sToken[0]
   case asc("A") to asc("Z")
      rem valid initial chars for part names
   case else
      return false
   end select
   for N as long = 1 to len(sToken)-1
      select case sToken[N]
      case asc("A") to asc("Z"),asc("a") to asc("z")
         rem valid chars for part names
      case asc("0") to asc("9"),asc("_")
         rem valid chars for part names
      case else
         return false
      end select
   next N
   return true 
end function

function ParseColor( sToken as string ) as long
   var iLen = len(sToken), bHasHex = false, iTokenStart = 1
   if iLen < 1 orelse sToken[0] <> asc("#") then return ErrInfo(ecFailedToParse)
   dim as ulong uColor
   if (iLen-iTokenStart) = 6 then '#RRGGBB
      for N as long = iTokenStart to iLen-1
         select case sToken[N]
         case asc("0") to asc("9"): uColor = uColor*16+sToken[N]-asc("0")
         case asc("a") to asc("f"): uColor = uColor*16+sToken[N]-asc("a")+10
         case asc("A") to asc("F"): uColor = uColor*16+sToken[N]-asc("A")+10
         case else: return ErrInfo(ecFailedToParse)
         end select
      next N
      return uColor+&h1000000
   elseif (iLen-iTokenStart) = 4 then '#0RGB
      if sToken[iTokenStart]=asc("0") then
         iTokenStart += 1 : bHasHex = true
      end if
   end if
   if (iLen-iTokenStart) = 3 then '#RGB
      if sToken[iTokenStart]=asc("0") then bHasHex = 1
      for N as long = iTokenStart to iLen-1
         select case sToken[N]
         case asc("0") to asc("9"): uColor = uColor*256+(((sToken[N]-asc("0")   )*255)\15)
         case asc("a") to asc("f"): uColor = uColor*256+(((sToken[N]-asc("a")+10)*255)\15) : bHasHex = 1
         case asc("A") to asc("F"): uColor = uColor*256+(((sToken[N]-asc("A")+10)*255)\15) : bHasHex = 1
         case else: return ErrInfo(ecFailedToParse)
         end select
      next N
      if bHasHex then return uColor+&h1000000
   end if
   'decimal color index
   uColor = 0
   for N as long = iTokenStart to iLen-1
      select case sToken[N]
      case asc("0") to asc("9"): uColor = uColor*10+sToken[N]-asc("0")
      case else: return ErrInfo(ecFailedToParse)
      end select      
      if uColor > 10999 then return ErrInfo(ecFailedToParse)
   next N
   return uColor
end function

function FindPartName( sName as string ) as long
   if len(sName) < 1 then return ErrInfo(ecNotFound)
   for N as long = 0 to g_iPartCount-1
      with g_tPart(N)
         if .sName = sName then return N
      end with
   next N
   return ErrInfo(ecNotFound)
end function
function FindModelIndex( sPart as string ) as long
   'g_sFilenames '/255{Index}/0'Name'/0'
   var iPos = instr(g_sFilenames,"\"+lcase(sPart)+".dat")-1
   if iPos<0 then return ErrInfo(ecNotFound)   
   do 
      iPos -= 1
      if g_sFilenames[iPos]=0 then exit do
   loop
   return *cptr(long ptr,@g_sFilenames[iPos-4])
end function  
function LoadPartModel( byref tPart as PartStructLS ) as long
   with tPart
      if .iModelIndex >= 0 then return ErrInfo(ecSuccess) 'already loaded
      'load model
      dim as string sModel
      if LoadFile( .sPrimative , sModel ) = 0 then return ErrInfo(ecFailedToLoad) 'part failed to load file
      var pModel = LoadModel( strptr(sModel) , .sPrimative )                      
      if pModel=0 then return ErrInfo(ecFailedToParse)                      'part failed to parse
      .iModelIndex = pModel->iModelIndex : .sPrimative = ""
      'generate snap if not generated yet
      'var pModel = g_tModels(.iModelIndex).pModel
      if pModel->pData = 0 then   
         pModel->pData = new PartSnap
         var pSnap = cptr(PartSnap ptr,pModel->pData)
         SnapModel( pModel , *pSnap )
      end if
   end with
   return ErrInfo(ecSuccess)
end function
   
function AddPartName( sName as string , sPart as string ) as long   
         
   'skip '0 prefix (as no part name start with a '0')
   'var bPartPrefix =  (sPart[0]=asc("0"))
   'if bPartPrefix then with *Cast_fbStr(sPart) : .pzData += 1 : .iLen -= 1 : end with
   
   var iIndex = FindModelIndex( sPart )
   with g_tPart( g_iPartCount )
      .sName      = sName
      .sPrimative = sPart+".dat"
      .iModelIndex = -1 : .iColor = -1
      
      if iIndex < 0 then         
         'if bPartPrefix then with *Cast_fbStr(sPart) : .pzData -= 1 : .iLen += 1 : end with
         .bFoundPart = FindFile(.sPrimative)<>0 'part name not found
      else
         .bFoundPart = true 'part found previously
         .iModelIndex = iIndex
         'if bPartPrefix then with *Cast_fbStr(sPart) : .pzData -= 1 : .iLen += 1 : end with   
      end if
         
   end with
   
   g_iPartCount += 1
   return g_iPartCount-1
   
end function
'TODO implement this function
function AddConnection( iFrom as long , iFromType as long , iFromNum as long , iTo as long , iToType as long , iToNum as long) as long
   return 0
end function

function SafeText( sInput as string ) as string
   dim as string sResult
   for N as long = 0 to len(sInput)-1
      select case sInput[N]      
      case 0 to 31,128 to 255 : sResult += "%"+hex(sInput[N],2)
      case else
         sResult += chr(sInput[N])
      end select
   next N
   return sResult
end function      

'TODO: now check the remainder tokens, clutch/studs

function LegoScriptToLDraw( sScript as string ) as string
   
   '<PartCode> <PartName> <PartPosition> =
   '<PartName> <PartPosition> =
   
   'split tokens
   dim as string sStatement, sToken(15), sResult
   dim as long iStStart=1,iStNext
   while 1
      'get next statement
      iStNext = instr(iStStart,sScript,";")
      var pzFb = cptr(fbStr ptr,@sStatement)
      with *pzFb
         .pzData = cptr(ubyte ptr,strptr(sScript))+iStStart-1
         .iLen = iif(iStNext,iStNext,1+len(sScript))-(iStStart)         
         while .iLen>0 andalso (g_bSeparators(.pzData[0]) and stToken)
            .pzData += 1 : .iLen -= 1
         wend
         while .iLen>0 andalso (g_bSeparators(.pzData[.iLen-1]) and stToken)
            .iLen -= 1
         wend
         if .iLen=0 then 
            if iStNext=0 then exit while
            iStStart = iStNext+1 : continue while
         end if
      end with
      dim as long iTokStart=0,iTokNext,iTokCnt=0,iTokEnd=len(sStatement)
      'split tokens
      'print "["+sStatement+"]"
      var pzStatement = cptr(ubyte ptr,strptr(sStatement))            
      do
         with *cptr(fbStr ptr,@sToken(iTokCnt))
            .pzData = pzStatement+iTokStart
            while (g_bSeparators(.pzData[0]) and stToken)
               if .pzData[0]=0 then exit do
               .pzData += 1 : iTokStart += 1
               if iTokStart >= iTokEnd then exit do
            wend                        
            if (g_bSeparators(.pzData[0]) and (not stToken)) then
               .iLen = 1 : iTokStart += 1
            else
               .iLen = 0
               while g_bSeparators(.pzData[.iLen])=0
                  if iTokStart >= iTokEnd then exit while
                  .iLen += 1 : iTokStart += 1
               wend
            end if
            if .iLen <= 0 then exit do
            .iSize = .iLen : iTokCnt += 1 
         end with         
      loop
                  
      for N as long = 0 to iTokCnt-1
         print "{"+SafeText(sToken(N))+"}";
      next N
      print
      
      dim as long iCurToken=0 , iLeft=ecNotFound , iRight=ecNotFound      
      do          
         #define ParserError( _text ) color 12:print "Error: ";SafeText(_text);" at '";SafeText(sStatement);"'" : sResult="" : color 7: exit while
         #define ParserWarning( _text ) color 14:print "Warning: ";SafeText(_text);" at '";SafeText(sStatement);"'":color 7
         #define sRelToken(_N) sToken(iCurToken+(_N))
         #define sCurToken sToken(iCurToken)
         var iName=ecNotFound
         
         'if the first token is a primative (DAT) name then it's a declaration
         if IsPrimative( sCurToken ) then
            #define sPart sCurToken
            #define sName sRelToken(1)
            if len(sName)=0 orelse iCurToken >= iTokCnt then ParserError( "Expected part name, got end of statement" )
            if IsValidPartName( sName )=false then ParserError("'"+sName+"' is not a valid part name")
            iName = FindPartName( sName )
            if iName >= 0 then ParserError( "Name already exists" )            
            iName = AddPartName( sName , sPart  )            
            if iName >=0 andalso g_tPart(iName).bFoundPart = 0 then ParserWarning("'"+sPart+"' primative not found")
            iCurToken += 2            
         else 'otherwise it must be an existing part name
            #define sName sCurToken
            if IsValidPartName( sName )=false then ParserError("'"+sName+"' is not a valid primative or part name")
            iName = FindPartName( sName )
            if iName < 0 then ParserError( "part name not declared" )
            iCurToken += 1
         end if         
         'if there's no more parameters than it's just a part declaration
         
         'print ,iLeft , iRight , iCurToken ; iTokCnt
         if iCurToken = iTokCnt then 
            if iLeft<0 then exit do
            ParserError("missing operands in the right side")
         end if
         'otherwise it's a processed block (assignment?)
         'so read tokens to add characteristics
         
         'first for the LEFT side then for the RIGHT side
         if iLeft < 0 then iLeft = iName else iRight = iName
         if iLeft = iRight then ParserError("a part can't connect to itself")
                           
         with g_tPart(iName)
            do 
               if iCurToken = iTokCnt then                
                  if iLeft < 0 then ParserError("premature end of statement")
                  iRight = iName
                  print iLeft,iRight
                  exit do,do
               end if
               iCurToken += 1
               var sToken = sRelToken(-1)
               'parse characteristic
               select case sToken[0]
               case asc("="): 'assignment token
                  if iRight >= 0 then               
                     ParserError("expected end of statement, got '"+sToken+"'")
                  end if
                  continue do,do
               case asc("#"): 'color token #nn #RGB #RRGGBB
                  if .iColor >= 0 then ParserError("color attribute was already set for part '"+.sName+"'")
                  var iColor = ParseColor( sToken )
                  if iColor < 0 then
                     ParserError("Invalid color format '"+sToken+"'")
                  end if
                  .iColor = iColor                  
               case else
               end select
            loop
         end with
      loop
      
      if iStNext=0 then exit while else iStStart = iStNext+1      
   wend
         
   clear sToken(0),0,16*sizeof(fbStr) ': erase sToken
   clear sStatement,0,sizeof(fbStr)   ': sStatement = ""   
   
   return sResult
   
end function

dim as string sText,sScript
var sCmd = command()
if len(sCmd) then
   var f = freefile()
   if open(sCmd for binary access read as #f) then
      print "Failed to open '"+sCmd+"'"
      sleep : system
   end if
   sScript = space(lof(f))
   get #f,,sScript : close #f
else   
   print ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> in memory script <<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
   sScript = _
      "3001 B1;" _
      "B1 #2 s7 = 3001 B2 c1;    ;" _
      "B2 s7=3001 B3 c1;" _
      "B3 #3 s1 = 3001 B4 c3;" _
      "B3 #FFF s7 = 3002 B5 c3;"
end if
print LegoScriptToLDraw(sScript)

#if 0
   print AddPartName( "B3" , "30001" )
   print AddPartName( "B3" , "3001" )
   print AddPartName( "B4" , "3002" )
   print AddPartName( "B5" , "3001" )
   print FindName("B3")
   print FindName("B4")
   print FindName("B5")
   'with g_tPart( FindName("B3") )
   '   print .pModel ,
   'end with
   
   print "------------------"
   
   print g_tPart( FindName("B3") ).iModelIndex
   print g_tPart( FindName("B4") ).iModelIndex
   print g_tPart( FindName("B5") ).iModelIndex
   print FindModelIndex("3001")
#endif

'for N as long = 0 to ubound(g_tModels)       
'   print strptr(g_sFilenames)[g_tModels(N).iFilenameOffset+9]
'next N

sleep
