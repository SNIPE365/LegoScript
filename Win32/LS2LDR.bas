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

'puts("3001 <2> B1 s7 = 3001 <2> B2 c1;")
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
   ecNoError        = 0
end enum   

type PartNameStruct
   sName       as string
   iModelIndex as long
end type

static shared as byte g_bSeparators(255)
static shared as PartNameStruct g_tPart(1023)
static shared as long g_iNameCount

scope
   var sSeparators = !"\9 "   
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
function FindName( sName as string ) as long
   if len(sName) < 1 then return ErrInfo(ecNotFound)
   for N as long = 0 to g_iNameCount-1
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
function AddPartName( sName as string , sPart as string ) as long   
         
   'skip '0 prefix (as no part name start with a '0')
   var bPartPrefix =  (sPart[0]=asc("0"))
   if bPartPrefix then with *Cast_fbStr(sPart) : .pzData += 1 : .iLen -= 1 : end with   
   
   var iIndex = FindModelIndex( sPart )
   'load part if not loaded yet
   if iIndex < 0 then
      dim as string sFile=sPart+".dat",sModel
      if bPartPrefix then with *Cast_fbStr(sPart) : .pzData -= 1 : .iLen += 1 : end with
      if FindFile(sFile)=0 then return ErrInfo(ecNotFound)                  'part name not found
      if LoadFile( sFile , sModel ) = 0 then return ErrInfo(ecFailedToLoad) 'part failed to load file
      var pModel = LoadModel( strptr(sModel) , sFile )                      
      if pModel=0 then return ErrInfo(ecFailedToParse)                      'part failed to parse
      iIndex = pModel->iModelIndex
   else
      if bPartPrefix then with *Cast_fbStr(sPart) : .pzData -= 1 : .iLen += 1 : end with   
   end if
   'generate snap if not generated yet
   var pModel = g_tModels(iIndex).pModel
   if pModel->pData = 0 then   
      pModel->pData = new PartSnap
      var pSnap = cptr(PartSnap ptr,pModel->pData)
      SnapModel( pModel , *pSnap )
   end if
   
   with g_tPart( g_iNameCount )
      .sName      = sName
      .iModelIndex = iIndex
   end with
   g_iNameCount += 1
   return g_iNameCount-1
   
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
         print "{"+sToken(N)+"}";
      next N
      print
      
      dim as long iCurToken=0 , iLeft=ecNotFound , iRight=ecNotFound      
      do          
         #define ParserError( _text ) print "Error: ";_text;" at '";sStatement;"'" : sResult="" : exit while
         #define sRelToken(_N) sToken(iCurToken+(_N))
         #define sCurToken sToken(iCurToken)
         var iName=ecNotFound      
         
         if IsTokenNumeric( sCurToken ) then                     
            #define sPart sCurToken
            #define sName sRelToken(1)
            if iCurToken >= iTokCnt then ParserError( "Expected part name, got end of statement" )
            iName = FindName( sName )
            if iName >= 0 then ParserError( "Name already exists" )            
            iName = AddPartName( sName , sPart  )            
            iCurToken += 2
            
         else
            #define sName sCurToken
            iName = FindName( sName )
            if iName < 0 then ParserError( "part name not declared" )
            iCurToken += 1
         end if
         
         'just a part declaration
         if iCurToken = iTokCnt then exit do
         do 
            if iCurToken = iTokCnt then                
               if iLeft < 0 then ParserError("premature end of statement")
               iRight = iName
               print iLeft,iRight
               exit do,do
            end if
            iCurToken += 1
            if sRelToken(-1)[0]=asc("=") then                
               if iLeft < 0 then 
                  iLeft = iName
               else
                  ParserError("expected end of statement, got "+sCurToken)
               end if
               continue do,do
            end if         
         loop
      loop
      
      if iStNext=0 then exit while else iStStart = iStNext+1      
   wend
         
   clear sToken(0),0,16*sizeof(fbStr) ': erase sToken
   clear sStatement,0,sizeof(fbStr)   ': sStatement = ""   
   
   return sResult
   
end function

dim as string sText
var sScript = _
"3001 B1;" _
"B1 s7 = 3001 B2 c1;    ;" _
"B2 s7=3001 B3 c1;"
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
