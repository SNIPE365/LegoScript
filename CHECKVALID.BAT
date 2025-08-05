@echo off
setlocal enabledelayedexpansion

:: Directories containing .dat files
set "PARTS_DIR1=%USERPROFILE%\Desktop\LDCAD\LDraw\parts"
set "PARTS_DIR2=%USERPROFILE%\Desktop\LDCAD\LDraw\unoff\parts"
set "OUTPUT_DIR=%USERPROFILE%\Desktop\LS\Win32\LStests"

echo.>%OUTPUT_DIR%\ValidParts.txt
echo.>%OUTPUT_DIR%\Crashes.txt
echo.>%OUTPUT_DIR%\Failures.txt

for %%A in ("%PARTS_DIR1%\*.dat" "%PARTS_DIR2%\*.dat") do (    
    rem check if theres no errors in the part itself
    set "PART1=%%~nA"
    rem Write the input file for LS2LDR.EXE
    echo !PART1! P1 #2 c1 = !PART1! P2 #4 s1;>"%OUTPUT_DIR%\check.ls"
    rem Run LS2LDR.EXE
    echo !PART1!
    "%USERPROFILE%\Desktop\LS\Win32\LS2LDR.EXE" "%OUTPUT_DIR%\check.ls" >NUL
    echo xxx !ERRORLEVEL!
    if !ERRORLEVEL! == 0 ( echo %%A >>%OUTPUT_DIR%\ValidParts.txt )
    if !ERRORLEVEL! NEQ 0 (
      if !ERRORLEVEL! == 255 ( echo %%A >>%OUTPUT_DIR%\Failures.txt )
      if !ERRORLEVEL! NEQ 255 ( echo %%A >>%OUTPUT_DIR%\Crashes.txt )
    )
    rem (crash) = -1073741819

)

goto :eof

:: Loop through .dat files in the directories
for %%A in ("%PARTS_DIR1%\*.dat" "%PARTS_DIR2%\*.dat") do (    

    for %%B in ("%PARTS_DIR1%\*.dat" "%PARTS_DIR2%\*.dat") do (
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
            echo !PART1! P1 #2 c1 = !PART2! P2 #4 s1;>"%OUTPUT_DIR%\!FOLDER_NAME!\!TEXT_FILE_NAME!"
            pushd  "%OUTPUT_DIR%!FOLDER_NAME!"
            :: Run LS2LDR.EXE
            "%USERPROFILE%\Desktop\LS\Win32\LS2LDR.EXE" "%OUTPUT_DIR%\!FOLDER_NAME!\!TEXT_FILE_NAME!"
	    popd
        )
    )
)

echo All combinations processed.
pause
