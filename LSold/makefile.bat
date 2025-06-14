@echo off
if "%~2"=="" (
    set "output_file=%~n1.exe"
) else (
    set "output_file=%~2"
)
set "input_file=%~1"
set "input_file=%input_file:"=%"

rem Step 1: Compile the C source file to an executable
C:\Users\kris\Desktop\LegoScript\MINGW32\bin\gcc "%input_file%" -o "%output_file%"

rem Step 2: Compile the optimized version of the C source file and save it as a .c file
set "optimized_output_file=%~n1_optimized.c"
C:\Users\kris\Desktop\LegoScript\MINGW\bin\gcc -O2 -E "%input_file%" -o "%optimized_output_file%"

exit /b
