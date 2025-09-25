#include "file.bi"

redim shared as string g_sOpenFiles(0)

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
      "  -ci    use interactive console mode (automatically if no input file is given)" CRLF _
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

#include "crt.bi"

#ifdef __FB_WIN32__
   #undef _isatty
   function _isatty( iFileNum as long ) as bool
      dim as DWORD dwMode
      var hFile = cast(HANDLE,_get_osfhandle(iFileNum))
      if hFile=INVALID_HANDLE_VALUE then return 0
      return GetConsoleMode( hFile , @dwMode )
   end function
#endif

function LoadScriptFileAsArray( sFile as string , sOutArray() as string ) as boolean
   
   var f = freefile(), iResu = open(sFile for binary access read as #f)
   if iResu orelse (lof(f) > (64*1024*1024)) then
      if iResu=0 then close(f) 
      return false
   end if
   
   redim sOutArray(63)
   dim as string sData = space(lof(f)), sRow = space(512)
   dim as long iCurRow = 0   
   get #f,,sData : close #f
      
   dim as long iOut=0, iLen = len(sData)
   dim as boolean bDoneRow
   for iN as long = 0 to iLen
      dim as ubyte iChar = sData[iN]      
      select case iChar
      case 0
         if iN >= iLen then bDoneRow = true
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
            sRow[iOut] = iChar : iOut += 1            
            do
               iN += 1 : if iN >= iLen then bDoneRow = true : iN += 1 : exit do
               iChar = sData[iN]
               select case iChar
               case 13,9,asc(" "),asc(";") 'ignore blanks
               case 10
                  bDoneRow = true : exit do                  
               case else
                  iN -= 1 : bDoneRow = true : exit do
               end select
            loop
         end if
      case 13 : continue for
      case 10 : bDoneRow = true
      end select
      if bDoneRow then         
         sOutArray(iCurRow) = left(sRow,iOut) 
         'printf(!"'%s'\n",sOutArray(iCurRow))
         iOut = 0 : iCurRow += 1 : bDoneRow = false
         if iN >= iLen then 
            redim preserve sOutArray( iCurRow-1 )            
         elseif iCurRow > ubound(sOutArray) then
            redim preserve sOutArray( iCurRow+63 )
         end if
         continue for
      end if      
      sRow[iOut] = iChar : iOut += 1
   next iN      
   return true
end function
function SaveScriptFileFromArray( sFile as string , sInArray() as string , iRows as long ) as boolean
   
   var f = freefile(), iResu = open(sFile for binary access write as #f)
   if iResu then return false   
   
   for N as long = 0 to iRows-1
      if N=(iRows-1) then 
         print #f,sInArray(N);
      else
         print #f,sInArray(N)
      end if
   next N
   close #f
   
   return true
   
end function


function ConsoleEdit( sFiles() as string ) as long         
   dim as ConEditContext tCtx
   InitEditContext( tCtx )
   redim as string sCode(0)
   dim as byte bUnsaved, bUnnamed 
   if ubound(sFiles) >= 1 then
      LoadScriptFileAsArray( sFiles(1) , sCode() )
   else
      sFiles(1) = "Unnamed.ls": bUnnamed = 1
   end if   
   with tCtx
      .iCodeLines = ubound(sCode)+1
      .iViewWid -= 6 : .iViewHei = .ConHei-4
      .iCol += 6 : .iStartLine = 0 : .iCurLine = 0
      .bUpdateCaption = true: .bUpdateScroll = true : .bUpdateRowsBar = true      
      do
         'update whole screen
         if .bUpdateCaption then
            .bUpdateCaption=false
            var sCaption = "File: "+sFiles(1)
            locate 1,1,0 : color 14,1 : print sCaption;
            print space(.ConWid-len(sCaption));: color 7,0
         end if
         
         if .bUpdateScroll then            
            locate ,,0
            for N as long = 0 to .iViewHei-1
               var iLine=.iStartLine+N
               if iLine >= .iCodeLines then 
                  locate 2+N,1 : print space(.iViewWid+5);
               else
                  if .bUpdateRowsBar then locate 2+N, 1 : color 0,7 : print right("    " & 1+iLine,5);
                  color 7,0 : locate 2+N,.iCol : print left(mid(sCode(iLine),1+.iStart)+space(.ConWid),.iViewWid);
               end if
            next N
            .bUpdateScroll = false : .bUpdateRowsBar = false
         end if
                           
         .iLin = 2+(.iCurLine-.iStartLine)         
         .sText = sCode(.iCurLine)
         var iCode = RowEdit(tCtx)
         #define sqCtx *cptr(SearchQueryContext ptr,@tCtx)
         if HandleCasing( .sText , sqCtx ) then
            .bUpdateScroll = true : .bChanged = 1
         end if
         if sCode(.iCurLine) <> .sText then 
            bUnsaved = 1 : sCode(.iCurLine) = .sText
         end if
         
         #define _ctrl(_K) (1+asc(#_K)-asc("A"))
         
         select case iCode
         case 8                'move to the end of previous line and proceed as DELETE (falltrough)
            if .iCurLine < 1 then continue do
            .iCurLine -= 1 : .iCur = len(sCode(.iCurLine))
            goto _FALLTROUGH_DELETE_
         case -fb.SC_DELETE    'concat two lines removing one line
            _FALLTROUGH_DELETE_:                        
            if .iCodeLines = 1 then sCode(0)="" : continue do
            if (.iCurLine+1) >= .iCodeLines then continue do 'andalso .iCur then continue do
            .iCodeLines -= 1    
            sCode(.iCurLine) += sCode(.iCurLine+1)
            for N as long = .iCurLine+1 to .iCodeLines-1
               sCode(N) = sCode(N+1) 
               '*cptr(fbStr ptr,@sCode(N)) = *cptr(fbStr ptr,@sCode(N+1))
            next N          
            'clear *(@sCode(.iCodeLines)),0,sizeof(fbStr) 'sCode(.iCodeLines)=""
            'if (ubound(sCode)-.iCodeLines)>16 then redim preserve sCode(.iCodeLines-15)
            .bUpdateScroll = true : .bChanged = 1
            if .iCodeLines < .iViewHei then .bUpdateRowsBar = true
            if (.iCodeLines-.iStartLine) > .iViewHei then continue do
            if (.iCurLine+1) > .iCodeLines then .iCurLine -= 1 : .iCur = len(sCode(.iCurLine))
            if .iStartLine >0 then .iStartLine -= 1 
            .bUpdateRowsBar = true            
         case 13               'split a line, inserting a new line
            .iCodeLines += 1
            if .iCodeLines >= ubound(sCode) then redim preserve sCode(.iCodeLines+15)
            for N as long = .iCodeLines-1 to .iCurLine+2 step -1
               'sCode(N) = sCode(N-1) 
               *cptr(fbStr ptr,@sCode(N)) = *cptr(fbStr ptr,@sCode(N-1))
            next N
            clear *(@sCode(.iCurLine+1)),0,sizeof(fbStr) 'sCode(.iCurLine+1)=""
            sCode(.iCurLine+1) = mid( sCode(.iCurLine) , .iCur+1 ) 
            sCode(.iCurLine) = left( sCode(.iCurLine) , .iCur )
            .iCur = 0 : .iCurLine += 1 
            .bUpdateScroll = true : .bChanged = 1
            if .iCodeLines < .iViewHei then .bUpdateRowsBar = true
            if (.iCurLine-.iStartLine) < .iViewHei then continue do
            .iStartLine += 1 : .bUpdateRowsBar = true
         case -fb.SC_UP        'move cursor up (previous line)
            if .iCurLine <= 0 then continue do
            .iCurLine -= 1 : .bChanged = 1
            if .iCurLine>=.iStartLine then continue do
            .iStartLine -= 1 : .bUpdateScroll = true : .bUpdateRowsBar = true
         case -fb.SC_DOWN      'move cursor down (next line)
            if .iCurLine >= (.iCodeLines-1) then continue do
            .iCurLine += 1 : .bChanged = 1
            if (.iCurLine-.iStartLine) < .iViewHei then continue do
            .iStartLine += 1 : .bUpdateScroll = true : .bUpdateRowsBar = true
         case -fb.SC_PAGEUP    'scroll one page up
            .iCurLine -= .iViewHei : .iStartLine -= .iViewHei            
            if .iStartLine < 0 then .iCurLine -= .iStartLine : .iStartLine=0
            .bUpdateScroll = true : .bUpdateRowsBar = true
         case -fb.SC_PAGEDOWN  'scroll one page down
            .iCurLine += .iViewHei : .iStartLine += .iViewHei            
            while (.iStartLine+.iViewHei) > .iCodeLines
               .iStartLine -= 1 : .iCurLine -= 1
            wend
            .bUpdateScroll = true : .bUpdateRowsBar = true
         case _ctrl(S),_ctrl(W)'save
            if bUnnamed orelse multikey(fb.SC_LSHIFT) orelse multikey(fb.SC_RSHIFT) then
               locate .iViewHei+2,1 : color 11
               print space(.iViewWid);!"\r";
               print "Save as: ";: color 7               
               var sFile = sFiles(1)
               input "", sFile: sFile = trim(sFile)
               locate ,1 : print space(.iViewWid);
               if len(sFile)=0 then continue do
               bUnnamed = 0 : .bUpdateCaption = true : sFiles(1) = sFile
            end if
            SaveScriptFileFromArray( sFiles(1) , sCode() , .iCodeLines )            
            bUnsaved = 0
         case _ctrl(Q)         'quit
            if bUnsaved then
               locate .iViewHei+2,1 : color 14
               print "File not saved, lose changes ";
               color 11: print "(Y/N)? ";: color 7
               select case getkey()
               case asc("Y"),asc("y") : cls : return 1
               end select
               locate ,1 : print space(.iViewWid);
            else
               cls : return 1
            end if
         end select
         
      loop
   end with   
   return 1
end function

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
         case asc("c"),asc("C"): bUseConsole = true : bInteractive = ((sParm[2] or 32)=asc("i"))
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
         var iFile = ubound(g_sOpenFiles)+1
         redim preserve g_sOpenFiles( iFile )
         g_sOpenFiles(iFile) = sParm
      end if
   loop
   
   if bUseConsole=false then return 0
   if bAutoFile andalso len(sOutputFile)<>0 then
      color 12: _errorf("when '-f' is used no output filename is allowed")
      color 7 : _GiveUp(1)
   end if   
   if ubound(g_sOpenFiles)=0 then bInteractive = true
      'color 12: _errorf("console requires at least one input file")
      'color 7 : _GiveUp(1)
   'end if
      
   var isOutTTY = _isatty( _fileno(stdout) ) , isInTTY = _isatty( _fileno(stdin) )   
   if bInteractive then               
      if isOutTTY = 0 orelse isInTTY = 0 then
         color 12: _Errorf(!"Interactive mode can't have redirected input/output")
         color 7: _GiveUp(1)
      end if      
      cls : g_StandaloneQuery = true
      InitSearchWindow()
      ConsoleEdit( g_sOpenFiles() ) ': sScript = trim(sScript)
      end 0f
   end if  
   
   dim as string sText,sScript
   for iN = 1 to ubound(g_sOpenFiles)
      var sInput = g_sOpenFiles(iN)
      
      if bInteractive = false then
         if sInput = "-" orelse lcase(sinput)="stdin" then
            sInput = ""
            do
               var iChar = getchar() 
               if iChar=4 then iChar=10 'hack: alternative EOL to help batch scripts
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
         if len(sModel)=0 then _GiveUp(1)
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
