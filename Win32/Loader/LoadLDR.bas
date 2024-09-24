#cmdline "-gen gcc -O 3"
#include "crt.bi"
#include "vbcompat.bi"

#define RGBA_R( c ) ( CUInt( c ) Shr 16 And 255 )
#define RGBA_G( c ) ( CUInt( c ) Shr  8 And 255 )
#define RGBA_B( c ) ( CUInt( c )        And 255 )
#define RGBA_A( c ) ( CUInt( c ) Shr 24         )

'#define DebugPrimitive
'#define DebugLoading
'#define IgnoreMissingDependencies

type Matrix4x4
   m(15) as single
end type   

static shared as Matrix4x4 tMatrixStack(1023)
static shared as long g_CurrentMatrix

scope
   dim as Matrix4x4 tIdentityMatrix = ( _
      { 1, 0, 0, 0,  _
        0, 1, 0, 0,  _
        0, 0, 1, 0,  _
        0, 0, 0, 1 } _
   )
   tMatrixStack( 0 ) = tIdentityMatrix
end scope
sub PushAndMultMatrix( pIn as const single ptr )
   var pCur = cast(single ptr,@tMatrixStack(g_CurrentMatrix))
   g_CurrentMatrix += 1
   if g_CurrentMatrix > 1023 then
      puts("MATRIX STACK OVERFLOW!!!!")
      sleep : system
   end if
   var pOut = cast(single ptr,@tMatrixStack(g_CurrentMatrix))
      
   for row as long = 0 to 3
      for col as long = 0 to 3
         pOut[row+col*4] = _            
            pCur[row + 0 * 4] * piN[0 + col * 4] + _
            pCur[row + 1 * 4] * piN[1 + col * 4] + _
            pCur[row + 2 * 4] * piN[2 + col * 4] + _
            pCur[row + 3 * 4] * piN[3 + col * 4]
      next col
   next row
   
end sub
sub PopMatrix()
   if g_CurrentMatrix>0 then g_CurrentMatrix -= 1
end sub   
sub MultiplyMatrixVector( pVec as single ptr )
   dim as single fX = pVec[0] , fY = pVec[1] , fZ = pVec[2]
   with tMatrixStack(g_CurrentMatrix)    
      pVec[0] = .m(0) * fX + .m(4) * fY + .m( 8) * fZ + .m(12)
      pVec[1] = .m(1) * fX + .m(5) * fY + .m( 9) * fZ + .m(13)
      pVec[2] = .m(2) * fX + .m(6) * fY + .m(10) * fZ + .m(14)
   end with
end sub


const cScale = 1'/20

#include "Modules\Structs.bas"
#include "Modules\PartPaths.bas"
#include "ViewGL.bas"
#include "Colours.bas"

'dim shared as string g_sLog
dim shared as string g_sFilenames,g_sFilesToLoad
dim shared as long g_ModelCount
redim shared as ModelList g_tModels(0)

g_sFilenames = chr(0)
g_sFilesToLoad = chr(0)

#include "Modules\ParserFunctions.bas"

function LoadModel( pFile as ubyte ptr , sFilename as string = "" , iModelIndex as long = -1 , iLoadDependencies as byte = 1 ) as DATFile ptr   
   #macro CheckError(_s , _separator... )
      #if len( #_separator )
        if iResu>0 andalso pFile[iResu] <> asc(_separator) then iResu = -1
      #endif
      if iResu<=0 then
         print _s " error reading '"+sFilename+"' at line " & iLineNum
         sleep : system         
         iFailed = 1 : exit do
      end if
   #endmacro
   #macro CheckEndOfLine()
      while *pFile <> asc(!"\n")
         select case *pFile
         case 0                    : exit do 'last line of file so we're done SUCCESS
         case asc("\r"),9,asc(" ") 'skipping spaces/tabs/CR
         case else
            print " expect end of line in '"+sFilename+"' at line " & iLineNum
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
         var pNew = reallocate( pT , PartsToBytes(iLimitParts+1) )
         if pNew=NULL then 
            print "Failed to allocate memory to load file"
            iFailed = 1 : exit do 'gives up
         end if
         if pT=NULL then 'first allocation
            pT = pNew
            iFilenameOffset = len(g_sFilenames)
            g_sFilenames += chr(255)+mkl(iModelIndex)+chr(0)+lcase(sFilename)+chr(0)
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
         if ucase(sComment) = "FILE" then            
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
         print "Unknown line"
         NextLine() : continue do
      end select
   loop
   
   
   'g_sFilesToLoad
   RecursionLevel -= 1
   'clean-up
   if iFailed then 'clean-up in case of faillure
      puts("Faillure?"):sleep:system
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
               'sleep : system
            loop
         end if         
         
      end if
   end if
   
   return pT
   
end function

#define EOL !"\n"
dim as string sModel = _
"1 4 0 0 0 1 0 0 0 1 0 0 0 1 3024.dat"          EOL _
"1 1 0 8 0 1 0 0 0 1 0 0 0 1 3024.dat"          EOL _
"1 2 0 16 0 1 0 0 0 1 0 0 0 1 3005.dat"         EOL _
"1 2 0 -2 -21 1 0 0 0 1 0 0 0 1 63710p01.dat"

'print LoadModel( strptr(sModel) , "MyModel.ldr" )
'sleep ': system

#if 0
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

'Function to compute the cross product of two vectors
sub crossProduct(v1 as single ptr, v2 as single ptr, result as single ptr)
    result[0] = v1[1] * v2[2] - v1[2] * v2[1]
    result[1] = v1[2] * v2[0] - v1[0] * v2[2]
    result[2] = v1[0] * v2[1] - v1[1] * v2[0]
end sub
'Function to normalize a vector
sub normalize(v  as single ptr)
    dim as single length = sqr(v[0] * v[0] + v[1] * v[1] + v[2] * v[2])
    if (length <> 0.0f) then
        v[0] /= length
        v[1] /= length
        v[2] /= length
    end if
end sub

sub SetLineNormal( byref tLine as LineType2Struct )
   with tLine
      '// Compute direction vector of the line
      dim as single direction(3-1)=any
      direction(0) = .fX2 - .fX1
      direction(1) = .fY2 - .fY1
      direction(2) = .fZ2 - .fZ1
      
      '// Reference vector for cross product (Y-axis, for example)
      dim as single ref(3-1) = {0.0f, 1.0f, 0.0f}
      
      '// Compute the normal using the cross product
      dim as single normal(3-1)
      crossProduct(@direction(0), @ref(0), @normal(0))
      
      '// Normalize the normal
      normalize(@normal(0))
      
      '// Scale the normal for visibility
      const normalScale = 0.5f
      normal(0) *= normalScale
      normal(1) *= normalScale
      normal(2) *= normalScale
       
      glNormal3fv( @normal(0) )
   end with
end sub
sub SetQuadNormal( byRef tQuad as LineType4Struct )
   with tQuad
      dim as single  edge1(3-1)=any, edge2(3-1)=any, normal(3-1)=any
      
      '// Compute edge vectors for one triangle of the quad (v1, v2, v3)
      edge1(0) = .fX2 - .fX1
      edge1(1) = .fY2 - .fY1
      edge1(2) = .fZ2 - .fZ1
      
      edge2(0) = .fX3 - .fX1
      edge2(1) = .fY3 - .fY1
      edge2(2) = .fZ3 - .fZ1
      
      '// Compute normal for the first triangle
      crossProduct(@edge1(0), @edge2(0), @normal(0))
      
      '// Normalize the normal
      normalize(@normal(0))
      
      '// Set normal for the quad
      glNormal3fv( @normal(0) )
   end with
end sub

static shared as single g_zFar
static shared as integer iBorders
sub WalkPart( pPart as DATFile ptr , uCurrentColor as ulong = &h70605040 , uCurrentEdge as ulong = 0 , sIdent as string = "" )
   if uCurrentColor = &h70605040 then uCurrentColor = g_Colours(c_Blue) : uCurrentEdge = g_EdgeColours(c_Blue)
   
   var uEdge = uCurrentEdge
   static as integer iOnce
   #macro CheckZ( _Var ) 
      if abs(.fX##_Var) > g_zFar then g_zFar = abs(.fX##_Var)
      if abs(.fY##_Var) > g_zFar then g_zFar = abs(.fY##_Var)
      if abs(.fZ##_Var) > g_zFar then g_zFar = abs(.fZ##_Var)
   #endmacro
        
   with *pPart      
      'for M as long = 0 to 1
      for N as long = 0 to .iPartCount-1
         dim as ulong uColor = any', uEdge = any
         with .tParts(N)
            #ifdef DebugPrimitive
               printf sIdent+"(" & .bType & ") Color=" & .wColour & " (Current=" & hex(uCurrentColor,8) & ")"
               'sleep
            #endif
                        
            if .wColour = c_Main_Colour then 'inherit
               uColor = uCurrentColor ': uEdge = uCurrentEdge
            elseif .wColour <> c_Edge_Colour then
               if .wColour > ubound(g_Colours) then
                  puts("Bad Color: " & .wColour)
               end if
               uColor = g_Colours(.wColour)
               'uEdge  = g_EdgeColours(.wColour)
               'uEdge = ((uColor and &hFEFEFE) shr 1) or (uColor and &hFF000000)
               'if .wColour = c_Trans_Yellow then
               '   puts "Trans Yellow"
               'end if
            end if
            
            
            'if M=0 then
            '   if .bType=1 or .bType=5 then continue for
            'else
            '   if .bType<>2 and .bType<>5 then continue for
            'end if
            select case .bType
            case 1
               'uEdge = rgb(rnd*255,rnd*255,rnd*255)
               uEdge = ((uColor and &hFEFEFE) shr 1) or (uColor and &hFF000000)
               'g_EdgeColours(.wColour)
               var T1 = ._1
               with T1
                  var pSubPart = g_tModels(.lModelIndex).pModel
                  var sName = *cptr(zstring ptr,strptr(g_sFilenames)+g_tModels(.lModelIndex).iFilenameOffset+6)
                  #ifdef DebugPrimitive
                  Puts _
                     " fX:" & .fX & " fY:" & .fY & " fZ:" & .fZ & _
                     " fA:" & .fA & " fB:" & .fB & " fC:" & .fC & _
                     " fD:" & .fD & " fE:" & .fE & " fF:" & .fF & _
                     " fG:" & .fG & " fH:" & .fH & " fI:" & .fI & " '" & sName & "'"                     
                  #endif
                                    
                  'MultiplyMatrixVector( @.fX ) 
               
                  dim as single fMatrix(15) = { _
                    .fA*cScale , .fD*cScale , .fG*cScale , 0 , _
                    .fB*cScale , .fE*cScale , .fH*cScale , 0 , _
                    .fC*cScale , .fF*cScale , .fI*cScale , 0 , _
                    .fX*cScale , .fY*cScale , .fZ*cScale , 1 }                                      
                  PushAndMultMatrix( @fMatrix(0) ) 
                  'glPushMatrix() : glMultMatrixf( @fMatrix(0) )
                  WalkPart( pSubPart , uColor , uEdge , "   "+sIdent )
                  PopMatrix() 
                  'glPopMatrix()
               end with               
            case 2               
               if iBorders=0 then continue for
               'glPushMatrix() : glMultMatrixf( @fMatrix(0) )
               
               var T2 = ._2
               
               MultiplyMatrixVector( @T2.fX1 )
               MultiplyMatrixVector( @T2.fX2 )
               SetLineNormal( T2 )
               
               with T2
                  #ifdef DebugPrimitive
                  puts _
                     " fX1:" & .fX1 & " fY1:" & .fY1 & " fZ1:" & .fZ1 & _
                     " fX2:" & .fX2 & " fY2:" & .fY2 & " fZ2:" & .fZ2
                  #endif
                  CheckZ(1) 
                  CheckZ(2)                                    
                  glColor4ubv( cast(ubyte ptr,@uEdge) )
                                    
                  glBegin GL_LINES                  
                  glVertex3f .fX1*cScale , .FY1*cScale , .fZ1*cScale
                  glVertex3f .fX2*cScale , .FY2*cScale , .fZ2*cScale
                  glEnd
               end with
            case 3
               if iBorders then continue for
               var T3 = ._3
               MultiplyMatrixVector( @T3.fX1 ) 
               MultiplyMatrixVector( @T3.fX2 )
               MultiplyMatrixVector( @T3.fX3 )
               with T3
                  #ifdef DebugPrimitive
                     puts _
                        " fX1:" & .fX1 & " fY1:" & .fY1 & " fZ1:" & .fZ1 & _
                        " fX2:" & .fX2 & " fY2:" & .fY2 & " fZ2:" & .fZ2 & _
                        " fX3:" & .fX3 & " fY3:" & .fY3 & " fZ3:" & .fZ3
                  #endif
                  CheckZ(1) 
                  CheckZ(2)
                  CheckZ(3)                   
                  glColor4ubv( cast(ubyte ptr,@uColor) )                  
                  
                  'normalize triangle
                  dim as single edge1(3-1) = any, edge2(3-1) = any, normal(3-1) = any

                  'Compute edge vectors
                  edge1(0) = .fX2 - .fX1
                  edge1(1) = .fY2 - .fY1
                  edge1(2) = .fZ2 - .fZ1
               
                  edge2(0) = .fX3 - .fX1
                  edge2(1) = .fY3 - .fY1
                  edge2(2) = .fZ3 - .fZ1
               
                  '// Compute normal
                  crossProduct(@edge1(0), @edge2(0), @normal(0))
               
                  '// Normalize the normal vector
                  normalize(@normal(0))
               
                  '// Set normal for the triangle
                  'glNormal3f(normal(0), normal(1), normal(2));
                  glNormal3fv( @normal(0) )
                  
                  glBegin GL_TRIANGLES                  
                  'glNormal3f( rnd , rnd , rnd )
                  glVertex3f .fX1*cScale , .FY1*cScale , .fZ1*cScale 
                  'glNormal3f( rnd , rnd , rnd )
                  glVertex3f .fX2*cScale , .FY2*cScale , .fZ2*cScale
                  'glNormal3f( rnd , rnd , rnd )
                  glVertex3f .fX3*cScale, .FY3*cScale , .fZ3*cScale 
                  glEnd
               end with
            case 4               
               if iBorders then continue for
               var T4 = ._4
               MultiplyMatrixVector( @T4.fX1 ) 
               MultiplyMatrixVector( @T4.fX2 )
               MultiplyMatrixVector( @T4.fX3 )
               MultiplyMatrixVector( @T4.fX4 )
               SetQuadNormal( T4 )
               with T4
                  #ifdef DebugPrimitive
                     puts _
                        " fX1:" & .fX1 & " fY1:" & .fY1 & " fZ1:" & .fZ1 & _
                        " fX2:" & .fX2 & " fY2:" & .fY2 & " fZ2:" & .fZ2 & _
                        " fX3:" & .fX3 & " fY3:" & .fY3 & " fZ3:" & .fZ3 & _
                        " fX4:" & .fX4 & " fY4:" & .fY4 & " fZ4:" & .fZ4
                  #endif
                  CheckZ(1) 
                  CheckZ(2)
                  CheckZ(3) 
                  CheckZ(4)
                  glColor4ubv( cast(ubyte ptr,@uColor) )                  
                  glBegin GL_QUADS
                  glVertex3f .fX1*cScale , .FY1*cScale , .fZ1*cScale 
                  glVertex3f .fX2*cScale , .FY2*cScale , .fZ2*cScale
                  glVertex3f .fX3*cScale , .FY3*cScale , .fZ3*cScale 
                  glVertex3f .fX4*cScale , .FY4*cScale , .fZ4*cScale
                  glEnd
               end with
            case 5
               continue for
               if iBorders=0 then continue for
               var T5 = ._5
               MultiplyMatrixVector( @T5.fX1 ) 
               MultiplyMatrixVector( @T5.fX2 )
               SetLineNormal( *cptr( typeof(._2) ptr , @T5 ) ) 'just need the line
               with ._5
                  #ifdef DebugPrimitive
                     puts _
                        " fX1:" & .fX1 & " fY1:" & .fY1 & " fZ1:" & .fZ1 & _
                        " fX2:" & .fX2 & " fY2:" & .fY2 & " fZ2:" & .fZ2 & _
                        " fXA:" & .fX3 & " fYA:" & .fY3 & " fZA:" & .fZ3 & _
                        " fXB:" & .fX4 & " fYB:" & .fY4 & " fZB:" & .fZ4
                  #endif
                  CheckZ(1) 
                  CheckZ(2)                  
                  glColor4ubv( cast(ubyte ptr,@uEdge) )
                  'glColor3f( 0 , 1 , 0 )
                  
                  glBegin GL_LINES                  
                  glVertex3f .fX1*cScale , .FY1*cScale , .fZ1*cScale
                  glVertex3f .fX2*cScale , .FY2*cScale , .fZ2*cScale
                  glEnd                  
               end with
            end select
         end with
      next N      
      'next M
      iOnce = 1
   end with   
end sub

'3044a 'Regx for good files = ^1.*\.dat
'var sFile = "%userprofile%\Desktop\LDCAD\LDraw\parts\3044a.dat"
'var sFile = "%userprofile%\Desktop\LDCAD\LDraw\p\t01i3261.dat"
'var sFile = "%userprofile%\Desktop\LDCAD\LDraw\deleted\official\168315a.dat"
'var sFile = "%userprofile%\Desktop\LDCAD\LDraw\parts\3001.dat"
'var sFile = "%userprofile%\Desktop\LDCAD\LDraw\p\stud4.dat"
'var sFile = "%userprofile%\Desktop\LDCAD\LDraw\p\4-4edge.dat"

var sFile = "%userprofile%\Desktop\LDCAD\LDraw\models\car.ldr"
'var sFile = "%userprofile%\Desktop\LDCAD\examples\5580.mpd"

'var sFile = "%userprofile%\Desktop\LDCAD\LDraw\digital-bricks.de parts not in LDRAW\12892.dat" 'working
'var sFile = "%userprofile%\Desktop\LDCAD\LDraw\digital-bricks.de parts not in LDRAW\12894.dat" 'working
'var sFile = "%userprofile%\Desktop\LDCAD\LDraw\digital-bricks.de parts not in LDRAW\12895.dat" 'working
'var sFile = "%userprofile%\Desktop\LDCAD\LDraw\digital-bricks.de parts not in LDRAW\12887.dat" 'working
'var sFile = "%userprofile%\Desktop\LDCAD\LDraw\digital-bricks.de parts not in LDRAW\12893.dat" 'working
'var sFile = "%userprofile%\Desktop\LDCAD\LDraw\digital-bricks.de parts not in LDRAW\12898.dat" 'working
'var sFile = "%userprofile%\Desktop\LDCAD\LDraw\digital-bricks.de parts not in LDRAW\13037.dat" 'working
'var sFile = "%userprofile%\Desktop\LDCAD\LDraw\digital-bricks.de parts not in LDRAW\12899.dat" 'working
'var sFile = "%userprofile%\Desktop\LDCAD\LDraw\digital-bricks.de parts not in LDRAW\13194.dat" 'working
'var sFile = "%userprofile%\Desktop\LDCAD\LDraw\digital-bricks.de parts not in LDRAW\13195.dat" 'working
'var sFile = "%userprofile%\Desktop\LDCAD\LDraw\digital-bricks.de parts not in LDRAW\13249.dat" 'working
'var sFile = "%userprofile%\Desktop\LDCAD\LDraw\digital-bricks.de parts not in LDRAW\13197.dat"

if LoadFile( sFile , sModel ) = 0 then
   print "Failed to load '"+sFile+"'"
   sleep : system
end if
var pModel = LoadModel( strptr(sModel) , sFile ) '/ virtual file name for sModel which is loaded into memory'/
InitOpenGL()

dim as single fRotationX = 120 , fRotationY = 20
dim as single fPositionX , fPositionY , fZoom = -3
dim as long iWheel , iPrevWheel

glDisable( GL_LIGHTING )

var iModel = glGenLists( 1 )
glNewList( iModel ,  GL_COMPILE ) 'GL_COMPILE_AND_EXECUTE
iBorders = 0 : WalkPart( pModel )
iBorders = 1 : WalkPart( pModel )
glEndList()

dim as double dRot = timer
dim as boolean bLeftPressed,bRightPressed,bWheelPressed
dim as long iFps

do
   
   glClear GL_COLOR_BUFFER_BIT OR GL_DEPTH_BUFFER_BIT      
   glLoadIdentity()
   glScalef(1/-20, 1.0/-20, 1/20 )
   
   '// Set light position (0, 0, 0)
   dim as GLfloat lightPos(...) = {0,0,0, 1.0f}'; // (x, y, z, w), w=1 for positional light
   glLightfv(GL_LIGHT0, GL_POSITION, @lightPos(0))
   
   glTranslatef -fPositionX , fPositionY , g_zFar*fZoom '/-5)
   glRotatef fRotationY , -1.0 , 0.0 , 0
   glRotatef fRotationX , 0   , -1.0 , 0
      
   glCallList(	iModel )
   'WalkPart( pModel )
   'glutSolidTeapot(1.0)
   
   Dim e as fb.EVENT = any
   while (ScreenEvent(@e))
      Select Case e.type
      Case fb.EVENT_MOUSE_MOVE
         if bLeftPressed  then fRotationX += e.dx : fRotationY += e.dy
         if bRightPressed then fPositionX += e.dx : fPositionY += e.dy
      case fb.EVENT_MOUSE_WHEEL
         iWheel = e.z-iPrevWheel
         fZoom = -3+(iWheel/2)
      case fb.EVENT_MOUSE_BUTTON_PRESS
         if e.button = fb.BUTTON_MIDDLE then 
            iPrevWheel = iWheel
            fZoom = -3
         end if
         if e.button = fb.BUTTON_LEFT   then bLeftPressed  = true
         if e.button = fb.BUTTON_RIGHT  then bRightPressed = true
      case fb.EVENT_MOUSE_BUTTON_RELEASE
         if e.button = fb.BUTTON_LEFT   then bLeftPressed  = false
         if e.button = fb.BUTTON_RIGHT  then bRightPressed = false      
      end select
   wend
               
   flip   
   static as double dFps : iFps += 1   
   if abs(timer-dFps)>1 then
      dFps = timer      
      'WindowTitle("Fps: " & cint(1/(timer-dRot)))
      WindowTitle("Fps: " & iFps): iFps = 0
      'if dFps=0 then dFps = (timer-dRot) else dFps = (dFps+(timer-dRot))/2
   else
      sleep 1
   end if
   
   'WindowTitle("Fps: " & cint(1/(timer-dRot)))
   
   'fRotation -= (timer-dRot)*30
   dRot = timer
   
loop until multikey(fb.SC_ESCAPE)
sleep
