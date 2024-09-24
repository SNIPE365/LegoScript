#define HaveMain

#include "Loader\LoadLDR.bas"
#include "Loader\PartSearch.bas"
'#include "wildmatch.bas"
'#include "IsInt.bas"
''#include "BinPacking.bas"

#define WildMatchTest(_A,_B,_C...) WildMatch(_A,_B,_C),"'" _A "'", "'" _B "'"

function GetOptionEnum ( sInput as string , pzOptionList() as zstring ptr ) as long
   for N as long = lbound(pzOptionList) to ubound(pzOptionList)
      if sInput = *pzOptionList(N) then return N
   next N
   return -1
end function  

sub ShowHelp()
   print "ls.exe [OPTION]... [INPUT_FILE.LDR] INPUT_FILE.LS OUTPUT_FILE.LDR [OUTPUT_FILE.LS]"
   print "Options:"
   print "  -warn off                : Turn off all warnings"
   print "  -warn wmajor             : Enable warnings for major issues"
   print "  -warn wminor             : Enable warnings for minor issues"   
   print "  -warn all                : Enable all warnings"
   print "  -version                 : Display version information"
   print "  -update                  : Check for updates"
   print "  -autoupdate off          : Disable automatic updates"
   print "  -autoupdate on           : Enable automatic updates"
end sub

function NextToken( pStart as ubyte ptr , byref pEnd as ubyte ptr , byref bEndOfStatement as byte ) as zstring ptr
   'first ignore separators
   do
      select case *pStart
      case 0 : pEnd=NULL : return NULL 'end of string
      case 13,10,asc(" "),asc(";"),9 'CRLF space colon and TAB as separators
         pStart += 1 : continue do
      end select
      exit do
   loop
   
   function = pStart '(return value)   
   'now find the end of the token   
   do
      select case *pStart 'found end of statement?         
      case 0
         pEnd = pStart : bEndOfStatement=FALSE : exit function
      case asc(";")
         pEnd = pStart : bEndOfStatement=TRUE : exit function
      case 13,10,asc(" "),9 'found end of token?
         pEnd = pStart : exit do
      end select
      pStart += 1
   loop
   
   'and see if it was an end of statement
   do
      select case *pStart 'found end of statement?
      case asc(";")
         bEndOfStatement=TRUE : exit function
      case 13,10,asc(" "),9 'found end of token?
         pStart += 1
      case else
         bEndOfStatement=FALSE : exit function
      end select            
   loop
   
end function

function main() as integer
   
   enum WarnLevel
      WarnLevelOff
      WarnLevelMajor
      WarnLevelMinor
      WarnLevelAll
   end enum
   
   #macro EvaluateValue( _var , _options... )
      N += 1 : var sValueL = lcase(trim(command(N)))
      static as zstring ptr _var##WarnOptions(...) = { _options }
      _var = GetOptionEnum( sValueL  , _var##WarnOptions() )
      if _var < 0 then print "Invalid value '"+sValueL+"' for parameter '"+sParm+"'": system 1
   #endmacro
   #macro OptionString( _var )  
      N += 1 : _var = command(N)
      if len(_var)=0 then print "No filename specified for parameter '"+sParm+"'": system 1       
   #endmacro
   
   dim as integer N=1 , iWarn= WarnLevelMajor
   dim as string sLDpath , sLDunoffPath
   
   #if 0
      do
         var sParm = command(N), sParmL=trim(lcase(sParm))
         if len(sParmL)=0 then : 'done but must validate if all requirements were met
            print "Done.": system 0
         end if
         if sParmL[0] = asc("-") then 'is option
            select case sParmL
            case "-ldpath"
               OptionString( sLDpath )
            case "-ldunoffpath"
               OptionString( sLDunoffPath )
            case "-warn"
               EvaluateValue( iWarn , @"off" , @"wmajor", @"wminor", @"all" )
            case "-version"
               print "LegoScript Parser Version 0.1": system 0
            case "-update"
               print "No Update avaliable"
            case "-autoupdate" 'this does not make sense yet, but i will play along
               EvaluateValue( iWarn , @"off" , @"wmajor", @"wminor", @"all" )
            case "--h","-help"
               ShowHelp(): system 0
            case else            
               print "Invalid option '"+sParm+"'" : system 1
            end select
         end if
         print "File: "+sParm      
         N += 1
      loop
   #endif
      
   #if 0
      [PartID] Partname [#Color] [BasePrimative] [= [PartID] Partname [#Color] [BasePrimative] ];
      3024 P1; 3024 P2; P1 s1 = P2 c1; OR 3024 P1 s1 = 3024 P2 c1;   
      3024 P1 = 3024 P2;
      3024 P1 s1 = 3024 P2 c1;
   #endif   
   
   'var sTest = !"3024      P1\n\n = 3024\nP2 ;  3024\r\nP2 =   3024 P3 #1\r\n;3024  P3 = 3024 P4;;;\r\n;;;3024 P4\r\n= 3025 P5 c1"
   var sTest = !"3024 P1 = 3024 P2 ; P1 = 3024 P3;"
   dim as ubyte ptr pzToken = any , pzTokenEnd = any
   dim as byte bEOS = FALSE, bClean=TRUE
   var pzStatement = cast(ubyte ptr, strptr(sTest) )
   color 10: print sTest: color 7
   
   dim as string sToken,sPartName
   
   #macro GetToken( _StrVar )
      pzToken = NextToken( pzStatement , pzTokenEnd , bEOS )      
      if pzToken = NULL then 
         if bClean=FALSE then color 12: print "ERROR: found end of file without end of statement": color 7
         exit do         
      end if
      'temporally change separator to \0
      scope
         var bSep = *pzTokenEnd : *pzTokenEnd=0
         _StrVar = lcase(*cptr(zstring ptr,pzToken)) : *pzTokenEnd = bSep 
      end scope
      pzStatement = pzTokenEnd
      if bEOS then bClean=TRUE else bClean=FALSE
   #endmacro
   
   var sNameList = chr(0)
   dim as SearchPartStruct ptr pPart = any
   
   do
      pPart = NULL
      GetToken(sPartName) '1st token must be a PartID or a PartName
      if instr(sNameList,chr(0)+sPartName+chr(0)) then 'found as PartName
         pPart = cptr(SearchPartStruct ptr,&hFFFFFFFF) 'PartIDFromName(sPartName)
      else 'not found as PartName, trying PartID
         pPart = FindPart( sPartName )
         if pPart = NULL then
            color 12
            print "ERROR: Part name or ID not found '"+sPartName+"'"
            color 7 : sleep : system
         end if
         print pPart->zDesc
         sPartName = ""
      end if
      if len(sPartName)=0 then 'we didnt got a part name... so next token MUST BE a part name
         GetToken(sPartName)
         if instr(sNameList,chr(0)+sPartName+chr(0)) then
            color 12
            print "ERROR: Part name already defined '"+sPartName+"'"
            color 7 : sleep : system
         end if         
         sNameList += sPartName+chr(0)
         'validate the part name
      end if
      
      while bEOS=0
         GetToken(sToken)
      wend
      
      print hex(pPart),sPartName
      
   loop
   
   sleep
   
   #if 0
      var dTime = timer
      for N as long = 0 to g_lPartCount-1
         with *cptr(SearchPartStruct ptr, g_pPartsNames+g_lPartIndex(N))
            var sFile = .zName, sContent = ""
            'g_sLog += .zName & !" "
            print .zName & !" ";
            if FindFile( sFile )=0 then
               print "Failed to find file '"+sFile+"'"
               continue for
            end if         
            LoadFile( sFile , sContent )
            LoadModel( strptr(sContent) , .zName )         
         end with
      next
      'print g_sLog
      print
      print timer-dTime
      sleep
   #endif
   #if 0
      /'
      ls.exe[OPTION]... [INPUT_FILE.LDR] INPUT_FILE.LS OUTPUT_FILE.LDR [OUTPUT_FILE.LS]

       Options:
         -warn off                : Turn off all warnings
         -warn wmajor             : Enable warnings for major issues   
         -warn wminor             : Enable warnings for minor issues   
         -warn all                : Enable all warnings   
         -version                 : Display version information
         -update                  : Check for updates
         -autoupdate off          : Disable automatic updates   
         -autoupdate on           : Enable automatic updates

       Note:
         • parameters not within [] are mandatory.
         • parameter names can be invoked using variables, either %0.ls, %0.ldr, %1.ls, or %1.ldr.
         • only 3 of the above variables can be used after typing LS.exe (so at least 1 real filename with extension must be specified)
         • Avoid naming the first parameter the same as the third parameter, and the second parameter the same as the fourth parameter, as the program only makes copies of input files.
      '/

      /'
      ----------------------------Freebasic tokens help:----------------------------
      !"" escaped string
      $"" non escaped string
      ? match any single character of any value except for non-printing ascii characters. NOTE: change ? so that it  only matches a single  a-z,A-Z
      * matches anything until it finds the next character you specified. NOTE: change * so that it  only matches any amount of   a-z,A-Z
      ~ matches at least none combinations of " ", \t , \n or \r
      ^ matches at least one combinations of " ", \t , \n or \r,
      # matches any integer, padded 0's are ignored, so 01 gets convereted to 1
      % matches any decimal number or integer, padded 0's are ignored so 01.20 gets converted to 1.2
      & matches any combination or quantity of " " or \t but not \r or \n
      @ matches \r \n or any combination but not " " or \t
      '/

      /'
      ----------------------------outside of the " " you can do:----------------------------
      : statement termination character
      _ line continuation character, _ must immidiatley be followed by a line break
      & concatenation with numeric to string conversion
      + concatenation without numeric to string conversion
      '/

      /' ----------------------------LegoScript tokens help---------------------------- '/
      /' ; statement terminator character '/
      /' = equals (assignment) '/
      /' , list seperator for example: s1,s2,s3,s4 '/
      /' .. range operator, for example: s1..8 would be s1,s2,s3,s4,s5,s6,s7,s8 '/
      /' Parts use LDRAW part IDs and are case sensitive, File extenion does not need to be included '/
   #endif   
   #if 0
      dim CaseSensitive as boolean = true
      dim CaseInSensitive as boolean = false

      dim PartID as string = $"3005":        /' line input overwrites this test value '/
      dim PartName as string = $"B":         /' line input overwrites this test value '/
      dim PartNum as uinteger = 1:           /' line input overwrites this test value '/
      dim PrimativeName as string = $"c":    /' line input overwrites this test value '/
      dim PrimativeNum as uinteger = 1:      /' line input overwrites this test value '/
      dim Lvalue as string = PartID & $"~" & PartName & PartNum & $"~" & PrimativeName & PrimativeNum:
      dim PartID2 as string = $"3024":       /' line input overwrites this test value '/
      dim PartName2 as string = $"P":        /' line input overwrites this test value '/
      dim PartNum2 as uinteger = 1:          /' line input overwrites this test value '/
      dim PrimativeName2 as string = $"s":   /' line input overwrites this test value '/
      dim PrimativeNum2 as uinteger = 1:     /' line input overwrites this test value '/
      dim Rvalue as string = PartID2 & $"~" & PartName2 & PartNum2 & $"~" & PrimativeName2 & PrimativeNum2:
      dim Statement as string = Lvalue & $"~=~" & Rvalue & $"~;~":
      dim ExpStr as string = $"~*^?#^?#~=~*^?#^?#~;~":
      dim ExpStrFwdDecl as string = $"~*^?#~;~":
      dim LDrawExpStrLineType0 as string = !"~0~*~\r\n": /' eg: 0 this is a comment or 0 //this is also a comment '/
      dim LDrawExpStrLineType1 as string = !"&#&#&%&%&%&%&%&%&%&%&%&%&%&%&*~@": /' eg: 1 0 1.1 2.2 3.3 4.4 5.5 6.6 7.7 8.8 9.9 10.10 11.11 3024.dat '/
      dim LDrawExpStrLineType2 as string = !"&#&#&%&%&%&%&%&%&*~@": /' eg: 2 3 1.1 2.2 3.3 4.4 5.5 6.6 '/
      dim LDrawExpStrLineType3 as string = !"&#&#&%&%&%&%&%&%&%&%&*~@": /' eg: 3 5 1.1 2.2 3.3 4.4 5.5 6.6 7.7 8.8 '/
      dim LDrawExpStrLineType4 as string = !"&#&#&%&%&%&%&%&%&%&%&%&%&%&%&%&*~@": /' eg: 4 7 1.1 2.2 3.3 4.4 5.5 6.6 7.7 8.8 9.9 10.10 11.11 12.12 '/
      dim LDrawExpStrLineType5 as string = !"&#&#&%&%&%&%&%&%&%&%&%&%&%&%&%&*~@": /' eg: 5 9 1.1 2.2 3.3 4.4 5.5 6.6 7.7 8.8 9.9 10.10 11.11 12.12 '/
      dim TestLDrawStr as string = !"1 0 0 0 0 1 0 0 0 1 0 0 0 1" & PartID & "@": /' test LDraw line type 1 string '/

      open "inputfileTest.ls" for input as #10
      open "inputfileTest.ldr" for input as #20
      open "wildcardstest.ls" for output As #1
      open "wildcardstest.ldr" for output As #2

      '

      do while (1)
         line input Statement
         /' line input #1, ExpStr '/
         /' read from input file instead of keyboard '/
         print WildMatch(ExpStr, Statement, CaseSensitive)
         print #1, Statement
         
         line input TestLDrawStr
         /' line input #2, LDrawExpStrLineType1 '/ 
         /' read from input file instead of keyboard '/
         print WildMatch(LDrawExpStrLineType1, TestLDrawStr, CaseSensitive)
         print #2, TestLDrawStr
      loop
            
      close #1, #2
   #endif  
   'sleep()
   return 0

end function

main()