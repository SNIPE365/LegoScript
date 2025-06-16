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

function ParseCmdLine() as long
   #define _errorf(_Parms...) fprintf(stderr,_Parms)
   #define _GiveUp(_N) end _N
   dim as long iN = 1, iConsoleStart, iDump
   do
      var sParm = command(iN) : iN += 1
      if len(sParm)=0 then exit do
      if sParm[0] = asc("-") then 'options
         select case sParm[1]
         case asc("d"),asc("D"): iDump = true
         case asc("c"),asc("C"): iConsoleStart = iN: exit do
         case else
            color 12: _errorf("Invalid option: '%s'\n",sParm): color 7: _GiveUp(1)
         end select
      else
         var iFile = ubound(sOpenFiles)+1
         redim preserve sOpenFiles( iFile )
         sOpenFiles(iFile) = sParm
      end if
   loop
      
   if iConsoleStart then
      var isTerm = _isatty( _fileno(stdout) )
      dim as string sText,sScript            
      var sCmd = ""
      'do
         sCmd = command(iConsoleStart) : iConsoleStart += 1
         'if len(sParm)=0 then exit do
         'if len(sCmd) then sCmd += " "+sParm else sCmd += sParm
      'loop
      
      if len(sCmd) then
         var f = freefile()
         if open(sCmd for binary access read as #f) then
            _Errorf(!"Failed to open '%s'\n",sCmd)
            _GiveUp(2)
         end if         
         sScript = space(lof(f))
         get #f,,sScript : close #f
         if iDump=0 then 
            var sFile = command(iConsoleStart)
            if len(sFile)=0 then 
               _Errorf(!"SYNTAX: LegoScript [-d] -c file.ls [output.ldr]")
               _GiveUp(1)            
            elseif FileExists(sFile) then
               _Errorf(!"output file '%s' already exists.",sFile)
               _GiveUp(1)         
            end if
         end if
      else            
         if IsTerm=0 then
            _Errorf(!"SYNTAX: LegoScript -d -c file.ls >output.ldr")
            _GiveUp(1)
         end if         
         cls : g_StandaloneQuery = true
         dim as string sText
         InitSearchWindow()
         QueryText(sText)
         sleep : system
      end if      
      dim as string sModel, sError
      sModel = LegoScriptToLDraw(sScript, sError, sCmd)
      if len(sError) then PrintColoredOutput(sError)
      if len(sModel) then 
         dim as string sFile
         if iDump then            
            sFile = trim( sScript , any !"\r\n" )+".ldr"
            for N as long = 0 to len(sFile)-1
               select case sFile[N]
               case asc("*"),asc(""""),asc("/"),asc("\"),asc("<"),asc(">"),asc(":"),asc("|"),asc("?")
                 sFile[N] = asc("-")
               case is <32 , is > 127
                  sFile[N] = asc("_")
               end select
            next N
         else
            sFile = command(iConsoleStart)            
         end if
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
      return 1
   end if   
   return 0
end function
