scope 'add separators
   var sSeparators = !"\9 \r\n/;"
   for N as long = 0 to len(sSeparators)-1
      g_bSeparators( sSeparators[N] ) or= stToken
   next N
   var sOperators  = !"="
   for N as long = 0 to len(sOperators)-1
      g_bSeparators( sOperators[N] ) or= stOperator
   next N
end scope

#define ErrInfo( _N ) (_N)

function ReadTokenNumber( sToken as string , iStart as long = 0 , bSigned as long = false , byref lError as long = 0 ) as long
   dim as long iResult, iSign = 1 
   if bSigned andalso sToken[iStart] = asc("-") then iStart += 1 : iSign = -1
   for N as long = iStart to len(sToken)-1
      select case sToken[N]
      case asc("0") to asc("9")
         iResult = iResult*10+(sToken[N]-asc("0"))
         if iResult < 0 then lError = ecNumberOverflow : return ErrInfo(ecNumberOverflow)
      case else
         lError = ecNotANumber : return ErrInfo(ecNotANumber) 
      end select
   next N
   lError = 0 : return iResult*iSign
end function
function IsTokenNumeric( sToken as string , iStart as long = 0 ) as long
   var iLen = len(sToken)-1
   if iStart <= iLen andalso sToken[iStart] = asc("-") then iStart += 1
   for N as long = iStart to iLen
      if (cuint(sToken[N])-asc("0")) > 9 then return false
   next N
   return true
end function
function IsPrimative( sToken as string ) as long   
   if len(sToken)=0 then return false
   select case sToken[0]
   '!!! To allow letters in the begin of part ID/Primative we will need to be able to do a slower or cached CHECK
   'case asc("a") to asc("z") 
   case asc("0") to asc("9"),asc("_")
      rem valid first char for primatives
   case asc("$") 'force assumption of primative
      with *cptr(fbstr ptr,@sToken)
         .pzData += 1 : .iLen -= 1
      end with      
   case else
      return false
   end select
   
   for N as long = 1 to len(sToken)-1
      select case sToken[N]
      case asc("A") to asc("Z"),asc("a") to asc("z"),asc("0") to asc("9"),asc("_"),asc("-")
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
   case asc("A") to asc("Z"),asc("_")
      rem valid initial chars for part names
   case else
      return false
   end select
   for N as long = 1 to len(sToken)-1
      select case sToken[N]
      case asc("A") to asc("Z"),asc("a") to asc("z")
         rem valid chars for part names
      case asc("0") to asc("9"),asc("_"),asc("-")
         rem valid chars for part names
      case else
         return false
      end select
   next N
   return true 
end function
function IsValidIdentifierName( sToken as string ) as long   
   if len(sToken)=0 then return false
   select case sToken[0]   
   case asc("A") to asc("Z"),asc("a") to asc("z"),asc("_")
      rem valid initial chars for identifier names
   case else
      return false
   end select
   for N as long = 1 to len(sToken)-1
      select case sToken[N]
      case asc("A") to asc("Z"),asc("a") to asc("z")
         rem valid chars for identifier names
      case asc("0") to asc("9"),asc("_")
         rem valid chars for identifier names
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
      if uColor > g_MaxColor then return ErrInfo(ecFailedToParse)
   next N
   return uColor
end function

function FindPartName( sName as string ) as long
   if len(sName) < 1 then return ErrInfo(ecNotFound)
   for N as long = 1 to g_iPartCount-1
      with g_tPart(N)
        puts(.sName)
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
         pModel->pData = MyAllocData(sizeof(PartSnap))
         var pSnap = cptr(PartSnap ptr,pModel->pData)
         SnapModel( pModel , *pSnap )         
         SortSnap( *pSnap )
         #if 1 'snap debug            
            with *pSnap
              printf(!"Studs=%i Clutchs=%i Axles=%i Axlehs=%i Bars=%i Barhs=%i Pins=%i Pinhs=%i\n", _            
              .lStudCnt , .lClutchCnt , .lAxleCnt , .lAxleHoleCnt ,.lBarCnt , .lBarHoleCnt , .lPinCnt , .lPinHoleCnt )
              if .lStudCnt andalso .pStud then
                puts("---------- stud ----------")
                for N as long = 0 to .lStudCnt-1
                  with .pStud[N]
                    printf(!"#%i %g %g %g\n",N+1,.tPos.X,.tPos.Y,.tPos.Z)
                  end with
                next N
              end if
              if .lClutchCnt andalso .pClutch then
                puts("--------- clutch ---------")
                for N as long = 0 to .lClutchCnt-1
                  with .pClutch[N]
                    printf(!"#%i %g %g %g\n",N+1,.tPos.X,.tPos.Y,.tPos.Z)
                  end with
                next N
              end if
              if .lAxleCnt andalso .pAxle then
                puts("--------- axle ---------")
                for N as long = 0 to .lAxleCnt-1
                  with .pAxle[N]
                    printf(!"#%i %g %g %g\n",N+1,.tPos.X,.tPos.Y,.tPos.Z)
                  end with
                next N
              end if
              if .lAxleHoleCnt andalso .pAxleHole then
                puts("------- axlehole -------")
                for N as long = 0 to .lAxleHoleCnt-1
                  with .pAxleHole[N]
                    printf(!"#%i %g %g %g\n",N+1,.tPos.X,.tPos.Y,.tPos.Z)
                  end with
                next N
              end if
            end with
         #endif
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
   memset( @g_tPart( g_iPartCount ) , 0 , sizeof(PartStructLS) )
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
   g_tPart( tConn.iLeftPart ).bConnected = 1
   g_tPart( tConn.iRightPart ).bConnected = 1
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
function GetFilePath( In_sFullPath as string ) as string
   'puts(In_sFullPath)
   var iPosi = InstrRev( In_sFullPath , "\" ), iPosi2 = InstrRev( In_sFullPath , "/" )
   if iPosi2 > iPosi then iPosi = iPosi2
   return left( In_sFullPath , iPosi )
end function
sub sCanonicalizeFilePath( InOut_sFullPath as string , IN_sCurPath as string = "" )         
   dim as string sCurPath
   if len(IN_sCurPath)=0 then sCurPath=curdir() else sCurPath=IN_sCurPath
   var iLen = len(sCurPath)
   if sCurPath[iLen-1] <> asc("\") andalso sCurPath[iLen-1] <> asc("/") then sCurPath += "\"
   InOut_sFullPath = trim(InOut_sFullPath) 
   iLen = len(InOut_sFullPath) : if iLen=0 then exit sub
   for N as long = 0 to iLen-1
      if InOut_sFullPath[N] = asc("/") then InOut_sFullPath[N] = asc("\")
   next N
   if InOut_sFullPath[0] = asc("\") orelse (iLen>1) andalso InOut_sFullPath[1] = asc(":") then exit sub
   InOut_sFullPath = sCurPath + InOut_sFullPath
end sub
sub sGetFilename( In_sFullPath as string , Out_sFilename as string )
   var iPosi = InstrRev( In_sFullPath , "\" ), iPosi2 = InstrRev( In_sFullPath , "/" )
   if iPosi2 > iPosi then iPosi = iPosi2
   Out_sFilename = mid( In_sFullPath , iPosi+1 )
end sub
sub sToUpper( sText as string )
   for N as long = 0 to len(sText)-1
      sText[N] = toupper(sText[N])
   next N
end sub
function LoadScriptFile( sFile as string , sOutString as string ) as boolean
   var f = freefile(), iResu = open(sFile for binary access read as #f)
   if iResu orelse (lof(f) > (64*1024*1024)) then
      if iResu=0 then close(f) 
      return false
   end if   
   dim as string sData = space(lof(f))
   sOutString = space(lof(f)*3)   
   get #f,,sData : close #f
      
   dim as long iOut=0, iLen = len(sData)
   for iN as long = 0 to iLen-1
      dim as ubyte iChar = sData[iN]
      select case iChar
      case asc(";") 'implicit EOL
         'if there's comments or EOL in the line continuation then keep as is
         var iT = iN         
         do
            iT += 1
            select case sData[iT]
            case asc(" "),9 : continue do
            case 13,10      : iT = -1
            case asc("/")   : if sData[iT+1] = asc("/") then iT = -1 
            end select
            exit do
         loop  
         'if there's another statement put it over next line
         if iT <> -1 then            
            sOutString[iOut] = iChar : iOut += 1            
            do
               iN += 1 : if iN >= iLen then exit for
               iChar = sData[iN]
               select case iChar
               case 13,9,asc(" "),asc(";") 'ignore blanks
                  rem ignore blanks
               case 10
                  sOutString[iOut] = 13 : iChar = 10: iOut += 1 : exit do            
               case else
                  sOutString[iOut] = 13 : sOutString[iOut+1] = 10: iOut += 2 : exit do
               end select
            loop
         end if
      case 13 : continue for
      case 10 : sOutString[iOut] = 13 : iOut += 1
      end select
      sOutString[iOut] = iChar : iOut += 1
   next iN   
   sOutString = left(sOutString,iOut)
   return true
end function

type lsString
   pzData as ubyte ptr
   uLen   as ulong
   union
      uSize as ulong
      type
         uLine:21 as ulong
         uFile:11 as ulong
      end type
   end union
end type

static shared g_tDefineList as TreeNode
sub LS_InitDefineList( tDefineList as TreeNode )   
   var pDefineList = @tDefineList
   if tDefineList.iCount = 0 then
      #define AddColorDefine( _Name , _Code , Unused... ) AddEntry( pDefineList , "#" #_Name , "#" #_Code , true )
      ForEachColor( AddColorDefine )
      for I as long = 0 to ubound( g_psColourNames )
        if g_psColourNames(I) then AddEntry( pDefineList , "#"+*g_psColourNames(I) , "#" & I , true )
      next I      
   end if
end sub

'??? if there's a missing ; then the output statement is one char short ???
function LS_GetNextStatement( sScript as string , iStStart as long , Out_sStatement as string , byref InOut_iLineNumber as long ) as long
   
   'printf( !"%i of %i '%s'\n",iStStart,len(sScript),iif(iStStart<len(sScript),strptr(sScript)+iStStart-1,NULL) )
   
   if iStStart > len(sScript) then 
      with *cptr(fbStr ptr,@Out_sStatement)
         .pzData = NULL : .iLen = 0 : .iSize = 0
      end with
      return 0
   end if
   dim as long iStNext = instr(iStStart,sScript,";"), bNoEOS = 0
   if iStNext=0 then iStNext = len(sScript)+1 : bNoEOS = 1
   var pzFb = cptr(fbStr ptr,@Out_sStatement)
   dim as byte bPreSkipTillCondition = 0
   with *pzFb
      .pzData = cptr(ubyte ptr,strptr(sScript))+iStStart-1
      .iLen = iStNext-iStStart : iStNext += 1-bNoEOS
      while .iLen>0 andalso (bPreSkipTillCondition orelse (g_bSeparators(.pzData[0]) and stToken))
         select case .pzData[0] 'special chars
         'case 0 : exit while
         case asc("*")
            if .pzData[1] = asc("/") then bPreSkipTillCondition and= (not 2)
         case asc("/")
            if .pzData[1] = asc("*") then bPreSkipTillCondition or= 2
            if .pzData[1] = asc("/") then bPreSkipTillCondition or= 1
         case asc(!"\n")
            InOut_iLineNumber += 1 : bPreSkipTillCondition and= (not 1)
         case asc(!"\r")
            if .pzData[1]=asc(!"\n") then 
               .pzData += 1 : .iLen -= 1 : iStStart += 1 
               InOut_iLineNumber += 1 : bPreSkipTillCondition and= (not 1)
            end if
         end select
         .pzData += 1 : .iLen -= 1 : iStStart += 1
      wend      
      
      'preprocessor ends at line end not at ;
      var bIsPreProcessor = .iLen>0 andalso .pzData[0] = asc("#")
      if bIsPreProcessor then
         iStNext = instr(iStStart,sScript,!"\n")
         if iStNext=0 then iStNext = len(sScript)+1
         if iStNext > 1 andalso sScript[iStNext-2]=asc(!"\r") then iStNext -= 1
         .iLen = iStNext-iStStart : bNoEOS = 1
      end if
         
      while .iLen>0 andalso (g_bSeparators(.pzData[.iLen-1]) and stToken)
         select case .pzData[.iLen-1] 'special chars
         'case 0 : exit while
         case asc("/") : exit while
         case asc(!"\n") : InOut_iLineNumber += 1 
         case asc(!"\r"): if .pzData[.iLen]=asc(!"\n") then .iLen -= 1 : InOut_iLineNumber += 1
         end select
         .iLen -= 1
      wend
      
      '.iLen += bNoEOS
         
      if .iLen=0 then 
         if iStNext>len(sScript) then iStNext=0
         'Out_sStatement = ""
         with *cptr(fbStr ptr,@Out_sStatement)
            .pzData = NULL : .iLen = 0 : .iSize = 0
         end with
      end if
   end with
   return iStNext
end function
function LS_SplitTokens( sStatement as string , Out_sToken() as string , iFileNumber as long , pDefDictionary as TreeNode ptr = 0 ,  byref InOut_iLineNumber as long = 0 , byref Out_iErrToken as long = 0 ) as long
   dim as long iTokStart=0,iTokCnt=0,iTokEnd=len(sStatement),iRecursion=0
   'split tokens
   'print "["+sStatement+"]"
   if len(sStatement)=0 then return 0 'no tokens
   static as zstring*1024 zModifiedStatement
   var pzStatement = cptr(ubyte ptr,strptr(sStatement)), bModified = false   
   Out_iErrToken = 0   
   var iOrgLine = InOut_iLineNumber
   do      
      iRecursion += 1
      #define iCurToken iTokCnt-1
      if iRecursion > 1000 then Out_iErrToken = not iTokCnt : exit do
      if iTokCnt > ubound(Out_sToken) then Out_iErrToken = iCurToken : exit do
      with *cptr(lsString ptr,@Out_sToken(iTokCnt))         
         .uFile = iFileNumber
         .pzData = pzStatement+iTokStart         
         'skipping start of next token till a "non token separator" is found
         while (g_bSeparators(.pzData[0]) and stToken)
            if .pzData[0]=0 then exit do
            .pzData += 1 : iTokStart += 1               
            select case .pzData[-1] 'special characters
            case asc(!"\n") 'new line (LF)
               InOut_iLineNumber += 1
            case asc(!"\r")   'new line (CRLF)
               if .pzData[0]=asc(!"\n") then .pzData += 1 : iTokStart += 1 : InOut_iLineNumber += 1
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
            if iTokStart >= iTokEnd then .uLine = InOut_iLineNumber : exit do
         wend         
         'locating end/size of current token
         ''print .pzData[0],chr(.pzData[0])
         if (g_bSeparators(.pzData[0]) and (not stToken)) then
            .uLen = 1 : iTokStart += 1
         else
            .uLen = 0
            var bQuotes = 0
            while bQuotes orelse g_bSeparators(.pzData[.uLen])=0
               if .pzData[.uLen]=asc("""") then bQuotes xor= 1
               if iTokStart >= iTokEnd then exit while
               .uLen += 1 : iTokStart += 1
            wend
         end if         
                           
         .uLine = InOut_iLineNumber
         if .uLen <= 0 then exit do
         
         'locate defines and replace if needed
         if pDefDictionary andalso (iTokCnt=0 orelse Out_SToken(0)[0]<>asc("#")) then            
            var pzResu = FindEntry( pDefDictionary , Out_sToken(iTokCnt) )
            if pzResu then 
               'printf("*")
               if bModified = false then 
                  bModified = true : zModifiedStatement = _
                  left(sStatement,iTokStart-.uLen)+*pzResu+mid(sStatement,iTokStart+1)
               else
                  zModifiedStatement = _
                  left(zModifiedStatement,iTokStart-.uLen)+*pzResu+mid(zModifiedStatement,iTokStart+1)
               end if
               pzStatement = cptr(ubyte ptr,strptr(zModifiedStatement))
               iTokEnd = len(zModifiedStatement)
               iTokStart -= .uLen : InOut_iLineNumber = iOrgLine: continue do
            end if
         end if
         'puts( "'" & Out_sToken(iTokCnt) & "'" )
         iOrgLine = InOut_iLineNumber
         iTokCnt += 1 : iRecursion = 0
      end with      
   loop   
   return iTokCnt
end function
