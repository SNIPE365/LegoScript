#ifndef __Main
  #error " Don't compile this one"
#endif  

'TODO (20/02/2025) - Create a free index list, so that holes in the array and string can be reused

'#cmdline "-gen gcc -O 3"
#include once "crt.bi"
#include once "vbcompat.bi"

#define RGBA_R( c ) ( CUInt( c ) Shr 16 And 255 )
#define RGBA_G( c ) ( CUInt( c ) Shr  8 And 255 )
#define RGBA_B( c ) ( CUInt( c )        And 255 )
#define RGBA_A( c ) ( CUInt( c ) Shr 24         )

'#define __DebugShadowLoad
'#define DebugPrimitive
'#define DebugLoading
'#define IgnoreMissingDependencies

const cScale = 1'/20

#include once "Include\Structs.bas"
#include once "Include\PartPaths.bas"

'dim shared as string g_sLog
dim shared as string g_sFilenames,g_sFilesToLoad
dim shared as long g_ModelCount , g_LoadQuality = 1 'normal
redim shared as ModelList g_tModels(0)

g_sFilenames = chr(0)
g_sFilesToLoad = chr(0)

#ifndef GiveUp
  #define GiveUp(_N) sleep: end (_N)
#endif

#include "Modules\ParserFunctions.bas"

function LoadShadow( pPart as DATFile ptr , sFromFile as string , bRecursion as long = 0) as boolean
   
   #macro CheckError(_s , _separator... )
      #if len( #_separator )
        if iResu>0 andalso pFile[iResu] <> asc(_separator) then iResu = -1
      #endif
      if iResu<0 then
         puts _s " error reading '"+sFilename+"' at line " & iLineNum
         GiveUp(1)
         iFailed = 1 : exit do
      end if
   #endmacro
   #macro CheckEndOfLine()
      while *pFile <> asc(!"\n")
         select case *pFile
         case 0                    : exit do 'last line of file so we're done SUCCESS
         case asc("\r"),9,asc(" ") 'skipping spaces/tabs/CR
         case else
            puts " expect end of line in '"+sFilename+"' at line " & iLineNum
            iFailed = 1 : exit do
         end select
         pFile += 1         
       wend
       iLineNum += 1 : pFile += 1 : continue do 'now it point to the being of next line
   #endmacro
   #macro NextLine()
      while *pFile <> asc(!"\n") andalso *pfile : pFile += 1 : wend
      if *pFile=0 then exit do 'last line of file so we're done SUCCESS
      iLineNum += 1 : pFile += 1 'now it point to the being of next line
   #endmacro
         
   var iPos = instrrev(sFromFile,"\") , iPos2 = instrrev(sFromFile,"/")
   if iPos2 > iPos then iPos = iPos2      
   var sShadowFile = mid(sFromFile,iPos+1)
   #define sFilename sShadowFile
   if FindShadowFile( sShadowFile ) then         
      #if (not defined(__Tester)) andalso defined(__DebugShadowLoad)
         if bRecursion=0 then
            printf(!"[%s] have shadow\n",sShadowFile)
         else
            printf(!"[%s] included shadow\n",sFromFile)
         end if
      #endif
   else
      if bRecursion then
         printf(!"[%s] was referenced in a shadow file, but was not found\n",sShadowFile)
      end if
      'printf(!"[%s] does NOT have shadow\n",sShadowFile)
      return false
   end if     
   
   dim as string sContent
   if LoadFile( sShadowFile , sContent , false ) then
      dim as ubyte ptr pFile = strptr(sContent)
      dim as long iType = any , iResu = any ', iColour = any
      dim as long iFailed=0 , iLineNum = 1
      do
         'at this point we should assume we are at the begin of a line so we get a line type
         iResu = ReadInt( pFile , iType )
         if iResu=0 then 'empty line
            NextLine() : continue do 'so let's get the next one         
         end if
         CheckError( "Syntax" ) 'failed to read the line type integer?
         pFile += iResu 'advancing to the next component
      
         'only comments are expected
         if iType<>0 then
            puts "ERROR: only comments are expect in shadow files, in '"+sFilename+"' at line " & iLineNum         
            NextLine() : continue do
            'iFailed = 1 : exit do         
         end if      
         
         #macro GetFloat( _ptr , _var , _description , _separator... )            
            iResu = ReadFloat( _ptr , _var )            
            CheckError( "ERROR: Expected " _description " parameter" ) 'failed to read the line type float?
            _ptr += iResu
         #endmacro
         #macro GetInt( _ptr , _var , _description , _separator... )            
            iResu = ReadInt( _ptr , _var )            
            CheckError( "ERROR: Expected " _description " parameter" ) 'failed to read the line type int?
            _ptr += iResu
         #endmacro         
                     
         rem select case iType 'which line type is it?      
         rem case 0 'ignore if comment OR empty line and advance to next line        
            dim as string sType
            iResu = ReadToken( pFile , sType )            
            pFile += iResu
                     
            var suType = ucase(sType)
            if suType = "//!LDCAD" then
               #if (not defined(__Tester)) andalso defined(__DebugShadowLoad)               
               puts("Unignoring commented !LDCAD")
               #endif
               suType = "!LDCAD"
            end if
            'ignore all non !LDCAD comments
            if suType <> "!LDCAD" then 
               NextLine() : continue do
            end if                        
            iResu = ReadToken( pFile , sType )
            pFile += iResu
                        
            'https://www.melkert.net/LDCad/tech/meta
            '[scale<vec3>] [ID<string>] [grid<annoying>]
            #if (not defined(__Tester)) andalso defined(__DebugShadowLoad)
            printf("{%s} - ",sType)
            #endif
            select case ucase(sType)
            'case "SNAP_CLEAR" '0 !LDCAD SNAP_CLEAR [id<string>=axleHole]
            case "SNAP_INCL"  '0 !LDCAD SNAP_INCL [ref<string>=connhole.dat] [pos<vec3>=-50 10 0] [ori<mat3>=0 -1 0 0 0 -1 1 0 0] [grid=C 1 C 3 20 20] // 
               'printf(!"<%s>\n",sType)
               if bRecursion=3 then
                  iResu=-1
                  CheckError("Shadow include Recursion limit reached")
               end if
               ReadLine( pFile , sType )
               dim as string sName,sParms
               pPart->iShadowCount += 1
               dim as ShadowStruct ptr pNew = realloc( pPart->paShadow ,  sizeof(ShadowStruct)*pPart->iShadowCount )
               if pNew = 0 then
                  iResu=-1
                  CheckError("Out of memory")
               end if
               pPart->paShadow = pNew
               pNew += (pPart->iShadowCount-1)
               clear *pNew , 0 , sizeof(ShadowStruct)
               pNew->bType       = sit_Include
               pNew->bRecurse    = bRecursion
               pNew->tGrid.xCnt = 1 : pNew->tGrid.xStep = 0
               pNew->tGrid.zCnt = 1 : pNew->tGrid.zStep = 0
               dim as string sRefFile
               do
                  #define cvl2(_s) (cvl(_s "  ") and &hFFFFFF)
                  #define cvl3(_s) cvl(_s " ")
                  var iResu = ReadBracketOption( pFile , sName , sParms )
                  CheckError( "Syntax" )
                  pFile += iResu : if len(sName)=0 then exit do
                  #if (not defined(__Tester)) andalso defined(__DebugShadowLoad)
                  printf(!">>> name='%s' parms='%s'\n",sName,sParms)
                  #endif
                  select case *cptr(ulong ptr,strptr(sName)) or &h20202020 'lcase(sName)
                  case cvl3("ref")
                     if len(sRefFile) then
                        iResu=-1
                        CheckError("duplicated reference")
                     end if
                     var pParm = cast(ubyte ptr,strptr(sParms))
                     iResu = ReadToken( pParm , sRefFile )                        
                     if iResu <= 0 then 
                        iResu=-1
                        CheckError("null reference")
                     end if
                  case cvl3("pos")   'X Y Z
                     var pPos = @(pNew->fPosX) , pParm = cast(ubyte ptr,strptr(sParms))
                     for N as long = 0 to (3-1) 'position vector
                        GetFloat( pParm , *pPos , "Position" )
                        '#if (not defined(__Tester)) andalso defined(__DebugShadowLoad)
                        'printf("<%f>",*pPos)
                        '#endif
                        pPos += 1
                     next N
                     'puts("")
                  case cvl("grid")   '['C'] CntX ['C'] CntY StepX stepZ
                     var pParm = cast(ubyte ptr,strptr(sParms))
                     dim as long   lCntX=any , lCntZ=any
                     dim as single fStepX=any, fStepZ=any
                     #macro ChkToken()
                        While *pParm = asc(" ") orelse *pParm = 9 : pParm += 1 : wend
                        if ((*pParm and (not &h20)) <> asc("C")) andalso ((*pParm < asc("0")) orelse (*pParm > asc("9"))) then
                           iResu = -1
                           CheckError( "grid syntax" )
                        end if
                     #endmacro
                     ChkToken()
                     if (*pParm and (not &h20))=asc("C") then
                        pParm += 1
                        GetInt( pParm , lCntX , "grid X Count" )                         
                        lCntX = -lCntX
                     else
                        GetInt( pParm , lCntX , "grid X count" )
                     end if
                     if lCntX = 0 then
                        iResu = -1
                        CheckError( "invalid grid X count" )
                     end if
                     ChkToken()
                     if (*pParm and (not &h20))=asc("C") then
                        pParm += 1
                        GetInt( pParm , lCntZ , "grid Z count" )                         
                        lCntZ = -lCntZ
                     else
                        GetInt( pParm , lCntZ , "grid Z count" )
                     end if  
                     if lCntX = 0 then
                        iResu = -1
                        CheckError( "invalid grid Z count" )
                     end if
                     GetFloat( pParm , fStepX , "grid step X" )
                     #ifndef __Tester
                     if (cint(fStepX)*100) <> cint(fStepX*100) then printf(!"Warning: float grid step X (%f)\n", fStepX)
                     #endif
                     GetFloat( pParm , fStepZ , "grid step Z" )
                     #ifndef __Tester
                     if (cint(fStepZ)*100) <> cint(fStepZ*100) then printf(!"Warning: float grid step Z (%f)\n", fStepZ)
                     #endif
                     '#if (not defined(__Tester)) andalso defined(__DebugShadowLoad)
                     'printf(!"Grid: %ix%i step %g,%g\n",lCntX,lCntZ,fStepX,fStepZ)
                     '#endif
                     pNew->bFlagHasGrid = true
                     with pNew->tGrid
                        .Xcnt  = lCntX  : .Zcnt  = lCntZ
                        .Xstep = fStepX : .Zstep = fStepZ                        
                     end with
                  case cvl3("ori")   'Mat3x3
                     var pOri = @(pNew->fOri(0)) , pParm = cast(ubyte ptr,strptr(sParms))
                     pNew->bFlagOriMat = true
                     for N as long = 0 to (9-1) 'Orientation 3x3 matrix
                        GetFloat( pParm , *pOri , "Orientation" )
                        '#if (not defined(__Tester)) andalso defined(__DebugShadowLoad)
                        'printf("<%f>",*pOri)
                        '#endif
                        pOri += 1
                     next N
                     'puts("")
                  
                  case else
                     iResu=-1
                     CheckError("shadow Include parm")
                  end select
               loop
               if len(sRefFile)=0 then
                  iResu=-1
                  CheckError("include without reference")
               end if
               LoadShadow( pPart , sRefFile , bRecursion+1 )               
               NextLine() : continue do
               
            case "SNAP_CYL"   '0 !LDCAD SNAP_CYL [id=connhole] [gender=F] [caps=none] [secs=R 8 2 R 6 16 R 8 2] [center=true] [slide=true] [pos=0 0 0] [ori=1 0 0 0 1 0 0 0 1]
               #if 0 
                  'puts("SNAP!")
                  'Property   Type 	      Default    Description
                  'ID         string 	  	           Optional identifier which can be used in clear metas to optionally drop this meta's information in higher level parts using it.
                  'group 	   string 	  	           optional group identifier. Can be used to limit potential matches to only snap info having the same group string. Can be used to prevent unwanted matches when very complicated shapes are involved e.g. click rotation holes etc.
                  'pos        vector 	  	           Position of this shape.
                  'ori        3x3 matrix             Orientation of this shape.
                  'scale 	   enum        none 	     Defines how scaled references to the master (official) part should be handled information inheritance wise. Must be one of the following:
                  '                      	           none: If scaling is detected this information will not be inherited by the higher level part.
                  '                      	           YOnly: The information will only be inherited if scaling is limited to the Y-axis, if X and or Z is scaled the info will not be inherited.
                  '                      	           ROnly: The information will only be inherited if scaling is limited to the cylinder's radius (usually x and z) given its done symmetrical. If the info is scaled in any other way it will not be inherited.
                  '                      	           YandR: The information will only be inherited if YOnly or ROnly rules apply.
                  'mirror     enum        cor        Defines how mirrored references to the master (official) part should be handled information inheritance wise. Must be one of the following:
                  '                      	           none: If mirroring is detected this information will not be inherited by the higher level part.
                  '                      	           cor: If mirroring is detected the snap information will be corrected by flipping one of the radius axis'.
                  'gender     enum        male       Sets the gender of the cylinder shape M for male (pen) and F for female (hole).
                  'secs       mixed array            Describes the shape of the hole (along the neg Y-axis) or pen by a sequence of shape variants, radius's and lengths. The info must be given in blocks of: shapeVariant radius length where shapeVariant must be one of the following:
                  '                      	             R: Round.
                  '                      	             A: Axle.
                  '                      	             S: Square.
                  '                      	             _L: Flexible radius wise extension to the previous block's specs. This will be needed for e.g. the tip of an technic connector pin. Although it is slightly larger it allows for (temporary) compression while sliding the pin inside e.g. a beam hole.
                  '                      	             L_: Same as _L but as an extension to the next section instead of the previous one.
                  '                          	           For example a plain stud can be described using a single block: R 8 4 while a technic beam hole needs three: R 8 2 R 6 16 R 8 2.
                  'caps       enum        one        Defines the ends of the shape, must be one of the following:
                  '                      	             none: The shape is open ended. e.g. a male axle or female beam hole.
                  '                      	             one: The shape has one closed ending, which one depends on the gender. For male shapes it will be A (bottom) and for female shapes it will be B (top).
                  '                      	             two: The shape is closed (blocked) at both sides. e.g. the male bar of a minifig suitcase handle.
                  '                      	             A: The bottom is closed / blocked. e.g. a stud.
                  '                      	             B: The top is closed / blocked. e.g. an anti stud.
                  'grid       mixed array            Defines a grid pattern to use for multiple placement of this cylindrical shape. The grid uses the orientation stated in the ori parameter. As all snap info is Y-axis orientated only the X and Z grid stepping values need to be given like so:
                  '                                  Xcnt Zcnt Xstep Zstep for example: 4 8 20 20 which could be used to make a 4x8 grid of e.g. studs.
                  '                                  Optionally each count value can be preceded by a C character indicating the grid should be centered on that axis. If no C is given the axis will add to the pos parameter. For example to center the 4x8 grid around it's pos parameter use: C 4 C 8 20 20
                  'center     boolean     false      Indicates if this cylinder shape should be centered at its position or not.
                  'slide      boolean     false      Indicates if this cylinder shape should be considered 'smooth' enough to make sliding of matching parts possible. If ether part of a matched pair of snap info metas has the slide option set to true the user will be able to slide them together. If not it will just 'snap'.
                  '                      	           Be careful while setting this option as it can cause unwanted sliding of e.g. a stud inside an anti stud. In practice it is best to limit the slide=true value to things you know will slide most of the time (e.g. clips, bush and gear parts etc).
               #endif
               ReadLine( pFile , sType )
               #if (not defined(__Tester)) andalso defined(__DebugShadowLoad)
               printf(!"<%s>\n",sType)
               #endif
               dim as string sName,sParms
               pPart->iShadowCount += 1
               dim as ShadowStruct ptr pNew = realloc( pPart->paShadow ,  sizeof(ShadowStruct)*pPart->iShadowCount )
               if pNew = 0 then
                  iResu=-1
                  CheckError("Out of memory")
               end if
               pPart->paShadow = pNew
               pNew += (pPart->iShadowCount-1)
               clear *pNew , 0 , sizeof(ShadowStruct)
               pNew->bType       = sit_Cylinder 
               pNew->bRecurse    = bRecursion
               pNew->bFlagMirror = true 'defaults
               pNew->tGrid.xCnt = 1 : pNew->tGrid.xStep = 0
               pNew->tGrid.zCnt = 1 : pNew->tGrid.zStep = 0
               do
                  #define cvl2(_s) (cvl(_s "  ") and &hFFFFFF)
                  #define cvl3(_s) cvl(_s " ")
                  var iResu = ReadBracketOption( pFile , sName , sParms )
                  CheckError( "Syntax" )
                  pFile += iResu : if len(sName)=0 then exit do
                  ''#if (not defined(__Tester)) andalso defined(__DebugShadowLoad)
                  ''printf(!">> name='%s' parms='%s'\n",sName,sParms)
                  ''#endif
                  select case *cptr(ulong ptr,strptr(sName)) or &h20202020 'lcase(sName)
                  case cvl("gender") 'F' or 'M'
                     select case sParms[0] or &h20
                     case asc("f"): pNew->bFlagMale = false
                     case asc("m"): pNew->bFlagMale = true
                     case else
                        iResu = -1
                        CheckError("Invalid Gender")
                     end select
                  case cvl("secs")   'shapeVariant radius length
                     'Describes the shape of the hole (along the neg Y-axis) or pen by a sequence of shape variants, 
                     'radius's and lengths. The info must be given in blocks of: 
                     '  shapeVariant radius length 
                     'where shapeVariant must be one of the following:
                     '  R: Round.
                     '  A: Axle.
                     '  S: Square.
                     '  _L: Flexible radius wise extension to the previous block's specs. 
                     '      This will be needed for e.g. the tip of an technic connector pin. 
                     '      Although it is slightly larger it allows for (temporary) compression
                     '      while sliding the pin inside e.g. a beam hole.
                     '  L_: Same as _L but as an extension to the next section instead of the previous one.
                     'For example a plain stud can be described using a single block: R 8 4 
                     'while a technic beam hole needs three: R 8 2 R 6 16 R 8 2.
                     var pParm = cast(ubyte ptr,strptr(sParms))
                     dim sShape as string
                     dim as long iSecs=0, iShapeID=any
                     dim as single fRad=any , fLen=any                     
                     do
                        iResu = ReadToken( pParm , sShape )                        
                        if iResu <= 0 then exit do
                        if iSecs >= cShadowMaxSecs then
                           iResu = -1
                           CheckError( "Too many secs" )
                        end if
                        pParm += iResu
                        var iShape = *cptr(ushort ptr,strptr(sShape)) and (not &h2020)
                        select case iShape
                        case     asc("R") : iShapeID=sss_Round
                        case     asc("A") : iShapeID=sss_Axle
                        case     asc("S") : iShapeID=sss_Square
                        case cvshort("_L"): iShapeID=sss_FlexPrev
                        case cvshort("L_"): iShapeID=sss_FlexNext
                        case else
                           iResu = -1
                           CheckError( "Invalid sec shape" )
                        end select
                        GetFloat( pParm , fRad , "Radius" )
                        #ifndef __Tester
                        if (cint(fRad*100)*100) <> cint(fRad*100*100) then printf(!"Warning: innacurate fixed Radius (%f)\n", fRad)
                        #endif
                        GetFloat( pParm , fLen , "Length" )
                        #ifndef __Tester
                        if (cint(fLen)*100) <> cint(fLen*100) then printf(!"Warning: float Length (%f)\n", fLen)
                        #endif
                        '#if (not defined(__Tester)) andalso defined(__DebugShadowLoad)
                        'printf(!"Shape:(%i)'%s' Rad:%g Len:%g\n",iShapeID,sShape,fRad,fLen)
                        '#endif
                        with pNew->tSecs(iSecs)
                           .bshape  = iShapeID
                           .wFixRadius = fRad*100
                           .bLength = fLen                           
                        end with
                        iSecs += 1
                     loop
                     if iSecs=0 then
                        iResu = -1
                        CheckError( "sec syntax" )
                     end if 
                     pNew->bSecCnt = iSecs
                  case cvl("caps")   '"none" , "one" , "two" , "A" , "B"
                     select case *cptr(ushort ptr,strptr(sParms)) or &h2020 'lcase(sName)
                     case cvshort("none"): pNew->bCaps = sc_None
                     case cvshort("one") : pNew->bCaps = sc_One
                     case cvshort("two") : pNew->bCaps = sc_Two
                     case cvshort("a ")  : pNew->bCaps = sc_A
                     case cvshort("b ")  : pNew->bCaps = sc_B
                     case else
                        iResu = -1
                        CheckError("Invalid caps")
                     end select
                  case cvl3("pos")   'X Y Z
                     var pPos = @(pNew->fPosX) , pParm = cast(ubyte ptr,strptr(sParms))
                     for N as long = 0 to (3-1) 'position vector
                        GetFloat( pParm , *pPos , "Position" )
                        '#if (not defined(__Tester)) andalso defined(__DebugShadowLoad)
                        'printf("<%f>",*pPos)
                        '#endif
                        pPos += 1
                     next N
                     '#if (not defined(__Tester)) andalso defined(__DebugShadowLoad)
                     'puts("")
                     '#endif
                  case cvl("grid")   '['C'] CntX ['C'] CntY StepX stepZ
                     var pParm = cast(ubyte ptr,strptr(sParms))
                     dim as long   lCntX=any , lCntZ=any
                     dim as single fStepX=any, fStepZ=any
                     #macro ChkToken()
                        While *pParm = asc(" ") orelse *pParm = 9 : pParm += 1 : wend
                        if ((*pParm and (not &h20)) <> asc("C")) andalso ((*pParm < asc("0")) orelse (*pParm > asc("9"))) then
                           iResu = -1
                           CheckError( "grid syntax" )
                        end if
                     #endmacro
                     ChkToken()
                     if (*pParm and (not &h20))=asc("C") then
                        pParm += 1
                        GetInt( pParm , lCntX , "grid X Count" )                         
                        lCntX = -lCntX
                     else
                        GetInt( pParm , lCntX , "grid X count" )
                     end if
                     if lCntX = 0 then
                        iResu = -1
                        CheckError( "invalid grid X count" )
                     end if
                     ChkToken()
                     if (*pParm and (not &h20))=asc("C") then
                        pParm += 1
                        GetInt( pParm , lCntZ , "grid Z count" )                         
                        lCntZ = -lCntZ
                     else
                        GetInt( pParm , lCntZ , "grid Z count" )
                     end if  
                     if lCntX = 0 then
                        iResu = -1
                        CheckError( "invalid grid Z count" )
                     end if
                     GetFloat( pParm , fStepX , "grid step X" )
                     #ifndef __Tester
                     if (cint(fStepX)*100) <> cint(fStepX*100) then printf(!"Warning: float grid step X (%f)\n", fStepX)
                     #endif
                     GetFloat( pParm , fStepZ , "grid step Z" )
                     #ifndef __Tester
                     if (cint(fStepZ)*100) <> cint(fStepZ*100) then printf(!"Warning: float grid step Z (%f)\n", fStepZ)
                     #endif
                     '#if (not defined(__Tester)) andalso defined(__DebugShadowLoad)
                     'printf(!"Grid: %ix%i step %g,%g\n",lCntX,lCntZ,fStepX,fStepZ)
                     '#endif
                     pNew->bFlagHasGrid = true
                     with pNew->tGrid
                        .Xcnt  = lCntX  : .Zcnt  = lCntZ                        
                        .Xstep = fStepX : .Zstep = fStepZ
                     end with
                  case cvl3("ori")   'Mat3x3
                     var pOri = @(pNew->fOri(0)) , pParm = cast(ubyte ptr,strptr(sParms))
                     pNew->bFlagOriMat = true
                     for N as long = 0 to (9-1) 'Orientation 3x3 matrix
                        GetFloat( pParm , *pOri , "Orientation" )
                        '#if (not defined(__Tester)) andalso defined(__DebugShadowLoad)
                        'printf("<%f>",*pOri)
                        '#endif
                        pOri += 1
                     next N
                     '#if (not defined(__Tester)) andalso defined(__DebugShadowLoad)
                     'puts("")
                     '#endif
                  case cvl("center") 'T'rue or 'F'alse
                     select case sParms[0] or &h20
                     case asc("f"): pNew->bFlagCenter = false
                     case asc("t"): pNew->bFlagCenter = true
                     case else
                        iResu = -1
                        CheckError("Invalid Cender")
                     end select
                  case cvl("slide")  'T'rue or 'F'alse
                     select case sParms[0] or &h20
                     case asc("f"): pNew->bFlagSlide = false
                     case asc("t"): pNew->bFlagSlide = true
                     case else
                        iResu = -1
                        CheckError("Invalid Cender")
                     end select
                  case cvl("scale")  '"none" , "YOnly" , "ROnly" , "YandR" 
                     select case *cptr(ulong ptr,strptr(sParms)) or &h20202020 'lcase(sName)
                     case cvl("none")  : pNew->bScale = ss_None
                     case cvl("yonly") : pNew->bScale = ss_YOnly
                     case cvl("ronly") : pNew->bScale = ss_ROnly
                     case cvl("yandr") : pNew->bScale = ss_YandR
                     case else
                        iResu = -1
                        CheckError("Invalid Scale")
                     end select
                  case cvl("mirror") '"none" or "cor"
                     select case *cptr(ulong ptr,strptr(sParms)) or &h20202020 'lcase(sName)
                     case cvl("none")  : pNew->bFlagMirror = false
                     case cvl3("cor")  : pNew->bFlagMirror = true                     
                     case else
                        iResu = -1
                        CheckError("Invalid Mirror")
                     end select
                  case cvl("group")  '-- maybe implement --
                  case else          'ID or error...
                     'special case for 2 letters
                     select case (*cptr(ulong ptr,strptr(sName)) or &h20202020) and &hFFFFFF
                     case cvl2("id") '-- maybe implement --
                     case else
                        iResu=-1
                        CheckError("Cylinder Parm")
                     end select
                  end select                    
               loop                  
               NextLine() : continue do
            'case "SNAP_CLP"   '0 !LDCAD SNAP_CLP [radius=4] [length=8] [pos=0 0 0] [ori=1 0 0 0 1 0 0 0 1] [center=true]
            'case "SNAP_FGR"   '0 !LDCAD SNAP_FGR [group=lckHng] [genderOfs=M] [seq=4.5 8 4.5] [radius=6] [center=true] [pos=-30 10 0] [ori=1 0 0 0 0 1 0 -1 0]
            'case "SNAP_GEN"   '0 !LDCAD SNAP_GEN [group=nxtc] [gender=M] [pos=0 -1.5 1.5] [ori=1 0 0 0 0 1 0 -1 0] [bounding=box 12.5 16.5 8]
            'case "SNAP_SPH"   '0 !LDCAD SNAP_SPH [gender=M] [radius=4]
            end select
            
            '#if (not defined(__Tester)) andalso defined(__DebugShadowLoad)
            'printf(!"unimplmented shadow: <'%s'>\n",sType)
            '#endif
            pFile += ReadLine( pFile , sType )                        
            if sType="" then sType=" "               
            #if (not defined(__Tester)) andalso defined(__DebugShadowLoad)
            printf(!"unimplmented shadow: '%s'\n",sType)
            #endif
            NextLine() : continue do
         rem end select
      loop
      if iFailed then
         printf("ERROR: Failed to load shadow file '%s'\n",sFilename)
      end if
      return iFailed=0
   end if
   return false

end function

function LoadModel( pFile as ubyte ptr , sFilename as string = "" , iModelIndex as long = -1 , iLoadDependencies as byte = 1 ) as DATFile ptr   
   if pFile = NULL then pFile = @" "
   #macro CheckError(_s , _separator... )
      #if len( #_separator )
        if iResu>0 andalso pFile[iResu] <> asc(_separator) then iResu = -1
      #endif
      if iResu<=0 then
         puts _s " error reading '"+sFilename+"' at line " & iLineNum
         GiveUp(1)
         iFailed = 1 : exit do
      end if
   #endmacro
   #macro CheckEndOfLine()
      while *pFile <> asc(!"\n")
         select case *pFile
         case 0                    : exit do 'last line of file so we're done SUCCESS
         case asc(!"\r"),9,asc(" ") 'skipping spaces/tabs/CR
         case else
            puts " expect end of line in '"+sFilename+"' at line " & iLineNum
            iFailed = 1 : exit do
         end select
         pFile += 1         
       wend
       iLineNum += 1 : pFile += 1 : continue do 'now it point to the being of next line
   #endmacro
   #macro NextLine()
      while *pFile <> asc(!"\n") andalso *pfile : pFile += 1 : wend
      if *pFile=0 then exit do 'last line of file so we're done SUCCESS
      iLineNum += 1 : pFile += 1 'now it point to the being of next line
   #endmacro

   #define PartsToBytes(_N) (offsetof(DATFile,tParts(0))+(_N)*sizeof(PartStruct))
      
   dim as long iLastPart=0 , iLimitParts=-1 , iFailed=0, iLineNum = 1
   dim as long iType = any , iColour = any , iResu = any   
   dim as DATFile ptr pT = NULL 'pointer to the file structure in memory
   dim as long iFilenameOffset=0
   static as long RecursionLevel , iTotalLines , iTotalParts
   iTotalLines = 0 : iTotalParts = 0
   RecursionLevel += 1
   
   'if already referenced then we will use that index
   'otherwise add a new index to the model/submodel
   if iModelIndex < 0 then
      iModelIndex = g_ModelCount
      redim preserve g_tModels( g_ModelCount )
      g_ModelCount += 1
   end if
         
   do
      if iLastPart > iLimitParts then 'allocate more entries if necessary
         iLimitParts += 4096 'we increase the allocation every N parts         
         var pNew = cptr(DATFile ptr , reallocate( pT , PartsToBytes(iLimitParts+1) ))
         if pNew=NULL then 
            puts "Failed to allocate memory to load file"
            iFailed = 1 : exit do 'gives up
         end if
         if pT=NULL then 'first allocation
            pT = pNew
            iFilenameOffset = len(g_sFilenames)
            g_sFilenames += chr(255)+mkl(iModelIndex)+chr(0)+lcase(sFilename)+chr(0)
            pNew->iModelIndex = iModelIndex
            pNew->iShadowCount = 0
            pNew->pData = NULL
            pNew->paShadow = NULL
            with pNew->tSize
               .xMin = fUnused : .xMax = fUnused
               .yMin = fUnused : .yMax = fUnused
               .zMin = fUnused : .zMax = fUnused
            end with
            'clear pNew->tInfo , 0 , sizeof(pNew->tInfo)
         end if
         pT = pNew
      end if
      'at this point we should assume we are at the begin of a line so we get a line type
      iResu = ReadInt( pFile , iType )
      if iResu=0 then 'empty line
         NextLine() : continue do 'so let's get the next one         
      end if
      CheckError( "Syntax" ) 'failed to read the line type integer?
      pFile += iResu 'advancing to the next component
      
      'all types except comments/meta (0) have color as second parameter, so let's read it
      if iType<>0 then
         iResu = ReadInt( pFile , iColour )
         CheckError( "Expected colour as second parameter" , " " ) 'failed to read the line type integer?
         pt->tParts(iLastPart).wColour = iColour 'set the color to current part
         pt->tParts(iLastPart).bType = iType
         pFile += iResu 'advancing to the next component
      end if
      
      #macro NextFloat( _var , _description , _separator... )            
         iResu = ReadFloat( pFile , _var )
         'print _description & " = " & _var
         CheckError( "Expected " _description " parameter" , _separator ) 'failed to read the line type float?
         pFile += iResu
      #endmacro
                  
      select case iType 'which line type is it?      
      case 0 'ignore if comment OR empty line and advance to next line        
         dim as string sComment         
         iResu = ReadToken( pFile , sComment )
         'print sComment;
         if ucase(sComment) = "BFC" then            
            pFile += iResu
            iResu = ReadToken( pFile , sComment )
            'puts(sComment)
         elseif ucase(sComment) = "FILE" then            
            dim as string sFile
            pFile += iResu
            ReadFilename( pFile , sFile )
            'print sFile
            pFile += iResu            
            'go to start of next line and recursively call the model load function
            NextLine()
            'is this submodel already referenced? if so then grab it's index
            
            if iLastPart = 0 andalso RecursionLevel=1 then 'ignore naming alias
               NextLine() : continue do
            end if
            
            var sFileL = lcase(sFile)+chr(0), iIndex = -1 'default to new index
            var iOffset = instr(g_sFilenames,chr(0)+sFileL)
            
            #if 0
               if iLastPart = 0 andalso RecursionLevel=1 then 'no parts were added so this 
                  pt->tParts(iLastPart).wColour = 16 'inherit color
                  pt->tParts(iLastPart).bType = 1 'subfile
                  with pt->tParts(iLastPart)._1                  
                     .fX = 0 : .fY = 0 : .fZ = 0
                     .fA = 1 : .fB = 0 : .fC = 0
                     .fD = 0 : .fE = 1 : .fF = 0
                     .fG = 0 : .fH = 0 : .fI = 0 'ident matrix                   
                     .lModelIndex = g_ModelCount 'so the current count is the new model index               
                     g_sFilenames += chr(255)+mkl(g_ModelCount)+chr(0)+sFileL 'add the index to it along the lowercase name to loaded list                                 
                     redim preserve g_tModels( g_ModelCount ) : g_ModelCount += 1
                  end with                   
                  iLastPart += 1
               end if
            #endif
            
            'print sFilename, iLineNum & " lines and " & iLastPart & " parts were read Rec: " & RecursionLevel
            'print "submodel: '"+lcase(sFile)+"'",iOffset
            if iOffset > 4 then 'file already indexed
               'so get index directly from  an ulong stored in the string
               iIndex = *cptr(ulong ptr,strptr(g_sFilenames)+iOffset-(1+sizeof(ulong)))
               'ok but so, this submodel then is on the loadlist, we must remove it from that list
               iOffset = instr(lcase(g_sFilesToLoad),chr(0)+lcase(sFile)+chr(0)) '"\0previousname\0name\0nextname\0"
               if iOffset = 0 then print "/!\ INTERNAL ERROR: forwarded entry not found at the 'To Load List' /!\"
               g_sFilesToLoad = left(g_sFilesToLoad,iOffset)+mid(g_sFilesToLoad,iOffset+len(sFile)+2)
            end if
            LoadModel( pFile , sFile , iIndex )            
            exit do 'from this point is a different file, so we can stop parsing it here
         else
            ReadFilename( pFile , sComment )
            'print sComment            
            pFile += iResu
         end if         
         NextLine() : continue do
      case 1 'line type 1 (ldraw part) '1 <colour> x y z a b c d e f g h i <file>                  
         with pt->tParts(iLastPart)._1            
            NextFloat( .fX , "X (float) as second"     , " " )
            NextFloat( .fY , "Y (float) as third"      , " " )
            NextFloat( .fZ , "Z (float) as fourth"     , " " )
            NextFloat( .fA , "A (float) as fifth"      , " " )
            NextFloat( .fB , "B (float) as sixth"      , " " )
            NextFloat( .fC , "C (float) as seventh"    , " " )
            NextFloat( .fD , "D (float) as eighth"     , " " )
            NextFloat( .fE , "E (float) as ninth"      , " " )
            NextFloat( .fF , "F (float) as tenth"      , " " )
            NextFloat( .fG , "G (float) as eleventh"   , " " )
            NextFloat( .fH , "H (float) as twelth"     , " " )
            NextFloat( .fI , "I (float) as thirteenth" , " " )
            '.fY = -.fY : .fH = -.fH
            dim as string sFile
            iResu = ReadFilename( pFile , sFile )             
            CheckError( "Expected filename as fourteenth parameter" ) 'failed to read the line type string?
            pFile += iResu
            var sFileL = lcase(sFile)+chr(0)            
            var iOffset = instr(g_sFilenames,chr(0)+sFileL)
            if iOffset then 'file already indexed               
               'so get index directly from  an ulong stored in the string
               .lModelIndex = *cptr(ulong ptr,strptr(g_sFilenames)+iOffset-(1+sizeof(ulong)))
            else 'file isnt loaded so put it on the load list and on the loaded list
               .lModelIndex = g_ModelCount 'so the current count is the new model index               
               g_sFilenames += chr(255)+mkl(g_ModelCount)+chr(0)+sFileL 'add the index to it along the lowercase name to loaded list
               g_sFilesToLoad += sFile+chr(0)                           'add the real name to the "to load" list                                             
               'print g_sFilesToLoad 'if instr(sFileL,".ldr") then puts("File: " & SFile)
               redim preserve g_tModels( g_ModelCount ) : g_ModelCount += 1
            end if
            iLastPart += 1 'one part added
            'check if it's the end of line before continuing
            CheckEndOfLine()
         end with
      case 2 '2 <colour> x1 y1 z1 x2 y2 z2
         with pt->tParts(iLastPart)._2            
            NextFloat( .fX1 , "X1 (float) as second"     , " " )
            NextFloat( .fY1 , "Y1 (float) as third"      , " " )
            NextFloat( .fZ1 , "Z1 (float) as fourth"     , " " )
            NextFloat( .fX2 , "X2 (float) as fifth"      , " " )
            NextFloat( .fY2 , "Y2 (float) as sixth"      , " " )
            NextFloat( .fZ2 , "Z2 (float) as seventh"    )            
            '.fY1 = -.fY1 : .fY2 = -.fY2
         end with
         iLastPart += 1 'one part added
         'check if it's the end of line before continuing
         CheckEndOfLine()
      case 3 '3 <colour> x1 y1 z1 x2 y2 z2 x3 y3 z3
         with pt->tParts(iLastPart)._3            
            NextFloat( .fX1 , "X1 (float) as second"     , " " )
            NextFloat( .fY1 , "Y1 (float) as third"      , " " )
            NextFloat( .fZ1 , "Z1 (float) as fourth"     , " " )
            NextFloat( .fX2 , "X2 (float) as fifth"      , " " )
            NextFloat( .fY2 , "Y2 (float) as sixth"      , " " )
            NextFloat( .fZ2 , "Z2 (float) as seventh"    , " " )
            NextFloat( .fX3 , "X3 (float) as eighth"     , " " )
            NextFloat( .fY3 , "Y3 (float) as ninth"      , " " )
            NextFloat( .fZ3 , "Z3 (float) as tenth"      )            
            '.fY1 = -.fY1 : .fY2 = -.fY2 : .fY3 = -.fY3
         end with
         iLastPart += 1 'one part added
         'check if it's the end of line before continuing
         CheckEndOfLine()
      case 4 '4 <colour> x1 y1 z1 x2 y2 z2 x3 y3 z3 x4 y4 z4
         with pt->tParts(iLastPart)._4           
            NextFloat( .fX1 , "X1 (float) as second"     , " " )            
            NextFloat( .fY1 , "Y1 (float) as third"      , " " )
            NextFloat( .fZ1 , "Z1 (float) as fourth"     , " " )
            NextFloat( .fX2 , "X2 (float) as fifth"      , " " )
            NextFloat( .fY2 , "Y2 (float) as sixth"      , " " )
            NextFloat( .fZ2 , "Z2 (float) as seventh"    , " " )
            NextFloat( .fX3 , "X3 (float) as eighth"     , " " )
            NextFloat( .fY3 , "Y3 (float) as ninth"      , " " )
            NextFloat( .fZ3 , "Z3 (float) as tenth"      , " " )
            NextFloat( .fX4 , "X4 (float) as eleventh"   , " " )            
            NextFloat( .fY4 , "Y4 (float) as twelth"     , " " )            
            NextFloat( .fZ4 , "Z4 (float) as thirteenth" )
            '.fY1 = -.fY1 : .fY2 = -.fY2 : .fY3 = -.fY3 : .fY4 = -.fY4
         end with
         iLastPart += 1 'one part added
         'check if it's the end of line before continuing
         CheckEndOfLine()
      case 5 '5 <colour> x1 y1 z1 x2 y2 z2 x3 y3 z3 x4 y4 z4
         with pt->tParts(iLastPart)._5
            NextFloat( .fX1 , "X1 (float) as second"     , " " )
            NextFloat( .fY1 , "Y1 (float) as third"      , " " )
            NextFloat( .fZ1 , "Z1 (float) as fourth"     , " " )
            NextFloat( .fX2 , "X2 (float) as fifth"      , " " )
            NextFloat( .fY2 , "Y2 (float) as sixth"      , " " )
            NextFloat( .fZ2 , "Z2 (float) as seventh"    , " " )
            NextFloat( .fX3 , "X3 (float) as eighth"     , " " )
            NextFloat( .fY3 , "Y3 (float) as ninth"      , " " )
            NextFloat( .fZ3 , "Z3 (float) as tenth"      , " " )
            NextFloat( .fX4 , "X4 (float) as eleventh"   , " " )
            NextFloat( .fY4 , "Y4 (float) as twelth"     , " " )
            NextFloat( .fZ4 , "Z4 (float) as thirteenth" )
            '.fY1 = -.fY1 : .fY2 = -.fY2 : .fY3 = -.fY3 : .fY4 = -.fY4
         end with
         iLastPart += 1 'one part added
         'check if it's the end of line before continuing
         CheckEndOfLine()
      case else
         puts "Unknown line"
         NextLine() : continue do
      end select
   loop
   
   'Load Shadow Library information for this part
   LoadShadow( pT , sFilename )   
   
   'g_sFilesToLoad
   RecursionLevel -= 1
   'clean-up
   if iFailed then 'clean-up in case of faillure
      puts("Faillure?"):GiveUp(1)
      if pT then deallocate(pT): pT=NULL 'deallocate previous buffer
   else         
      'print sFilename,iLastPart
      g_tModels(iModelIndex).pModel = pT
      g_tModels(iModelIndex).iFilenameOffset = iFilenameOffset
      pT->iPartCount = iLastPart
      pT = reallocate( pT , PartsToBytes(pT->iPartCount) )
      iTotalLines += iLineNum : iTotalParts += pT->iPartCount
      if RecursionLevel=0 then 'finished loading everything         
         'print "Files List: "+g_sFilenames
         #ifdef DebugLoading
            print "FINISHED LOADING:"
            print iTotalLines & " lines and " & iTotalParts & " parts were read"
         #endif
         'if len(trim(g_sFilesToLoad)) then print "Files Yet to load:"+g_sFilesToLoad
         'split the files to load list, so we load each of the dependencies
         'increase recursion level again, so that it does not show information about dependency files         
         if iLoadDependencies then
            var iStart=2, sFilesToLoad = g_sFilesToLoad : g_sFilesToLoad=chr(0)
            do            
               var iEnd = instr( iStart , sFilesToLoad , chr(0) ) 'end of filename exists?
               if iEnd=0 then exit do 'no? so we loaded everything
               var sFile = mid( sFilesToLoad , iStart , iEnd-iStart ) 'extract filename from list
               iStart = iEnd+1
               var sFullPathFile = sFile
               'if instr(sFile,".ldr") then puts("Dep: " & SFile)
               if FindFile(sFullPathFile) then
                  var sFileL = lcase(sFile)+chr(0), iIndex = -1 'default to new index
                  var iOffset = instr(g_sFilenames,chr(0)+sFileL)
                  iIndex = *cptr(ulong ptr,strptr(g_sFilenames)+iOffset-(1+sizeof(ulong)))
                  dim as string sModel 
                  if LoadFile( sFullPathFile , sModel ) then                     
                     'print sFile,iIndex
                     LoadModel( strptr(sModel) , sFile , iIndex )
                     continue do
                  end if
               end if
               #ifndef IgnoreMissingDependencies
                  print "ERROR: DEPENDENCY NOT FOUND! '"+sFile+"'"
                  print "Model Path: '"+g_sPathList(0)+"'"
               #endif
               GiveUp(1)
            loop
         end if         
         
      end if
   end if
   
   return pT
   
end function

sub FreeModel( byref pPart as DATFile ptr )
   if pPart = 0 then exit sub
   with *pPart      
      if .iModelIndex < 0 then exit sub
      with g_tModels(.iModelIndex)              
         var iPosEnd = instr(.iFilenameOffset+5,g_sFilenames,chr(255))         
         if iPosEnd=0 then 
            cptr(uinteger ptr,@g_sFilenames)[1] = .iFilenameOffset 'crop from end            
         else 'TODO: WORKAROUND: clean the deleted part so it wont be found (need to compact them later)
            memset( strptr(g_sFilenames)+.iFilenameOffset , 0 , (iPosEnd-.iFilenameOffset)-2 )
         end if         
         .iFilenameOffset = - 1 : .pModel = 0
      end with      
      if .paShadow then deallocate(.paShadow) : .paShadow = 0      
      if .pData    then deallocate(.pData)    : .pData    = 0   
      .iModelIndex = -1
   end with   
   Deallocate( pPart ) : pPart = NULL   
end sub   

#define EOL !"\n"

'print LoadModel( strptr(sModel) , "MyModel.ldr" )
'GiveUp(1)

#if 0
   dim as string sModel
   var dTime = timer
   var sFile = "%userprofile%\Desktop\p.mpd"
   LoadFile( sFile , sModel )
   LoadModel( strptr(sModel) , sFile ) '/ virtual file name for sModel which is loaded into memory'/
   dTime = timer-dTime
   for N as long = 0 to ubound(g_tModels)       
       print strptr(g_sFilenames)[g_tModels(N).iFilenameOffset+9]
   next N   
   'print g_sLog
   printf(!"parsed in %1.3f seconds.\n",dTime)

   sleep
#endif