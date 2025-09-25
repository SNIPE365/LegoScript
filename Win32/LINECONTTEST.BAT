@echo off

rem start "" cmd.exe

setlocal enabledelayedexpansion

(set LF=^
%=Don't remove this line=%
)

rem === LEGO Script Runner with Error Handling and Multi-Instance Fallback ===
set "in_block=false"
set "line_number=0"
set "fullscript="
for /f "usebackq tokens=*" %%L in (`findstr /N "^" %~f0`) do (    
	
	set "line=%%L"		
    set /a line_number+=1    
	set "trimmed_line=!line:*:=!"	
    
	rem === Detect block start ===	
    if "!trimmed_line!" == ":: [LS_BEGIN]::" (
        set "in_block=true"		
    ) else if "!in_block!" == "true" (        
		rem Only process lines that begin with ::        
        if "!trimmed_line:~0,2!" == "::" (			
			if NOT "!fullscript!" == "" (
				call :Display				
			)			
			
			if "!trimmed_line!" == ":: [LS_END]::" (
				set "in_block=false"
			) else (		
				set "fullscript=!trimmed_line:~3!"							
				set "startline_number=!line_number!"
			)
			
        rem if line does not begin with :: but it's between BEGIN/END then it's a multiline
		) else (
			set "fullscript=!fullscript!!trimmed_line!"
		)
    )
)

endlocal
exit /b

:display
	rem === Run LEGO Script via start /wait, feeding one line ===
	echo =======================================================================================================================
	echo =======================================================================================================================
	echo =======================================================================================================================
	echo Running line !startline_number!: !fullscript!
	echo !fullscript! | legoscript.exe -c -v -
	rem start /wait /b "" legoscript.exe -c -v -	
	rem === Check for error and retry with parallel fallback ===
	rem if errorlevel 1 (
	rem	echo [WARN] Line !startline_number! failed. Retrying in separate process...
	rem	echo !fullscript! | start "" legoscript.exe -c -v -
	rem )
goto :eof

rem below is the legoscript blocks, each block can have many statements on a single line, but must not
rem have line breaks per statement, since :: as well as line breaks is used to denote the start and end of a new model.

//{ // <TEST>,<TEST>
//} NO COMMENTS IN LS FROM BATCH CAN BE USED YET!
//=====================================================================================================================

:: [LS_BEGIN]::

:: 1x1DummySlab SB1 #3;
   1x1DummySlab SB2 #5 #yo16;
   SB1 c1 = NULL;
:: 1x1DummySlab SB98 #6 c1 = 1x1DummySlab SB99 #9 #yo16  s1;
:: Error = ErrorToo;
:: //This is a comment you know right?
   3001 B1 c1 = /*multline
   comment */
   3001 B2 #2 s1;
// Here?
:: [LS_END]::