@echo off
if "%~2"=="" (
    set "output_file=%~n1.exe"
) else (
    set "output_file=%~2"
)
set "input_file=%~1"
set "input_file=%input_file:"=%"

"C:\Users\kris\Desktop\LegoScript 2\MINGW32\bin\gcc" "%input_file%" -Wall -o "%output_file%"

exit /b
