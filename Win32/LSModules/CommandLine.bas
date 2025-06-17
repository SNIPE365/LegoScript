#include "file.bi"

redim shared as string sOpenFiles(0)

sub PrintColoredOutput( sColoredText as string )
   dim as long iTag = instr( sColoredText , chr(2) )
   if iTag = 0 then iTag = len(sColoredText)+1
   print left(sColoredText,iTag-1);
   dim as CHARFORMAT tFmt = (sizeof(CHARFORMAT))
   while iTag < len(sColoredtext)
      var iC = sColoredText[iTag] : iTag += 2
      SendMessage( CTL(wcOutput) , EM_SETSEL , -1 , -1 )      
      var iNewTag = instr( iTag , sColoredText , chr(2) )
      if iNewTag = 0 then iNewTag = len(sColoredText)+1      
      var sText = mid(sColoredText,iTag,iNewTag-iTag)
      color iC : print sText : color 7
      iTag = iNewTag
   wend
end sub 

sub ShowHelp() 
   #define _errorf(_Parms...) fprintf(stderr,_Parms)
   #define _GiveUp(_N) end _N
   var sHelp = command(0)
   var iPos = instrrev( sHelp , "\" ), iPos2 = instrrev( sHelp , "/" )
   if iPos2 > iPos then iPos = iPos2
   if iPos then sHelp = mid(sHelp,iPos+1)
   #define CRLF !"\r\n"
   sHelp = _
      "usage: " CRLF + _
      sHelp+" [GUI options] [input files] [-c console options] [-o output file]" CRLF _
      CRLF _
      "using '-' or 'stdin'/'stdout' can be used instead of input/output files will to use console" CRLF _
      CRLF _
      "GUI Options:" CRLF _            
      "  -?     show help :)" CRLF _
      "  -c     use console mode (all options after this are only for console)" CRLF _
      CRLF _
      "CONSOLE Options:" CRLF _
      "  -y     automatically overwrite output file" CRLF _
      "  -f     output filename is generated from first (non empty) line of first input" CRLF _
      "  -o     select output filename" CRLF _
      "  -v     show output in the model viewer" CRLF
   _errorf( sHelp ) : _GiveUp(0)
   'CRLF CRLF CRLF CRLF CRLF CRLF CRLF CRLF CRLF CRLF CRLF CRLF CRLF CRLF CRLF CRLF CRLF _
   'CRLF CRLF CRLF CRLF CRLF CRLF CRLF CRLF CRLF CRLF CRLF CRLF CRLF CRLF CRLF CRLF CRLF 
   'Messagebox( null , sHelp , "LegoScript" , MB_ICONINFORMATION or MB_SYSTEMMODAL ) : _GiveUp(0)
end sub
sub ConsoleOnly( bIsConsole as boolean , sParm as string )
   if bIsConsole then exit sub
   #define _errorf(_Parms...) fprintf(stderr,_Parms)
   #define _GiveUp(_N) end _N
   color 12: _Errorf( "'"+sParm+"' must come after the '-c' option "): color 7
   _GiveUp(1)
end sub

function ParseCmdLine() as long
   #define _errorf(_Parms...) fprintf(stderr,_Parms)
   #define _GiveUp(_N) end _N
   #define _ConsoleOnly ConsoleOnly( bUseConsole , sParm )
   dim as long iN = 1
   dim as boolean bAutoFile = false , bViewOutput = false , bOverwriteOutput = false
   dim as boolean bUseConsole = false , bDumpToConsole = false , bTempOutput = true
   dim as boolean bInteractive = false
   dim as string sOutputFile
   do
      var sParm = command(iN) : iN += 1
      if len(sParm)=0 then exit do
      if len(sParm)>1 andalso sParm[0] = asc("-") then 'options
         select case sParm[1]         
         case asc("h"),asc("?"): ShowHelp()
         case asc("c"),asc("C"): bUseConsole = true
         case asc("f"),asc("F"): _ConsoleOnly : bAutoFile = true : bTempOutput = false            
         case asc("v"),asc("V"): _ConsoleOnly : bViewOutput = true
         case asc("y"),asc("Y"): _ConsoleOnly : bOverwriteOutput = true
         case asc("o"),asc("O") '_ConsoleOnly : output file
            _ConsoleOnly
            var bPrevOutput = len(sOutputFile)<>0
            sOutputFile = command(iN): iN += 1 : bTempOutput = false          
            if sOutputFile="-" orelse lcase(sOutputFile)="stdout" then
               sOutputFile = "" : bDumpToConsole = true
            elseif bPrevOutput then
               color 12: _errorf("only one output file is allowed")
               color 7: _GiveUp(1)            
            elseif instr(sOutputFile,"*") orelse instr(sOutputFile,"?") then
               color 12: _errorf("wildcards not supported for output file")
               color 7: _GiveUp(1)
            elseif len(sOutputFile)=0 orelse sOutputFile[0] = asc("-") then
               color 12: _errorf("Excepted output filename after '"+sParm+"'")
               color 7 : _GiveUp(1)
            end if
         case else
            color 12: _errorf("Invalid option: '%s'\n",sParm): color 7: _GiveUp(1)
         end select
      else
         var iFile = ubound(sOpenFiles)+1
         redim preserve sOpenFiles( iFile )
         sOpenFiles(iFile) = sParm
      end if
   loop
   
   if bUseConsole=false then return 0
   if bAutoFile andalso len(sOutputFile)<>0 then
      color 12: _errorf("when '-f' is used no output filename is allowed")
      color 7 : _GiveUp(1)
   end if   
   if ubound(sOpenFiles)=0 then bInteractive = true
      'color 12: _errorf("console requires at least one input file")
      'color 7 : _GiveUp(1)
   'end if
   
   var isOutTTY = _isatty( _fileno(stdout) ) , isInTTY = _isatty( _fileno(stdin) )
   dim as string sText,sScript
   for iN = 1 to iif(bInteractive,1,ubound(sOpenFiles))
      var sInput = sOpenFiles(1)
      
      if bInteractive = false then
         if sInput = "-" orelse lcase(sinput)="stdin" then
            sInput = ""
            do
               var iChar = getchar() 
               if iChar <=0 orelse iChar=26 then exit do
               sScript += chr(iChar)
            loop
            if len(sScript)=0 then
               color 12: _Errorf(!"Empty input from console")
               color 7: _GiveUp(1)
            end if
         else            
            var f = freefile()
            if open(sInput for binary access read as #f) then
               color 12: _Errorf(!"Failed to open '%s'\n",sInput)
               color 7: _GiveUp(2)
            end if         
            sScript = space(lof(f))
            get #f,,sScript : close #f
            if len(sScript)=0 then
               color 14: _Errorf(!"Empty input file ignored '%s'",sInput)
               color 7: continue for
            end if
         end if         
      end if
      
      #if 0
         if bTempOutput then
            var sTemp = date+time+".ldr" : sOutputFile = sTemp
            for N as long = 0 to len(sTemp)-1
               select case sTemp[N]
               case asc("a") to asc("z"),asc("A") to asc("Z"),asc("0") to asc("9"), asc("."): rem VALID
               case else : sOutputFile[N] = asc("_")
               end select
            next N
         end if
      #endif
      
      #macro CheckFileExists(_Cond)
         if cint(_Cond) andalso cint(FileExists(sOutputFile)) andalso cint(bOverwriteOutput=false) then         
            if isInTTY then color 14: else color 12 
            _Errorf(!"output file '%s' already exists. ",sOutputFile): color 7
            if isInTTY then
               do
                  _Errorf(!"Overwrite (Y/N)? ")
                  select case getkey()
                  case asc("y"),asc("Y"): _Errorf(!" YES\n"): exit do
                  case asc("n"),asc("N"): _Errorf(!" NO\n"): continue for
                  end select
                  _errorf(!"\n")
               loop            
            else
               _GiveUp(1)
            end if
         end if
      #endmacro
      CheckFileExists((bTempOutput=false andalso bAutoFile=false))
      
      if bInteractive then         
         cls : g_StandaloneQuery = true : sScript = ""
         InitSearchWindow()
         QueryText(sScript) : sScript = trim(sScript)
         if len(sScript)=0 then
            color 12: _Errorf(!"Empty input from console")
            color 7: _GiveUp(1)
         end if        
         
         if len(sScript)=0 then
            color 12: _Errorf(!"Empty input from console")
            color 7: _GiveUp(1)
         end if         
      end if
      
      if bAutoFile then            
         sOutputFile = trim( sScript , any !"\r\n" )+".ldr"
         for N as long = 0 to len(sOutputFile)-1
            select case sOutputFile[N]
            case asc("*"),asc(""""),asc("/"),asc("\"),asc("<"),asc(">"),asc(":"),asc("|"),asc("?")
              sOutputFile[N] = asc("-")
            case is <32 , is > 127
               sOutputFile[N] = asc("_")
            end select
         next N
         CheckFileExists(true)
      end if         
      
      dim as string sModel, sError
      sModel = LegoScriptToLDraw(sScript, sError, sInput)
      if len(sError) then 
         if isOutTTY then
            PrintColoredOutput(sError)
         else
            _Errorf("%s",sError)
         end if
         _GiveUp(1)
      end if
      if bDumpToConsole then color 3: print sModel: color 7
      if len(sOutputFile) then
         var f = freefile()
         if open(sOutputFile for output as #f) then
            _Errorf("Failed to open output file '%s'",sOutputfile)
            _GiveUp(1)
         end if
         print #f,sModel
         close #f
      end if
      if bViewOutput andalso len(sModel)<>0 then   
         var sParms = """"+sModel+""""
         puts("-----------------")         
         exec(exepath()+"\Loader\ViewModel.exe",sParms)         
         puts("-----------------")
         end 0
      else
         if IsInTTY<>0 andalso bInteractive then sleep
         end 0
      end if
   next iN   
   end 0
end function
