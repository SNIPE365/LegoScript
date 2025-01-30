#cmdline "-exx"

#include once "windows.bi"
#include once "fbgfx.bi"

#define __Main
#define __NoRender

#define GiveUp(_N) end _N

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
   ecNumberOverflow
   ecNotANumber
   ecAlreadyExist
   ecSuccess        = 0
end enum
type PartStructLS
   tLocation   as SnapPV   'Position/Direction (Model.bas)
   sName       as string   'name of the part "B1" , "P1", etc..
   sPrimative  as string   '.dat model path for part
   iColor      as long
   iModelIndex as long     'g_tModels(Index) (LoadrLDR.bas) (ModelList at Structs.bas)
   bPartCat    as byte     'enum PartCathegory
   bFoundPart  as byte
end type
type PartConnLS
   iLeftPart  as long    'g_tPart(index)
   iRightPart as long    'g_tPart(index)
   iLeftNum   as short
   iRightNum  as short
   iLeftType  as byte
   iRightType as byte
   bResv(1)   as byte    'padding
end type

const _cPartMin=255 , _cConnMin=255
static shared as byte g_bSeparators(255)
redim shared as PartStructLS g_tPart(_cPartMin)
redim shared as PartConnLS   g_tConn(_cConnMin)
static shared as long g_iPartCount , g_iConnCount = 0

scope 'add separators
   var sSeparators = !"\9 \r\n/"
   for N as long = 0 to len(sSeparators)-1
      g_bSeparators( sSeparators[N] ) or= stToken
   next N
   var sOperators  = !"="
   for N as long = 0 to len(sOperators)-1
      g_bSeparators( sOperators[N] ) or= stOperator
   next N
end scope

#define ErrInfo( _N ) (_N)

function ReadTokenNumber( sToken as string , iStart as long = 0 ) as long
   dim as long iResult
   for N as long = iStart to len(sToken)-1
      select case sToken[N]
      case asc("0") to asc("9")
         iResult = iResult*10+(sToken[N]-asc("0"))
         if iResult < 0 then return ErrInfo(ecNumberOverflow)
      case else
         return ErrInfo(ecNotANumber)
      end select
   next N
   return iResult
end function
function IsTokenNumeric( sToken as string , iStart as long = 0 ) as long
   for N as long = iStart to len(sToken)-1
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
      if LoadFile( .sPrimative , sModel ) = 0 then 'LoadLDR::LoadFile
         return ErrInfo(ecFailedToLoad) 'part failed to load file
      end if
      var pModel = LoadModel( strptr(sModel) , .sPrimative ) 'LoadLDR::LoadModel
      if pModel=0 then return ErrInfo(ecFailedToParse)                      'part failed to parse
      .iModelIndex = pModel->iModelIndex             
      .sPrimative = mid(.sPrimative,instrrev(.sPrimative,"\")+1)      
      'generate snap if not generated yet
      'var pModel = g_tModels(.iModelIndex).pModel
      if pModel->pData = 0 then   
         pModel->pData = new PartSnap
         var pSnap = cptr(PartSnap ptr,pModel->pData)
         SnapModel( pModel , *pSnap )         
      end if
      'calculate model size
      'SizeModel( pModel , .tSize ) 'Model::SizeModel
      'deteact part cathegory
      .bPartCat = DetectPartCathegory( pModel ) 'Model::DetectPartCathegory
   end with
   return ErrInfo(ecSuccess)
end function
function AddPartName( sName as string , sPart as string ) as long   
         
   'skip '0 prefix (as no part name start with a '0')
   'var bPartPrefix =  (sPart[0]=asc("0"))
   'if bPartPrefix then with *Cast_fbStr(sPart) : .pzData += 1 : .iLen -= 1 : end with
   if (g_iPartCount > ubound(g_tPart)) then
      redim preserve g_tPart( ubound(g_tPart)+_cPartMin+1 )
   end if
   
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
function AddConnection( byref tConn as PartConnLS ) as long
   if (g_iConnCount > ubound(g_tConn)) then
      redim preserve g_tConn( ubound(g_tConn)+_cConnMin+1 )
   end if
   g_tConn( g_iConnCount ) = tConn : g_iConnCount += 1
   return g_iConnCount-1
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
   dim as long iStStart=1,iStNext,iLineNumber=1,iTokenLineNumber=1
   
   #define TokenLineNumber(_N) (cptr(fbStr ptr,@sToken(_N))->iSize)
   #define ParserError( _text ) color 12:print "Error: ";SafeText(_text);" at line";TokenLineNumber(iCurToken);" '";SafeText(sStatement);"'" : sResult="" : color 7: exit while
   #define ParserWarning( _text ) color 14:print "Warning: ";SafeText(_text);" at line";TokenLineNumber(iCurToken);" '";SafeText(sStatement);"'":color 7
   
   while 1
      'get next statement
      iStNext = instr(iStStart,sScript,";")
      var pzFb = cptr(fbStr ptr,@sStatement)
      with *pzFb
         .pzData = cptr(ubyte ptr,strptr(sScript))+iStStart-1
         .iLen = iif(iStNext,iStNext,1+len(sScript))-(iStStart)         
         while .iLen>0 andalso (g_bSeparators(.pzData[0]) and stToken)
            select case .pzData[0] 'special chars
            case asc("/"): exit while
            case asc(!"\n"): iLineNumber += 1
            case asc(!"\r"): if .pzData[1]=asc(!"\n") then .pzData += 1 : .iLen -= 1 : iLineNumber += 1
            end select
            .pzData += 1 : .iLen -= 1
         wend
         while .iLen>0 andalso (g_bSeparators(.pzData[.iLen-1]) and stToken)
            select case .pzData[.iLen-1] 'special chars
            case asc("/") : exit while
            case asc(!"\n"): iLineNumber += 1
            case asc(!"\r"): if .pzData[.iLen]=asc(!"\n") then .iLen -= 1 : iLineNumber += 1
            end select
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
         #define iCurToken iTokCnt-1
         if iTokCnt > ubound(sToken) then ParserError("Too many tokens")            
         with *cptr(fbStr ptr,@sToken(iTokCnt))
            .pzData = pzStatement+iTokStart
            'skipping start of next token till a "non token separator" is found
            while (g_bSeparators(.pzData[0]) and stToken)
               if .pzData[0]=0 then exit do
               .pzData += 1 : iTokStart += 1
               select case .pzData[-1] 'special characters
               case asc(!"\n")   'new line (LF)
                  iLineNumber += 1
               case asc(!"\r")   'new line (CRLF)
                  if .pzData[0]=asc(!"\n") then .pzData += 1 : iTokStart += 1 : iLineNumber += 1
               case asc("/")    'escaping (commenting?)
                  if .pzData[0]=asc("/") then     'comment till EOL
                     while iTokStart < iTokEnd andalso .pzData[0]<>asc(!"\r") andalso .pzData[0]<>asc(!"\n")
                        .pzData += 1 : iTokStart += 1
                     wend
                  elseif .pzData[0]=asc("*") then 'comment till *\
                     .pzData += 1 : iTokStart += 1
                     while iTokStart < iTokEnd andalso .pzData[0]
                        .pzData += 1 : iTokStart += 1
                        if .pzData[-1]=asc("*") andalso .pzData[0]=asc("/") then
                           .pzData += 1 : iTokStart += 1 : exit while
                        end if
                     wend
                  end if
               end select
               if iTokStart >= iTokEnd then exit do
            wend 
            'locating end/size of current token
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
            .iSize = iLineNumber : iTokCnt += 1 
         end with         
      loop
            
      iStStart = iStNext+1
      if iTokCnt=0 then if iStNext=0 then exit while else continue while
      
      'Display Tokens
      for N as long = 0 to iTokCnt-1
         if iTokenLineNumber <> TokenLineNumber(N) then 
            print : iTokenLineNumber = TokenLineNumber(N)
         end if         
         print "{"+SafeText(sToken(N))+"}";
      next N
      print
      
      'Parse Tokens
      dim as long iCurToken=0
      dim as PartConnLS tConn 'expects 0's
      tConn.iLeftPart = ecNotFound : tConn.iRightPart = ecNotFound
      
      #define tLeft(_N)  tConn.iLeft##_N
      #define tRight(_N) tConn.iRight##_N
  
      do 
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
         
         'print ,tLeft(Part) , tRight(Part) , iCurToken ; iTokCnt
         if iCurToken = iTokCnt then 
            if tLeft(Part)<0 then exit do
            ParserError("missing operands in the right side")
         end if
         'otherwise it's a processed block (assignment?)
         'so read tokens to add characteristics
         
         'first for the LEFT side then for the RIGHT side
         if tLeft(Part) < 0 then tLeft(Part) = iName else tRight(Part) = iName
         if tLeft(Part) = tRight(Part) then ParserError("a part can't connect to itself")
                           
         with g_tPart(iName)
            do 
               if iCurToken = iTokCnt then                
                  if tLeft(Part) < 0 then ParserError("premature end of statement")                  
                  exit do,do
               end if
               iCurToken += 1
               var sThisToken = sRelToken(-1)
               'parse characteristic
               select case sThisToken[0]
               case asc("s"),asc("c"): 'stud/clutch (connector)   (last token from the side)
                  #define curPart g_tPart(iName)
                  #define sFullName "'"+curPart.sName+"("+curPart.sPrimative+")'"
                  if tRight(Part) < 0 then
                     if tRight(Type) then ParserError("Expected '=', got '"+sThisToken+"'")
                  else
                     if tRight(Type) then ParserError("Expected end of statement, got '"+sThisToken+"'")
                  end if
                  var iConn = ReadTokenNumber(sThisToken,1)                  
                  if iConn <= 0 then ParserError("invalid connector number")                  
                  if LoadPartModel( g_tPart(iName) ) < 0 then ParserError("failed to load model")
                  var pModel = g_tModels(curPart.iModelIndex).pModel 
                  var pSnap = cptr(PartSnap ptr,pModel->pData)
                  
                  with *pSnap
                     select case sThisToken[0]
                     case asc("s")                        
                        if iConn > .lStudCnt then ParserError("part "+sFullName+" only have " & .lStudCnt   & " studs.")
                        if tRight(Part) < 0 then tLeft(Type)=spStud : tLeft(Num)=iConn else tRight(Type)=spStud : tRight(Num)=iConn
                     case asc("c")
                        if iConn > .lClutchCnt then ParserError("part "+sFullName+" only have " & .lClutchCnt & " clutches.")
                        if tRight(Part) < 0 then tLeft(Type)=spClutch : tLeft(Num)=iConn else tRight(Type)=spClutch : tRight(Num)=iConn
                     end select
                     'printf(!"Studs=%i Clutchs=%i Aliases=%i Axles=%i Axlehs=%i Bars=%i Barhs=%i Pins=%i Pinhs=%i\n", _
                     '.lStudCnt , .lClutchCnt , .lAliasCnt , .lAxleCnt , .lAxleHoleCnt ,.lBarCnt , .lBarHoleCnt , .lPinCnt , .lPinHoleCnt )
                  end with
                  if tLeft(Type) = tRight(Type) then ParserError("same type of connector")
                     
               case asc("="): 'assignment token
                  if tRight(Part) >= 0 then               
                     ParserError("expected end of statement, got '"+sThisToken+"'")
                  end if
                  continue do,do
               case asc("#"): 'color token #nn #RGB #RRGGBB
                  if .iColor >= 0 then ParserError("color attribute was already set for part '"+.sName+"'")
                  var iColor = ParseColor( sThisToken )
                  if iColor < 0 then
                     ParserError("Invalid color format '"+sThisToken+"'")
                  end if
                  .iColor = iColor                  
               case else
                  ParserError("Unknown token '"+sThisToken+"'")
               end select
            loop
         end with
      loop
      
      AddConnection( tConn )
      
      if iStNext=0 then exit while      
   wend   
   if iStNext=0 andalso g_iPartCount>0 then      
      dim as zstring*256 zTemp=any
      dim as SnapPV ptr pLeft=any,pRight=any
      with g_tPart(0)
         'print .sName , .sPrimative , .iColor
         var iColor = iif( .iColor<0 , 16 , .iColor )
         sprintf(zTemp,!"1 %i %f %f %f 1 0 0 0 1 0 0 0 1 %s\n",iColor,.tLocation.fPX,.tLocation.fPY,.tLocation.fPZ,.sPrimative)
         sResult += zTemp : printf("%s",zTemp)
      end with
        
      for I as long = 0 to g_iConnCount-1
         with g_tConn(I)
            'print _
            '   .iLeftPart  & "{" & .iLeftType  & ":" & .iLeftNum  & "} = " & _
            '   .iRightPart & "{" & .iRightType & ":" & .iRightNum & "}"
            'dim as single FromX,FromY,FromZ , ToX,ToY,ToZ
            var pModel = g_tModels(g_tPart(.iLeftPart).iModelIndex).pModel 
            var pSnap = cptr(PartSnap ptr,pModel->pData)            
            select case .iLeftType
            case spStud   : pLeft = pSnap->pStud  +.iLeftNum-1
            case spClutch : pLeft = pSnap->pClutch+.iLeftNum-1
            case else     : print "Error"
            end select
            pModel = g_tModels(g_tPart(.iRightPart).iModelIndex).pModel 
            pSnap = cptr(PartSnap ptr,pModel->pData)
            select case .iRightType
            case spStud   : pRight = pSnap->pStud  +.iRightNum-1
            case spClutch : pRight = pSnap->pClutch+.iRightNum-1
            case else     : print "Error"
            end select
            'print pLeft->fPX , pLeft->fPY , pLeft->fPZ
            'print pRight->fPX , pRight->fPY , pRight->fPZ
            'type SnapPV
            '   as single fPX,fPY,fPZ 'position
            '   as single fVX,fVy,fVZ 'direction vector
            'end type
            var ptLocation = @g_tPart(.iLeftPart).tLocation
            dim as single fPX = ptLocation->fPX - (pLeft->fPX + pRight->fPX)
            dim as single fPY = ptLocation->fPY + (pLeft->fPY - pRight->fPY)
            dim as single fPZ = ptLocation->fPZ + pLeft->fPZ + pRight->fPZ
            var iRightPart_ = .iRightPart
            with g_tPart(iRightPart_)
               if .tLocation.fPX = 0 andalso .tLocation.fPY=0 andalso .tLocation.fPZ=0 then
                  .tLocation.fPX = fPX : .tLocation.fPY = fPY : .tLocation.fPZ = fPZ
               elseif abs(.tLocation.fPX-fPX)>.001 orelse abs(.tLocation.fPY-fPY)>.001 orelse abs(.tLocation.fPZ-fPZ)>.001 then
                  color 12 : print "Impossible Connection detected!" : color 7
               end if
               dim as PartSize tPart = any  : tPart = pModel->tSize
               tPart.xMin += .tLocation.fPX : tPart.xMax += .tLocation.fPX
               tPart.yMin =1+.tLocation.fPY : tPart.yMax += .tLocation.fPY
               tPart.zMin =1+.tLocation.fPZ : tPart.zMax += .tLocation.fPZ
               for N as long = 0 to g_iPartCount-1
                  if N = iRightPart_ then continue for
                  if .tLocation.fPX = 0 andalso .tLocation.fPY=0 andalso .tLocation.fPZ=0 then
                     continue for
                  end if
                  with g_tPart(N)                     
                     dim as PartSize tChk = any
                     tChk = g_tModels(g_tPart(N).iModelIndex).pModel->tSize                     
                     tChk.xMin += .tLocation.fPX : tChk.xMax += .tLocation.fPX
                     tChk.yMin =1+.tLocation.fPY : tChk.yMax += .tLocation.fPY
                     tChk.zMin =1+.tLocation.fPZ : tChk.zMax += .tLocation.fPZ
                     if CheckCollision( tPart , tChk ) then
                        color 12: printf(!"Collision! between part %s and %s\n",g_tPart(iRightPart_).sName,.sName): color 7
                     end if
                  end with
               next N               
               var iColor = iif(.iColor<0,16,.iColor)
               sprintf(zTemp,!"1 %i %f %f %f 1 0 0 0 1 0 0 0 1 %s\n",iColor,fPX,fPY,fPZ,.sPrimative)
               sResult += zTemp : printf("%s",zTemp)               
            end with            
            'puts("1 0 40 -24 -20 1 0 0 0 1 0 0 0 1 3001.dat")
            'puts("1 0 0 0 0 1 0 0 0 1 0 0 0 1 3001.dat")
            
         end with
      next I
   end if
         
   clear sToken(0),0,16*sizeof(fbStr) ': erase sToken
   clear sStatement,0,sizeof(fbStr)   ': sStatement = ""   
   
   return sResult
   
end function

dim as string sText,sScript
var sCmd = command(), iDump=0
if len(sCmd) then
   var f = freefile() : iDump=1
   if open(sCmd for binary access read as #f) then
      print "Failed to open '"+sCmd+"'"
      GiveUp(2)
   end if
   sScript = space(lof(f))
   get #f,,sScript : close #f
else   
   print ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> in memory script <<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
   #if 0
   sScript = _
      !"// part 3024 B1 is of type 'Plate' but was referenced as 'Brick' without a cast.\r\n;" _
      !"3001 /*Comment*/ B1;" _
      !"B1 #2 s7 = 3001 B2 c1;    ;" _
      !"B2 s7=3001 B3 c1;" _
      !"B3 #3 s1 = 3001 B4 c3;" _
      !"B3 s8 = 3002 B5 c3;"
   #endif
   sScript = _
     !"3865 BP10 #7 s69 = 3002 B1 c1;" _
     !"B1 s1 = 3002 B2 #2 c5;" _
     !"B2 s1 = 3002 B3 #3 c6;" _
     !"B3 c5 = 3021 B4 #4 s1;" _ '71752 '3021
     !"B4 c1 = 3002 B5 #5 s6;"    'collision
     '!"003238a P1 #2 c1 = 003238b P2 #4 s1;"
     
end if
var sModel = LegoScriptToLDraw(sScript)
if len(sModel) andalso iDump then
   var sFile = trim( sScript , any !"\r\n" )+".ldr"
   for N as long = 0 to len(sFile)-1
      select case sFile[N]
      case asc("*"),asc(""""),asc("/"),asc("\"),asc("<"),asc(">"),asc(":"),asc("|"),asc("?")
        sFile[N] = asc("-")
      case is <32 , is > 127
         sFile[N] = asc("_")
      end select
   next N
   var f = freefile()
   open sFile for output as #f
   print #f,sModel
   close #f
end if
      
if len(sModel) then
   var sParms = """"+sModel+""""
   puts("-----------------")   
   exec(exepath()+"\Loader\ViewModel.exe",sParms)
   'sleep
   puts("-----------------")
   end 0
else
   if iDump=0 then sleep
   end 255
end if

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


