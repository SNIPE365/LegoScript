#ifndef __Main
   
   #cmdline "-exx"

   #include once "windows.bi"
   #include once "fbgfx.bi"

   #define __Main "LS2LDR"
   #define __NoRender
   #define __Standalone
   #define GiveUp(_N) end _N

   #include once "Loader\PartSearch.bas"
   #include once "Loader\LoadLDR.bas"   
   #include once "Loader\Modules\Matrix.bas"
   #include once "Loader\Modules\Model.bas"   
   
   #define errorf(_Parms...) fprintf(stderr,_Parms)
   
#endif

'TODO: apply the rotation to the position vector for the stud/clutch (ongoing)
'TODO (11/02/2025): must rotate the matrix for the part based on the shadow stud/clutch not just the vector

const PI = atn(1)*4

#if 0
   var sFile = "3001.dat"
   dim as string sModel
   FindFile(sFile)
   if LoadFile( sFile , sModel ) = 0 then
      puts("Failed to load '"+sFile+"'")
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

'dbg_puts("3001 B1 #2 s7 = 3001 B2 #2 c1;")
'dbg_puts("")
'dbg_puts("3001 B1 s7 = 3001 B2 c1;")
'dbg_puts("1 0 40 -24 -20 1 0 0 0 1 0 0 0 1 3001.dat")
'dbg_puts("1 0 0 0 0 1 0 0 0 1 0 0 0 1 3001.dat")

enum SeparatorType
   stNone
   stToken    = 1
   stOperator = 2
end enum
enum ErrorCodes
   ecNotFound       = &h80000000
   ecFailedToLoad
   ecFailedToParse
   ecNumberOverflow
   ecNotANumber
   ecAlreadyExist
   ecSuccess        = 0
end enum
type PartStructLS
   tOffPos      as Vector3   'Offseted Position
   tOffRot      as Vector3   'Offseted X,Y,Z angles
   tPositionQ   as Vector3   'final position of the part
   tMatrix      as Matrix3x3 'final Part Matrix (matrix.bas)
   sName        as string    'name of the part "B1" , "P1", etc..
   sPrimative   as string    '.dat model path for part
   iColor       as long
   iModelIndex  as long      'g_tModels(Index) (LoadrLDR.bas) (ModelList at Structs.bas)
   bPartCat     as byte      'enum PartCathegory
   bFoundPart:1 as byte
   bConnected:1 as byte
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

const _cPartMin=255 , _cConnMin=255 , _NULLPARTNAME = 0
static shared as byte g_bSeparators(255)
redim shared as PartStructLS g_tPart(_cPartMin)
redim shared as PartConnLS   g_tConn(_cConnMin)
static shared as long g_iPartCount=1 , g_iConnCount = 0
static shared as SnapPV g_NullSnap
g_NullSnap.tOriMat = g_tIdentityMatrix3x3

#include "LSModules\DictionaryTree.bas"
#include once "Loader\Include\Colours.bas"
#include "LSModules\LSFunctions.bas"

'TODO: now check the remainder tokens, clutch/studs

function LegoScriptToLDraw( _sScript as string , sOutput as string = "" , sMainPath as string = "main.ldr" ) as string
   
   type FileStruct
      psFilename  as string ptr
      psFilePath  as string ptr
      psScript    as string ptr
      uLineNumber as long
      uStStart    as long
   end type
   '<PartCode> <PartName> <PartPosition> =
   '<PartName> <PartPosition> =
      
   dim as string sStatement, sToken(15), sResult
   dim as long iTokenLineNumber=1 , iCurFile = 1 , iStackPos = 0 , iFileCount = 1
   dim as byte bNullSkip = 1
   sOutput = "" : g_iPartCount = 1 : g_iConnCount = 0
   
   LS_InitDefineList( g_tDefineList )   
               
   #define iStStart aFile(iCurFile).uStStart
   #define iLineNumber aFile(iCurFile).uLineNumber
   #define sScript (*aFile(iCurFile).psScript)
         
   redim aFile(1 to 8) as FileStruct   
   redim iFileStack(15) as long
   
   iFileStack(iStackPos) = iCurFile
   dim as string sMainFile : sGetFilename( sMainPath , sMainFile )
   with aFile(iCurFile)
      .psFilename = @sMainFile
      .psFilePath = @sMainPath
      .psScript  = @_sScript
      .uStStart=1 
      .uLineNumber=1
   end with   
      
   #define TokenLineNumber(_N) (cptr(lsString ptr,@sToken(_N))->uLine)
   #define TokenFileNumber(_N) (cptr(lsString ptr,@sToken(_N))->uFile)
   #define TokenFileName(_N) (*(aFile(TokenFileNumber(_N)).psFilename))
   #define TokenFilePath(_N) (*(aFile(TokenFileNumber(_N)).psFilepath))
      
   #ifdef __Standalone      
      #define ParserError( _text ) color 12:errorf(!"Error: %s\r\nat '%s':%i '%s'\n",SafeText(_text),TokenFilename(iCurToken), TokenLineNumber(iCurToken),SafeText(sStatement)) : sResult="" : color 7: exit while
      #define ParserWarning( _text ) color 14:errorf(!"Warning: %s\r\nat '%s':%i '%s'\n",SafeText(_text),TokenFilename(iCurToken),TokenLineNumber(iCurToken),SafeText(sStatement)):color 7
      #define LinkerError( _text ) color 12 : errorf(!"Error: %s\n",_text) : sResult="" : color 7
      #define LinkerWarning( _text ) color 14 : errorf(!Warning: %s\n",_text): color 7
   #else
      #define ParserError( _text ) sOutput += !"\2\12Error: " & SafeText(_text) & !"\r\nat '" & TokenFilename(iCurToken) & "':" & TokenLineNumber(iCurToken) & " '" & SafeText(sStatement) & !"'\r\n" : sResult="" : ChangeToTabByFile( TokenFilePath(iCurTokeN) , TokenLineNumber(iCurToken ) ) : exit while
      #define ParserWarning( _text ) sOutput += !"\2\14Warning: " & SafeText(_text) & !"\r\nat '" & TokenFilename(iCurToken) & "':" &  TokenLineNumber(iCurToken) & " '" & SafeText(sStatement) & !"'\r\n"
      #define LinkerError( _text ) sOutput += !"\2\12Error: " & _text & !"\r\n" : sResult=""
      #define LinkerWarning( _text ) sOutput += !"\2\14Warning: " & _text & !"\r\n" 
   #endif
      
   with g_tPart(_NULLPARTNAME)
      .tMatrix = g_tIdentityMatrix3x3
      .bConnected = true
   end with
      
   
   'Parsing LS and generate connections
   
   #define FileDone() if iStackPos > 0 then iStackPos -= 1 : iCurFile = iFileStack(iStackPos) : DbgBuild("!! resuming at '" & *aFile(iCurFile).psFilepath & "':" & aFile(iCurFile).uLineNumber ) : aFile(iCurFile).uLineNumber -= 1 : continue while else DbgBuild("!! All files parsed"): exit while
   
   '#define DbgCrash() puts("" & __LINE__)
   #define DbgCrash()
   
   #define DbgBuild(_s) puts("" & __LINE__ & ": " & _s)
   '#define DbgBuild(_s)
   
   '#define Dbg_Printf  rem
   #define Dbg_Printf printf
   '#define Dbg_Puts rem
   #define Dbg_Puts puts
   
   
   DbgBuild(!"\r"+string(60,"-"))
   DbgBuild( "!! building '"+sMainFile+"'" )
   while 1            
      
      DbgCrash()
      
      '=======================================================================
      '======================== get next statement ===========================
      '=======================================================================
      var iStNext = LS_GetNextStatement(sScript,iStStart,sStatement,iLineNumber)
            
      DbgCrash()
      
      if iStNext=0 then FileDone()               
      if len(sStatement)=0 then iStStart = iStNext : continue while      
      DbgBuild("<" & iLineNumber & ">'"+sStatement+"'")
      
      DbgCrash()
      
      '=======================================================================
      '========================== split tokens ===============================
      '=======================================================================
      dim as long iErrToken = 0
      var iTokCnt = LS_SplitTokens( sStatement , sToken() , iCurFile , @g_tDefineList , iLineNumber , iErrToken )
      ''puts("err: " & iErrToken)
      if iErrToken < 0 then
         iErrToken = not iErrToken
         #define iCurToken iErrToken
         ParserError("Recursive define limit reached.")
      end if
      if iTokCnt > ubound(sToken) then 
         #define iCurToken iErrToken
         ParserError("Too many tokens")            
      end if
            
      DbgCrash()
      
      iStStart = iStNext+1
      if iTokCnt=0 then if iStNext=0 then FileDone() else continue while
      
      DbgCrash()
      
      '=======================================================================
      '=================== preprocessor / pragama checker ====================
      '=======================================================================
      if sStatement[0] = asc("#") then
         DbgBuild(">> Is meta statement so takes whole line")
         var iCurToken = 0
         select case lcase(sToken(0))
         case "#include"
            if iTokCnt<2 then ParserError( "Expected filename, got end of line" )
            if iTokCnt>2 then ParserError( "Expected end of line got '" & sToken(2) & "'" )            
            var iEnd = len(sToken(1)) : iCurToken = 1
            if sToken(1)[0]<>asc("""") andalso sToken(1)[0]<>asc("'") then
               ParserError( "Expected string, got end of line" )
            end if
            if iEnd < 2 orelse sToken(1)[iEnd-1] <> sToken(1)[0] then
               ParserError( "Mismatched string quotes" )
            end if
            var sFile = mid(sToken(1),2,iEnd-2) 
            sCanonicalizeFilePath( sFile , GetFilePath((*aFile(iCurFile).psFilepath))  )
            var sFileL = lcase(sFile), iLoadedFile=0
            for N as long = 1 to iFileCount
               if aFile(N).psFilepath = null then exit for
               if *aFile(N).psFilepath = sFileL then iLoadedFile = N
               for I as long = 0 to iStackPos
                  if (*aFile(iFileStack(I)).psFilepath) = sFileL then
                     ParserError( "Recursive #include" )
                  end if
               next I               
            next N
            if iLoadedFile = 0 then
               var psScript = new string               
               if LoadScriptFile( sFile , *psScript )=false then
                  puts("file not found?? '" & sFile & "'")
                  delete psScript : ParserError( "File not found" )                  
               end if               
               iFileCount += 1
               with aFile(iFileCount)
                  .psFilename = new string (sFile)
                  .psFilepath = new string (sFileL)
                  .psScript   = psScript
               end with
               iLoadedFile = iFileCount
            end if
            with aFile(iLoadedFile)
               .uStStart=1 
               .uLineNumber=1
            end with
            iStackPos += 1 : iCurFile = iLoadedFile
            iFileStack(iStackPos)=iLoadedFile
            DbgBuild(">> now processing '" & sFile & "'")
         case "#define","#redef"
            if iTokCnt=1 then ParserError( "expected #define identifier, got end of line" )
            if IsValidIdentifierName( sToken(1) )=0 then
               ParserError( "invalid characters #define identifier" )
            end if
            dim as string sDefineValue
            for N as long = 2 to iTokCnt-1
               if N=2 then sDefineValue=sToken(N) else sDefineValue += " "+sToken(N)
            next N
            var bCanOverwrite = (sToken(0)[1]=asc("r"))
            'puts( "'"+sToken(1)+"' '"+sDefineValue+"'" )
            var pzNew = AddEntry( @g_tDefineList , "" & sToken(1) , sDefineValue , , bCanOverwrite )
            'puts("new: " & pzNew & " ovr: " & bCanOverwrite)
            if pzNew = NULL then
               ParserError( "'"+sToken(1)+"' is already defined" )
            end if
         case "#pragma"
            rem
         case else            
            ParserError( "Unknown pre-processor directive" )            
         end select
         continue while
      end if
      
      DbgCrash()
      
      'Display Tokens (debug?)
      for N as long = 0 to iTokCnt-1
         if iTokenLineNumber <> TokenLineNumber(N) then
            #ifdef __Standalone
               errorf(!"\n")
            #else
               'puts("")
            #endif
            iTokenLineNumber = TokenLineNumber(N)
         end if
         #ifdef __Standalone
            errorf(!"{%s}",SafeText(sToken(N)))
         #else
            'dbg_printf("{%s}",SafeText(sToken(N)))
         #endif
      next N
      #ifdef __Standalone
         errorf(!"\n")
      #else
         'puts("")
      #endif
      
      '=======================================================================
      '============================= Parse Tokens ============================
      '=======================================================================
      dim as long iCurToken=0, lError
      dim as PartConnLS tConn 'expects 0's
      tConn.iLeftPart = ecNotFound : tConn.iRightPart = ecNotFound      
      #define tLeft(_N)  tConn.iLeft##_N
      #define tRight(_N) tConn.iRight##_N      
      
      DbgCrash()
      do 
         #define sRelToken(_N) sToken(iCurToken+(_N))
         #define sCurToken sToken(iCurToken)
         DbgBuild("{{" & sCurToken & "}}")         
         var iName=ecNotFound, bExisting = false         
         'if the first token is a primative (DAT) name then it's a declaration
         if IsPrimative( sCurToken ) then            
            #define sPart sCurToken
            #define sName sRelToken(1)
            DbgBuild(">> Token is a primative ")
            DbgBuild("{{" + sName + "}}")
            sToUpper(sName)
            if len(sName)=0 orelse iCurToken >= iTokCnt then ParserError( "Expected part name, got end of statement" )            
            if IsValidPartName( sName )=false then ParserError("'"+sName+"' is not a valid part name")
            iName = FindPartName( sName )            
            if iName >= 0 then ParserError( "Name already exists" )                        
            iName = AddPartName( sName , sPart  )
            if iName >=0 andalso g_tPart(iName).bFoundPart = 0 then 
               ParserError("'"+sPart+"' primative not found")
               'puts("bad primative?")
               exit do
            end if            
            iCurToken += 2            
            DbgBuild(">> Part name created, ID:" & iName)
         else 'otherwise it must be an existing part name            
            DbgBuild(">> Token must be an existing part name")
            #define sName sCurToken            
            sToUpper(sName)
            if sName = "NULL" then               
               iName = _NULLPARTNAME : bNullSkip = 0
            else
               if IsValidPartName( sName )=false then ParserError("'"+sName+"' is not a valid primative or part name")
               iName = FindPartName( sName )               
               if iName < 0 then ParserError( "part name not declared" )
            end if
            iCurToken += 1 : bExisting = true
            DbgBuild(">> Token is an existing part name, ID:" & iName)
         end if
         'if there's no more parameters than it's just a part declaration
         ''puts( tLeft(Part) & " , " & tRight(Part) & " , " & iCurToken & ":" & iTokCnt )
         
         if iCurToken = iTokCnt then 
            if tLeft(Part)<0 then exit do
            if iName <> _NULLPARTNAME then ParserError("missing operands in the right side")
         end if         
         rem otherwise it's a processed block (assignment?)

         rem first for the LEFT side then for the RIGHT side
                           
         if tLeft(Part) < 0 then tLeft(Part) = iName else tRight(Part) = iName
         if tLeft(Part) = tRight(Part) then ParserError("a part can't connect to itself")
         
         rem can only define rotation/offset once
         dim as byte bDefinedXRot , bDefinedYRot , bDefinedZRot
         dim as byte bDefinedXOff , bDefinedYOff , bDefinedZOff
         
         'other wise read tokens to add characteristics
         with g_tPart(iName)
            dim as byte bAttIgnored = 0
            do 
               if iCurToken = iTokCnt then                
                  if tLeft(Part) < 0 then ParserError("premature end of statement")                  
                  exit do,do
               end if
               iCurToken += 1
               var sThisToken = sRelToken(-1)               
               'parse characteristic
               if iName = _NULLPARTNAME andalso sThisToken[0] <> asc("=") then                  
                  if bAttIgnored=0 then bAttIgnored=1 : ParserWarning("NULL part attribute ignored")
                  continue do
               end if      
               if sThisToken[0] = asc("#") then 'it's an attribute modifier
                  'lowercase first two chars of the name as they can be attribute|modifier
                  if sThisToken[1] >= asc("A") andalso sThisToken[1] <= asc("Z") then
                     sThisToken[1] += 32 'lowercase
                  end if
                  if sThisToken[2] >= asc("A") andalso sThisToken[2] <= asc("Z") then
                     sThisToken[2] += 32 'lowercase
                  end if
                  
                  'if it's an hex digit then it's a color (this makes A-F unusable for attribute names)
                  if (sThisToken[1] >= asc("0") andalso sThisToken[1] <= asc("9")) orelse (sThisToken[1] >= asc("a") andalso sThisToken[1] <= asc("f")) then
                     'color token #nn #RGB #RRGGBB
                     if .bConnected then 
                        ParserError("Can't define attributes for existing parts")
                     end if
                     if .iColor >= 0 then ParserError("color attribute was already set for part '"+.sName+"'")
                     var iColor = ParseColor( sThisToken )
                     if iColor < 0 then
                        ParserError("Invalid color format '"+sThisToken+"'")
                     end if
                     .iColor = iColor
                  else 'x y z xo yo zo = attribute tokens
                     select case sThisToken[1] 'which attribute it is?
                     case asc("x"): 'X angle or position for this piece
                        if .bConnected then ParserError("Can't define attributes for existing parts (redefined X offset or rotation)")
                        select case sThisToken[2]
                        case asc("o") 
                           if bDefinedXOff then ParserError("Defined X offset twice")                                                      
                           .tOffPos.X += ReadTokenNumber( sThisToken , 3 , true , lError ) : bDefinedXOff = 1
                           if lError then ParserError("Invalid number at attribute '"+sThisToken+"'")
                        case asc("-"),asc("0") to asc("9") 'must be a number to be a rotation
                           if bDefinedXRot then ParserError("Defined X rotation twice")
                           .tOffRot.X  = ReadTokenNumber( sThisToken , 2-(sThisToken[2]=asc("r")) , true , lError )*(PI/180) : bDefinedXrot = 1
                           if lError then ParserError("Invalid number at attribute '"+sThisToken+"'")
                        case else
                           ParserError("Invalid attribute '"+sThisToken+"'")
                        end select
                     case asc("y"): 'Y angle or position for this piece
                        if .bConnected then ParserError("Can't define attributes for existing parts (redefined Y offset or rotation)")
                        select case sThisToken[2]
                        case asc("o") 'it's an offset instead of rotation
                           if bDefinedYOff then ParserError("Defined Y offset twice")
                           .tOffPos.Y += ReadTokenNumber( sThisToken , 3 , true , lError ) : bDefinedYOff = 1
                           if lError then ParserError("Invalid number at attribute '"+sThisToken+"'")
                        case asc("-"),asc("0") to asc("9") 'must be a number to be a rotation
                           if bDefinedYRot then ParserError("Defined Y rotation twice")
                           .tOffRot.Y  = ReadTokenNumber( sThisToken , 2-(sThisToken[2]=asc("r")) , true , lError )*(PI/180) : bDefinedYrot = 1                        
                           if lError then ParserError("Invalid number at attribute '"+sThisToken+"'")
                        case else
                           ParserError("Invalid attribute '"+sThisToken+"'")
                        end select
                     case asc("z"): 'Z angle or position for this piece
                        if .bConnected then ParserError("Can't define attributes for existing parts (redefined Z offset or rotation)")
                        select case sThisToken[2]
                        case asc("o") 'it's an offset instead of rotation
                           if bDefinedZOff then ParserError("Defined Z offset twice")
                           .tOffPos.Z += ReadTokenNumber( sThisToken , 3 , true , lError ) : bDefinedZOff = 1
                           if lError then ParserError("Invalid number at attribute '"+sThisToken+"'")
                        case asc("-"),asc("0") to asc("9") 'must be a number to be a rotation
                           if bDefinedZRot then ParserError("Defined Z rotation twice")
                           .tOffRot.Z  = ReadTokenNumber( sThisToken , 2-(sThisToken[2]=asc("r")) , true , lError )*(PI/180) : bDefinedZrot = 1
                           if lError then ParserError("Invalid number at attribute '"+sThisToken+"'")
                        case else
                           ParserError("Invalid attribute '"+sThisToken+"'")
                        end select
                     case else                        
                        ParserError("Invalid attribute '"+sThisToken+"'")
                     end select
                  end if
               else 'is a connector or what?
                  if sThisToken[0] >= asc("A") andalso sThisToken[0] <= asc("Z") then
                     sThisToken[0] += 32 'lowercase
                  end if
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
                     if LoadPartModel( g_tPart(iName) ) < 0 then 
                        '*CHECK* it hangs here if it fails to load?
                        ParserError("failed to load model")
                     end if                  
                     var pModel = g_tModels(curPart.iModelIndex).pModel 
                     var pSnap = cptr(PartSnap ptr,pModel->pData)                  
                     with *pSnap
                        select case sThisToken[0]
                        case asc("s")                        
                           if iConn > .lStudCnt then iConn=0: ParserWarning("part "+sFullName+" only have " & .lStudCnt   & " studs.")
                           if tRight(Part) < 0 then tLeft(Type)=spStud : tLeft(Num)=iConn else tRight(Type)=spStud : tRight(Num)=iConn
                        case asc("c")
                           if iConn > .lClutchCnt then iConn=0: ParserWarning("part "+sFullName+" only have " & .lClutchCnt & " clutches.")
                           if tRight(Part) < 0 then tLeft(Type)=spClutch : tLeft(Num)=iConn else tRight(Type)=spClutch : tRight(Num)=iConn
                        end select
                        'dbg_printf(!"Studs=%i Clutchs=%i Aliases=%i Axles=%i Axlehs=%i Bars=%i Barhs=%i Pins=%i Pinhs=%i\n", _
                        '.lStudCnt , .lClutchCnt , .lAliasCnt , .lAxleCnt , .lAxleHoleCnt ,.lBarCnt , .lBarHoleCnt , .lPinCnt , .lPinHoleCnt )
                     end with
                     if tLeft(Type) = tRight(Type) then ParserError("same type of connector")                  
                  case asc("="): 'assignment token
                     if tRight(Part) >= 0 then               
                        ParserError("expected end of statement, got '"+sThisToken+"'")
                     end if
                     continue do,do
                  case else
                     ParserError("Unknown token '"+sThisToken+"'")
                  end select
               end if
            loop
         end with            
         
      loop
      DbgCrash()
      with tConn      
         if .iLeftPart <> ecNotFound andalso .iRightPart <> ecNotFound then
            if tLeft(Part)<>_NULLPARTNAME andalso tLeft(type)=spUnknown then ParserError("left part is missing connector")
            if tRight(Part)<>_NULLPARTNAME andalso tRight(Type)=spUnknown then ParserError("right part is missing connector")
            if tLeft(Part)=_NULLPARTNAME andalso tRight(Part) = _NULLPARTNAME then ParserError("meaningless connection with both parts being NULL")
            AddConnection( tConn ) 'lsfunctions.bas
            DbgBuild(">> Added connection between parts " & tLeft(Part) & " and " & tRight(Part))
         end if
      end with
      DbgCrash()
      if iStNext=0 then exit while      
   wend   
   DbgCrash()
   
   #macro DebugParts()      
      dbg_puts("ID   sNam sPrimative  Colr Idx Ct Ok LocX LocY LocZ AngX AngY AngZ SX    1    2    4   SY    6    8    9   SZ")
      for N as long = bNullSkip to g_iPartCount-1      
         with g_tPart(N)
            var sPrim = .sPrimative , iPos = instrrev(sPrim,"\") 
            if iPos then sPrim = mid(sPrim,iPos+1)
            dbg_printf( _
               !"%-4i %-4s %-11s %4i %-3i %-2i %-2i " _
               !"%4i %4i %4i %4i %4i %4i " _
               !"%1.1f  %1.1f  %1.1f  " _
               !"%1.1f  %1.1f  %1.1f  " _
               !"%1.1f  %1.1f  %1.1f\n", _            
               N,iif(len(.sName),.sName,"NULL"), _
               iif(len(sPrim),sPrim,"None"), _
               .iColor,.iModelIndex,.bPartCat,.bFoundPart, _
               cint(.tOffPos.X),cint(.tOffPos.Y),cint(.tOffPos.Z), _
               cint(.tOffRot.X*(180/PI)),cint(.tOffRot.Y*(180/PI)),cint(.tOffRot.Z*(180/PI)), _
               (.tMatrix.fScaleX) , (.tMatrix.f_1)     , (.tMatrix.f_2)     , _
               (.tMatrix.f_3)     , (.tMatrix.fScaleY) , (.tMatrix.f_5)     , _
               (.tMatrix.f_6)     , (.tMatrix.f_7)     , (.tMatrix.fScaleZ) , _            
            )
         end with
      next N
   #endmacro      
   #if len(__FB_QUOTE__(DbgBuild))     
     dbg_puts(">>> ------------- >>>")
     DebugParts()   
     dbg_puts("<<< ------------- <<<")
   #endif
   
   'remove preprocessor entries now as they are unecessary (unless we use them for debug later)
   RemoveAllEntries( @g_tDefineList )
   
   'remove connection flags for all parts...
   for N as long = 1 to g_iPartCount-1
      g_tPart(N).bConnected = 0
   next N
   
   '=======================================================================
   '=================== generate LDRAW and check collisions ===============
   '=======================================================================
   if g_iPartCount>0 then 'iStNext=0 andalso 
      dim as zstring*256 zTemp=any
      dim as SnapPV ptr pLeftSnap,pRightSnap
      
      #define _fPX .tPositionQ.X
      #define _fPY .tPositionQ.Y
      #define _fPZ .tPositionQ.Z
      '------------------------------------------------------------------------
      '--------------- later parts are relative to some other part ------------
      '---------- so process all connections to get the relative parts --------
      '------------------------------------------------------------------------
      dim as byte bFirstConnect = true 
      dim as long iPass = 0
      
      DbgCrash()
      
      do
         iPass += 1
         DbgBuild("---- Handling connections Pass #" & iPass & " ----")
         dim as byte bDidConnect , bHaveStrayConnections 
         ''print "#","left","used","right","used"
                                 
         for I as long = 0 to g_iConnCount-1
            
            DbgCrash()
            
            with g_tConn(I)
               '----- decide what to do based on which sides are connected -----
               if g_tPart(.iLeftPart).bConnected=0 orelse g_tPart(.iRightPart).bConnected=0 then
                  DbgBuild(">> Conn: " & I & " Left: " & .iLeftPart & iif(g_tPart(.iLeftPart).bConnected,"|Locked","") & "  Right: " &  .iRightPart & iif(g_tPart(.iRightPart).bConnected,"|Locked","") )
               end if               
               if g_tPart(.iLeftPart).bConnected=false then 'if left side isnt connected
                  if g_tPart(.iRightPart).bConnected then     'and right side is connected then SWAP and connect
                     DbgBuild(">> Right part is already connected, so must swap sides")
                     swap .iLeftPart , .iRightPart : swap .iLeftType , .iRightType
                     swap .iLeftNum  , .iRightNum : I -= 1 : continue for
                  else                                        'and right side is also disconnected then check for stray                        
                     if bFirstConnect then
                        '------------------------------------------------------------------------
                        '------------------------ first part positioning ------------------------
                        '------------------------------------------------------------------------
                        with g_tPart( g_tConn(I).iLeftPart )
                           'print .sName , .sPrimative , .iColor
                           var iColor = iif( .iColor<0 , 16 , .iColor ) , psPrimative = @.sPrimative
                           .bConnected = true 'this part now have a position
                           .tMatrix = g_tIdentityMatrix3x3
                           _fPX = .tOffPos.X : _fPY = .tOffPos.Y : _fPZ = .tOffPos.Z
                           ''printf(!"~~- %f %f %f\n",_fPX,_fPY,_fPZ)
                           if .tOffRot.X then Matrix3x3RotateX( .tMatrix , .tMatrix , .tOffRot.X )
                           if .tOffRot.Y then Matrix3x3RotateY( .tMatrix , .tMatrix , .tOffRot.Y )
                           if .tOffRot.Z then Matrix3x3RotateZ( .tMatrix , .tMatrix , .tOffRot.Z )
                           var pPos = @.tPositionQ
                           with .tMatrix
                              sprintf(zTemp,!"1 %i %f %f %f %g %g %g %g %g %g %g %g %g %s\r\n",iColor,pPos->X,pPos->Y,pPos->Z, _
                                 .m(0),.m(1),.m(2),.m(3),.m(4),.m(5),.m(6),.m(7),.m(8) , *psPrimative )
                           end with
                           ''printf(!"~~+ %f %f %f\n",_fPX,_fPY,_fPZ)
                           sResult += zTemp 
                           #ifdef __Standalone
                           'errorf("(first) %s",zTemp)
                           dbg_printf("first: %s",zTemp)
                           #endif                                
                        end with
                        DbgBuild(">> This left part is a key-part")
                        'so there was a connection, but as first so it skips right to the next connection
                        bFirstConnect = false : bDidConnect = true : continue for
                     else
                        'print "[" &  I & "]"
                        bHaveStrayConnections = 1 : continue for
                     end if
                  end if
               else                                         'if left side is connected
                  if g_tPart(.iRightPart).bConnected then     'and right side is also connected then skips
                     continue for
                  else                                        'and right is not connected then do nothing
                     rem
                  end if
               end if
               
               DbgCrash()               
               'print _
               '   .iLeftPart  & "{" & .iLeftType  & ":" & .iLeftNum  & "} = " & _
               '   .iRightPart & "{" & .iRightType & ":" & .iRightNum & "}"
               'dim as single FromX,FromY,FromZ , ToX,ToY,ToZ
               
               '---- grab snap points of both parts ----
               dim pSnap as PartSnap ptr  = NULL , pModel as DATFile ptr = NULL 
               if .iLeftPart = _NULLPARTNAME then
                  pLeftSnap = @g_NullSnap
               else
                  pModel = g_tModels(g_tPart(.iLeftPart).iModelIndex).pModel 
                  pSnap = cptr(PartSnap ptr,pModel->pData)            
                  if .iLeftNum<1 then
                     pLeftSnap = @g_NullSnap
                  else                     
                     select case .iLeftType
                     case spStud   : pLeftSnap = pSnap->pStud  +.iLeftNum-1
                     case spClutch : pLeftSnap = pSnap->pClutch+.iLeftNum-1
                     case else     : puts("Error")
                     end select
                  end if
               end if
               if .iRightPart = _NULLPARTNAME then
                  pRightSnap = @g_NullSnap
               else                  
                  pModel = g_tModels(g_tPart(.iRightPart).iModelIndex).pModel 
                  pSnap = cptr(PartSnap ptr,pModel->pData)
                  if .iRightNum<1 then
                     pRightSnap = @g_NullSnap
                  else
                     select case .iRightType
                     case spStud   : pRightSnap = pSnap->pStud  +.iRightNum-1
                     case spClutch : pRightSnap = pSnap->pClutch+.iRightNum-1
                     case else     : puts("Error")
                     end select
                  end if
               end if  
               
               DbgCrash()
               
               'print pLeft->fPX , pLeft->fPY , pLeft->fPZ
               'print pRight->fPX , pRight->fPY , pRight->fPZ
               'type SnapPV
               '   as single fPX,fPY,fPZ 'position
               '   as single fVX,fVy,fVZ 'direction vector
               'end type
               
               'var ptPosition = @g_tPart(.iLeftPart).tPositionQ
               'var ptRotation = @g_tPart(.iLeftPart).tRotation
               
               var pLeftPart = @g_tPart(.iLeftPart) , iRightPart_ = .iRightPart
               g_tPart(.iRightPart).bConnected = true : bDidConnect = true
               
               DbgCrash()
               
               'pLeft/pRight are the snap matrix for the piece stud/clutch
               with g_tPart(iRightPart_)                              
                  'if memcmp( @pLeftPart->tMatrix , @g_tBlankMatrix , sizeof(Matrix4x4) ) = 0 then                        
                  '   'if memcmp( @pRightPart->tMatrix , @g_tBlankMatrix , sizeof(Matrix4x4) ) = 0 then                  
                  '      .tMatrix = g_tIdentityMatrix
                  '   'else
                  '   '   .tMatrix =pRightPart->tMatrix
                  '   'end if
                  'else
                  .tMatrix    = pLeftPart->tMatrix
                  .tPositionQ = pLeftPart->tPositionQ
                  'end if
                  
                  DbgCrash()
                  
                  'todo: FIND THE RIGHT COMBINATION for POST rotation
                                    
                  DbgCrash()
                  
                  dbg_printf(!"Left Snap <%g %g %g>\n",pLeftSnap->tPos.X,pLeftSnap->tPos.Y,pLeftSnap->tPos.Z)
                                    
                  'Vector3_AddEx(.tOffPos , 
                  var tPos = Vector3_Transform( pLeftSnap->tPos , .tMatrix )
                  if .tOffRot.X then Matrix3x3RotateX( .tMatrix , .tMatrix , .tOffRot.X )
                  if .tOffRot.Y then Matrix3x3RotateY( .tMatrix , .tMatrix , .tOffRot.Y )
                  if .tOffRot.Z then Matrix3x3RotateZ( .tMatrix , .tMatrix , .tOffRot.Z )
                  
                  MultMatrix3x3( .tMatrix , .tMatrix , pLeftSnap->tOriMat )
                  
                  Vector3_Add( .tPositionQ , tPos )
                  tPos = Vector3_Transform( .tOffPos , .tMatrix )
                  Vector3_Add( .tPositionQ , tPos )
                  
                  
                  #if 0
                     ''dbg_puts("pLeft:" & pLeft & " // pRight:" & pRight)
                     if pLeft->pMatOrg then 
                        dbg_puts("Prev rotation")
                        MultMatrix4x4( .tMatrix , .tMatrix , pLeft->pMatOrg )
                     end if
                     if pRight->pMatOrg then 
                        dbg_puts("Auto Rotating")
                        MultMatrix4x4( .tMatrix , .tMatrix , pRight->pMatOrg )
                     end if    
                  #endif                           
                                                         
                  DbgCrash()
                                                         
                  ''_fPX = pLeft->fPX : _fPY = pLeft->fPY : _fPZ = pLeft->fPZ
                  ''if pLeft->pMatOrg then MultiplyMatrixVector( @tVec3(0) , pLeft->pMatOrg )
                  ''MultiplyMatrixVector( @tVec3(0) , @pLeftPart->tMatrix )
                  ''tVec3(0) += pLeftPart->tMatrix.fPosX
                  ''tVec3(1) += pLeftPart->tMatrix.fPosY
                  ''tVec3(2) += pLeftPart->tMatrix.fPosZ
                  
                  DbgCrash()
                  
                  ''dim as single tVec3R(2) = { pRight->fPX , pRight->fPY , pRight->fPZ }
                  '''if pRight->pMatOrg then MultiplyMatrixVector( @tVec3R(0) , pRight->pMatOrg )
                  '''MultiplyMatrixVector( @tVec3R(0) , @.tMatrix )
                  dbg_printf(!"Right Snap <%g %g %g>\n",pRightSnap->tPos.X,pRightSnap->tPos.Y,pRightSnap->tPos.Z)
                  'MatrixTranslate( .tMatrix , pRight->fPX , -pRight->fPY , pRight->fpZ )
                  'MatrixTranslate( .tMatrix , .tLocation.fPX , -.tLocation.fPY , .tLocation.fpZ )
                  
                  tPos = Vector3_Transform( pRightSnap->tPos , .tMatrix )                                    
                  Vector3_Sub( .tPositionQ , tPos )
                                                                              
                  ''_fPX = ptLocation->fPX - (_fPX + tVec3R(0)) + .tLocation.fPX '.fPX
                  ''_fPY = ptLocation->fPY + (_fPY - tVec3R(1)) + .tLocation.fPY '.fPY
                  ''_fPZ = ptLocation->fPZ + (_fpZ + tVec3R(2)) + .tLocation.fPZ '.fPZ
                  
                  'if .tLocation.fPX = 0 andalso .tLocation.fPY=0 andalso .tLocation.fPZ=0 then
                  '.tLocation.fPX = _fPX : .tLocation.fPY = _fPY : .tLocation.fPZ = _fPZ
                  'elseif abs(.tLocation.fPX-_fPX)>.001 orelse abs(.tLocation.fPY-_fPY)>.001 orelse abs(.tLocation.fPZ-_fPZ)>.001 then
                  '   'LinkerError( "Impossible Connection detected!" )
                  'end if
                  
                  DbgCrash()
                  
                  dim as PartSize tPart = any  : tPart = pModel->tSize
                  var iIdx = .iModelIndex
                  'with tPart
                  '   dbg_printf(!"Part: %i = x:%f>%f y:%f>%f z:%f>%f\n", _
                  '     iIdx , .xMin,.xMax , .yMin,.yMax , .zMin,.zMax )
                  'end with
                  if (tPart.yMin-(-4)) < .0001 then tPart.yMin = 0
                  tPart.xMin = tPart.xMin+.1+.tPositionQ.X : tPart.xMax = tPart.xMax-.1+.tPositionQ.X
                  tPart.yMin = tPart.yMin+.1+.tPositionQ.Y : tPart.yMax = tPart.yMax-.1+.tPositionQ.Y
                  tPart.zMin = tPart.zMin+.1+.tPositionQ.Z : tPart.zMax = tPart.zMax-.1+.tPositionQ.Z               
                                                            
                  #if 0
                     for N as long = 0 to g_iPartCount-1
                        if N = iRightPart_ then continue for
                        if .tPositionQ.X = 0 andalso .tPositionQ.Y=0 andalso .tPositionQ.Z=0 then
                           continue for
                        end if
                        with g_tPart(N)                     
                           dim as PartSize tChk = any
                           tChk = g_tModels(g_tPart(N).iModelIndex).pModel->tSize                     
                           if (tChk.yMin-(-4)) < .0001 then tChk.yMin = 0                     
                           tChk.xMin = tChk.xMin+.1+.tLocation.fPX : tChk.xMax = tChk.xMax-.1+.tPosition.X
                           tChk.yMin = tChk.yMin+.1+.tLocation.fPY : tChk.yMax = tChk.yMax-.1+.tPosition.Y
                           tChk.zMin = tChk.zMin+.1+.tLocation.fPZ : tChk.zMax = tChk.zMax-.1+.tPosition.Z
                           if CheckCollision( tPart , tChk ) then
                              dim as zstring*128 zMessage = any
                              sprintf(zMessage,!"Collision! between part %s and %s",g_tPart(iRightPart_).sName,.sName)
                              LinkerWarning( zMessage )
                           end if
                        end with
                     next N
                  #endif
                  
                  DbgCrash()
                                                
                  var iColor = iif(.iColor<0,16,.iColor), psPrimative = @.sPrimative
                  'nearest = roundf(val * 100) / 100
                  var pPos = @.tPositionQ
                  with .tMatrix
                     #define r(_i) (roundf(.m(_i)*100000)/100000)
                     sprintf(zTemp,!"1 %i %f %f %f %g %g %g %g %g %g %g %g %g %s\r\n",iColor,pPos->X,pPos->Y,pPos->Z, _
                        r(0),r(1),r(2),r(3),r(4),r(5),r(6),r(7),r(8) , *psPrimative )
                  end with
                  sResult += zTemp 
                  #ifdef __Standalone
                  'dbg_printf("<%i>%s",__LINE__,zTemp)
                  dbg_printf("%s",zTemp)
                  #endif
               end with  
               
               DbgCrash()
               'dbg_puts("1 0 40 -24 -20 1 0 0 0 1 0 0 0 1 3001.dat")
               'dbg_puts("1 0 0 0 0 1 0 0 0 1 0 0 0 1 3001.dat")
            end with
         next I   
                   
         DbgCrash()
         
         ''print "First? ";bFirstConnect , "New? ";bDidConnect , "More? ";bHaveStrayConnections : sleep 
         ''print "-----------------------------------------------------------------------"
         if bDidConnect=false then 'there was no connections made?
            if bFirstConnect=false andalso bHaveStrayConnections then 'and there was no stray connections? then we're done!                  
               DbgBuild(">> There's still unconnected parts, so do extra pass")
               bFirstConnect=true : continue do 'there's stray connections, so we restart
            end if
            exit do 'no more possible connections, so we're done
         end if            
      loop         
      ''sleep
   end if
   
   DbgBuild("--- Build Complete ---")
   
   'DebugParts()
   DbgCrash()
   clear sToken(0),0,16*sizeof(fbStr) ': erase sToken
   clear sStatement,0,sizeof(fbStr)   ': sStatement = ""
   
   'cleanup dynamically allocated scripts (1=main = not dynamically created)
   for N as long = 2 to iFileCount
      with aFile(N)
         if .psScript   then delete .psScript   : .psScript   = 0
         if .psFilename then delete .psFilename : .psFilename = 0
         if .psFilepath then delete .psFilepath : .psFilepath = 0
      end with
   next N
   
   redim as PartStructLS g_tPart(_cPartMin)
   redim as PartConnLS g_tConn(_cConnMin)
   
   return sResult
   
end function

#ifdef __Standalone
   var isTerm = _isatty( _fileno(stdout) )
   dim as string sText,sScript
   var sCmd = command(), iDump=0
   if len(sCmd) then
      var f = freefile() : iDump=1
      if open(sCmd for binary access read as #f) then
         Errorf(!"Failed to open '%s'\n",sCmd)
         GiveUp(2)
      end if
      sScript = space(lof(f))
      get #f,,sScript : close #f
   else   
      if IsTerm=0 then
         Errorf(!"SYNTAX: ls2dlr file.ls >output.ldr")
         GiveUp(1)
      end if
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
      #if 0
         sScript = _
           !"3865 BP10 #7 s69 = 3001p11 B1 y90 c1;" _ '4070 (side stud) (87087 have shadow problems)
           !"B1 s1 = 3001p11 B2 #2 c5;" _
           !"B2 s1 = 3001p11 B3 #3 c6;" _
           !"B3 c5 = 3001p11 B4 #4 s1;" _ '71752 '3021
           !"B4 c1 = 4070 B5 #5 s2;"    'collision
           '!"003238a P1 #2 c1 = 003238b P2 #4 s1;"
      #endif   
      #if 0
         'sScript = _ 
         '   !"87087 B1 s1 = 87087 B2 #2 x-90 c1;"
         sScript = _
            !"3865 BP10 #7 s69 = 3001p11 B1 c1; \n" _
            !"B1 s1 = 3001p11 B2 #2 c5; \n " _
            !"B2 s1 = 3001p11 B3 #3 c6; \n" _
            !"B3 c5 = 3001p11 B4 #4 s1; \n" _
            !"B4 c1 = 4070 B5 #5 s22; \n" 
      #endif   
      #if 0
         sScript = _
            "3002 B2 #7 s1 = 3001p11 B1 xo12 c1;" !"\n" '_
            '"3001 B3 #2 s2 = B1 c1;"         !"\n"
      #endif   
      #if 0
         sScript = _
         "3023 P1 #1 c1 = 3023 P2 #2 s2;" !"\n" _
         "3001 P3 #4 c1 = P2 s1;"         !"\n"
      #endif
      #if 0
         sScript = _
            "3001 B1 #2 y90 xo100 c1 = 3001 B2 #3 s1;" !"\n" _
            "3002 B3 #4 c1 = 3002 B4 #5 s1;"           !"\n" _
      #endif
      #if 1
         '"3958 B1 #black s1 = 3005 B2 c1;"
         '"3001 B1 #black s1 = 3001 B2 c1;"
         sScript = _
            "2356 B1 #y0 s1 = 3001 P1 #y90 #xo20 #2 c1; " !"\n" _
            "P1 s8 = 3005 B2 #3 c1;"
         'sScript = _         
         '   "2356 B2 #black #yo50 s1 = 3005 P2 #black c1;" !"\n" _
         '   "2356 B1 #y30 s1 = 3001 P1 #2 c1;"
      #endif
   
        
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
   
   if len(sModel) andalso isTerm then   
      var sParms = """"+sModel+""""
      puts("-----------------")
      print sModel
      exec(exepath()+"\Loader\ViewModel.exe",sParms)
      'sleep
      puts("-----------------")
      end 0
   else
      if iDump=0 andalso IsTerm then sleep
      end 0
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
#endif
