@echo off
setlocal enabledelayedexpansion

:: Directories containing .dat files
set "PARTS_DIR1=%USERPROFILE%\Desktop\LDCAD\LDraw\parts"
set "PARTS_DIR2=%USERPROFILE%\Desktop\LDCAD\LDraw\unoff\parts"
set "OUTPUT_DIR=%USERPROFILE%\Desktop\LS\Win32\LStests"

cd /d %~dp0

set Threads=0
:: Loop through .dat files in the directories
for /F %%A in (LSTests\ValidParts.txt) do (
    for /F %%B in (LSTests\ValidParts.txt) do (
        if not "%%A"=="%%B" (
            :: Extract filenames without extensions
            set "PART1=%%~nA"
            set "PART2=%%~nB"

            :: Generate folder and filenames with ; included
            set "FOLDER_NAME=!PART1! P1 #2 c1 = !PART2! P2 #4 s1;"
            set "TEXT_FILE_NAME=!FOLDER_NAME!.ls"

            :: Create the folder
            mkdir "%OUTPUT_DIR%\!FOLDER_NAME!" 2>nul

            :: Write the input file for LS2LDR.EXE
            echo '!PART1!' '!PART2!'
            echo !PART1! P1 #2 c1 = !PART2! P2 #4 s1;>"%OUTPUT_DIR%\!FOLDER_NAME!\!TEXT_FILE_NAME!"
            pushd  "%OUTPUT_DIR%\!FOLDER_NAME!"
            :: Run LS2LDR.EXE          
            start /b %USERPROFILE%\Desktop\LS\Win32\LS2LDR.EXE %OUTPUT_DIR%\!FOLDER_NAME!\!TEXT_FILE_NAME! >NUL
	    popd

            set /a Threads=!Threads!+1
            if !Threads! == 64 (
              set Threads=0
              Echo Syncing...
              call :WaitFinish
              Echo Resuming...		
            )

        )
    )
)

call :WaitFinish
echo All combinations processed.
pause
goto :eof

:WaitFinish
  tasklist /FI "IMAGENAME eq LS2LDR.EXE" /NH | find /I "LS2LDR.EXE" >nul
  if %ERRORLEVEL% == 1 GOTO :EOF
  timeout 1 >nul
goto :WaitFinish
