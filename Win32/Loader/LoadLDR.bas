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

const cScale = 1'/20

#include "Include\Structs.bas"
#include "Include\PartPaths.bas"

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

'print LoadModel( strptr(sModel) , "MyModel.ldr" )
'sleep ': system

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