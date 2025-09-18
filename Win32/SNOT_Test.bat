@echo off

start "" cmd.exe

setlocal enabledelayedexpansion

rem === LEGO Script Runner with Error Handling and Multi-Instance Fallback ===

set "in_block=false"
set "line_number=0"

for /f "usebackq tokens=*" %%L in ("%~f0") do (
    set "line=%%L"
    set /a line_number+=1
    set "trimmed_line=!line!"

    rem === Detect block start ===
    if "!trimmed_line!" == ":: [LS_BEGIN]" (
        set "in_block=true"
    ) else if "!trimmed_line!" == ":: [LS_END]" (
        set "in_block=false"
    ) else if "!in_block!" == "true" (
        rem Only process lines that begin with ::
        echo !trimmed_line! | findstr /b "::" >nul
        if !errorlevel! == 0 (
            set "cleaned_line=!trimmed_line:~3!"
            rem === Run LEGO Script via start /wait, feeding one line ===
            echo Running line !line_number!: !cleaned_line!
            echo !cleaned_line! | start /wait /b "" legoscript.exe -c -v -
            
            rem === Check for error and retry with parallel fallback ===
            if errorlevel 1 (
                echo [WARN] Line !line_number! failed. Retrying in separate process...
                echo !cleaned_line! | start "" legoscript.exe -c -v -
            )
        )
    )
)

endlocal
exit /b

rem below is the legoscript blocks, each block can have many statements on a single line, but must not
rem have line breaks per statement, since :: as well as line breaks is used to denote the start and end of a new model.

:: [LS_BEGIN]

:: //{ 11211,11211
:: 7133 BM1 c1 = 7133 BM2 s1; //todo
:: 7133 BM1 c1 = 7133 BM2 s2; //todo
:: 7133 BM1 c1 = 7133 BM2 s3; //todo

:: 7133 BM1 c2 = 7133 BM2 s1; //todo
:: 7133 BM1 c2 = 7133 BM2 s2; //todo
:: 7133 BM1 c2 = 7133 BM2 s3; //todo

:: 7133 BM1 c3 = 7133 BM2 s1; //todo
:: 7133 BM1 c3 = 7133 BM2 s2; //todo
:: 7133 BM1 c3 = 7133 BM2 s3; //todo

:: 7133 BM1 s1 = 7133 BM2 c1; //todo
:: 7133 BM1 s1 = 7133 BM2 c2; //todo
:: 7133 BM1 s1 = 7133 BM2 c3; //todo

:: 7133 BM1 s2 = 7133 BM2 c1; //todo
:: 7133 BM1 s2 = 7133 BM2 c2; //todo
:: 7133 BM1 s2 = 7133 BM2 c3; //todo

:: 7133 BM1 s3 = 7133 BM2 c1; //todo
:: 7133 BM1 s3 = 7133 BM2 c2; //todo
:: 7133 BM1 s3 = 7133 BM2 c3; //todo

:: 7133 BM1 s4 = 7133 BM2 c1; //todo
:: 7133 BM1 s4 = 7133 BM2 c2; //todo
:: 7133 BM1 s4 = 7133 BM2 c3; //todo

:: 7133 BM2 c1 = 7133 BM1 s1; //todo
:: 7133 BM2 c1 = 7133 BM1 s2; //todo
:: 7133 BM2 c1 = 7133 BM1 s3; //todo

:: 7133 BM2 c2 = 7133 BM1 s1; //todo
:: 7133 BM2 c2 = 7133 BM1 s2; //todo
:: 7133 BM2 c2 = 7133 BM1 s3; //todo

:: 7133 BM2 c3 = 7133 BM1 s1; //todo
:: 7133 BM2 c3 = 7133 BM1 s2; //todo
:: 7133 BM2 c3 = 7133 BM1 s3; //todo

:: 7133 BM2 s1 = 7133 BM1 c1; //todo
:: 7133 BM2 s1 = 7133 BM1 c2; //todo
:: 7133 BM2 s1 = 7133 BM1 c3; //todo

:: 7133 BM2 s2 = 7133 BM1 c1; //todo
:: 7133 BM2 s2 = 7133 BM1 c2; //todo
:: 7133 BM2 s2 = 7133 BM1 c3; //todo

:: 7133 BM2 s3 = 7133 BM1 c1; // Warning: part 'BM1(7133.dat)' only have 0 clutches at '':1 '7133 BM2 s3 = 7133 BM1 c1'
:: 7133 BM2 s3 = 7133 BM1 c2; // Warning: part 'BM1(7133.dat)' only have 0 clutches at '':1 '7133 BM2 s3 = 7133 BM1 c2'
:: 7133 BM2 s3 = 7133 BM1 c3; // Warning: part 'BM1(7133.dat)' only have 0 clutches at '':1 '7133 BM2 s3 = 7133 BM1 c3'

:: //}

:: //{ // 4070,4070
:: 4070 BM1  c1 = 4070 BM2  s1; // collision between BM1 c1 and BM2 s1
:: 4070 BM1  c2 = 4070 BM2  s1; // collision between BM1 c1 and BM2 s2
:: 4070 BM1  c1 = 4070 BM2  s2;
:: 4070 BM1  c2 = 4070 BM2  s2; // collision between BM1 c2 and BM2 s2

:: 4070 BM1  s1 = 4070 BM2  c1;
:: 4070 BM1  s2 = 4070 BM2  c1; 
:: 4070 BM1  s1 = 4070 BM2  c2; // collision between BM1 s1 and BM2 c2
:: 4070 BM1  s2 = 4070 BM2  c2; // collision between BM1 s2 and BM2 c2

:: 4070 BM2  c1 = 4070 BM1  s1; // collision between BM2 c1 and BM1 s1
:: 4070 BM2  c2 = 4070 BM1  s1; // collision between BM2 c2 and BM1 s1
:: 4070 BM2  c1 = 4070 BM1  s2;
:: 4070 BM2  c2 = 4070 BM1  s2; // collision between BM2 c2 and BM1 s2

:: 4070 BM2  s1 = 4070 BM1  c1;
:: 4070 BM2  s2 = 4070 BM1  c1;
:: 4070 BM2  s1 = 4070 BM1  c2; // collision between BM2 s1 and BM1 c2
:: 4070 BM2  s2 = 4070 BM1  c2; // collision between BM2 s2 and BM1 c2
:: //}

:: //{ // 87087,87087
:: 87087 BM1  c1 = 87087 BM2  s1; // collision between BM1 c1 and BM2 s1
:: 87087 BM1  c1 = 87087 BM2  s2;
:: 87087 BM1  s1 = 87087 BM2  c1;
:: 87087 BM1  s2 = 87087 BM2  c1;

:: 87087 BM2  c1 = 87087 BM1  s1; // collison between BM2 c1 and BM1 s1
:: 87087 BM2  c1 = 87087 BM1  s2;
:: 87087 BM2  s1 = 87087 BM1  c1;
:: 87087 BM2  s2 = 87087 BM1  c1;
:: //}

:: //{ // 47905,47905
:: 47905 BM1  c1 = 47905 BM2  s1; // collision between BM1 c1 and BM2 s1
:: 47905 BM1  c1 = 47905 BM2  s2; // collision between BM1 c1 and BM2 s2
:: 47905 BM1  c1 = 47905 BM2  s3;

:: 47905 BM1  s1 = 47905 BM2  c1;
:: 47905 BM1  s2 = 47905 BM2  c1;
:: 47905 BM1  s3 = 47905 BM2  c1;

:: 47905 BM2  c1 = 47905 BM1  s1; // collision between BM2 c1 and BM1 s1
:: 47905 BM2  c1 = 47905 BM1  s2; // collision between BM2 c1 and BM1 s2
:: 47905 BM2  c1 = 47905 BM1  s3;

:: 47905 BM2  s1 = 47905 BM1  c1;
:: 47905 BM2  s2 = 47905 BM1  c1;
:: 47905 BM2  s3 = 47905 BM1  c1;
:: //}

:: //{ // 26604,26604
:: 26604 BM1  c1 = 26604 BM2  s1; // collision between BM1 c1 and BM2 s1
:: 26604 BM1  c1 = 26604 BM2  s2; // collision between BM1 c1 and BM2 s2
:: 26604 BM1  c1 = 26604 BM2  s3;

:: 26604 BM1  s1 = 26604 BM2  c1;
:: 26604 BM1  s2 = 26604 BM2  c1;
:: 26604 BM1  s3 = 26604 BM2  c1;

:: 26604 BM2  c1 = 26604 BM1  s1; // collision between BM2 c1 and BM1 s1
:: 26604 BM2  c1 = 26604 BM1  s2; // collision between BM2 c1 and BM1 s2
:: 26604 BM2  c1 = 26604 BM1  s3;

:: 26604 BM2  s1 = 26604 BM1  c1;
:: 26604 BM2  s2 = 26604 BM1  c1;
:: 26604 BM2  s3 = 26604 BM1  c1;
:: //}

:: //{ // 4733,4733
:: 4733 BM1  c1 = 4733 BM2  s1; // collision between BM1 c1 and BM2 s1
:: 4733 BM1  c1 = 4733 BM2  s2; // collision between BM1 c1 and BM2 s2
:: 4733 BM1  c1 = 4733 BM2  s3; // collision between BM1 c1 and BM2 s3
:: 4733 BM1  c1 = 4733 BM2  s4; // collision between BM1 c1 and BM2 s4
:: 4733 BM1  c1 = 4733 BM2  s5;

:: 4733 BM1  s1 = 4733 BM2  c1;
:: 4733 BM1  s2 = 4733 BM2  c1;
:: 4733 BM1  s3 = 4733 BM2  c1;
:: 4733 BM1  s4 = 4733 BM2  c1;
:: 4733 BM1  s5 = 4733 BM2  c1;

:: 4733 BM2  c1 = 4733 BM1  s1; // collision between BM2 c1 and BM1 s1
:: 4733 BM2  c1 = 4733 BM1  s2; // collision between BM2 c1 and BM1 s2
:: 4733 BM2  c1 = 4733 BM1  s3; // collision between BM2 c1 and BM1 s3
:: 4733 BM2  c1 = 4733 BM1  s4; // collision between BM2 c1 and BM1 s4
:: 4733 BM2  c1 = 4733 BM1  s5;

:: 4733 BM2  s1 = 4733 BM1  c1;
:: 4733 BM2  s2 = 4733 BM1  c1;
:: 4733 BM2  s3 = 4733 BM1  c1;
:: 4733 BM2  s4 = 4733 BM1  c1;
:: 4733 BM2  s5 = 4733 BM1  c1;
:: //}

:: //{ // 32952,32952
:: 32952 BM1  c1 = 32952 BM2  s1; // collision between B1 c1 and BM2 s1; 
:: 32952 BM1  c1 = 32952 BM2  s2; // collision between B1 c1 and BM2 s2;
:: 32952 BM1  c1 = 32952 BM2  s3;

:: 32952 BM1  s1 = 32952 BM2  c1;
:: 32952 BM1  s2 = 32952 BM2  c1;
:: 32952 BM1  s3 = 32952 BM2  c1;

:: 32952 BM2  c1 = 32952 BM1  s1; // collision between B2 c1 and BM1 s1;
:: 32952 BM2  c1 = 32952 BM1  s2; // collision between B2 c1 and BM1 s2;
:: 32952 BM2  c1 = 32952 BM1  s3;

:: 32952 BM2  s1 = 32952 BM1  c1;
:: 32952 BM2  s2 = 32952 BM1  c1;
:: 32952 BM2  s3 = 32952 BM1  c1;
:: //} 

:: //{ // 1x1x2brickwith2studson3sides,1x1x2brickwith2studson3sides
:: //dummy part with dummy part ID because not in ldraw yet and part ID is not yet known
:: 1x1x2brickwith2studson3sides BM1  c1 = 1x1x2brickwith2studson3sides BM2  s1; //LS is saying 0 clutches and 0 studs weirdly
:: 1x1x2brickwith2studson3sides BM1  c1 = 1x1x2brickwith2studson3sides BM2  s2; //LS is saying 0 clutches and 0 studs weirdly
:: 1x1x2brickwith2studson3sides BM1  c1 = 1x1x2brickwith2studson3sides BM2  s3; //LS is saying 0 clutches and 0 studs weirdly
:: 1x1x2brickwith2studson3sides BM1  c1 = 1x1x2brickwith2studson3sides BM2  s4; //LS is saying 0 clutches and 0 studs weirdly
:: 1x1x2brickwith2studson3sides BM1  c1 = 1x1x2brickwith2studson3sides BM2  s5; //LS is saying 0 clutches and 0 studs weirdly
;: 1x1x2brickwith2studson3sides BM1  c1 = 1x1x2brickwith2studson3sides BM2  s6; //LS is saying 0 clutches and 0 studs weirdly
:: 1x1x2brickwith2studson3sides BM1  c1 = 1x1x2brickwith2studson3sides BM2  s7; //LS is saying 0 clutches and 0 studs weirdly

:: 1x1x2brickwith2studson3sides BM1  s1 = 1x1x2brickwith2studson3sides BM2  c1; //LS is saying 0 clutches and 0 studs weirdly
:: 1x1x2brickwith2studson3sides BM1  s2 = 1x1x2brickwith2studson3sides BM2  c1; //LS is saying 0 clutches and 0 studs weirdly
:: 1x1x2brickwith2studson3sides BM1  s3 = 1x1x2brickwith2studson3sides BM2  c1; //LS is saying 0 clutches and 0 studs weirdly
:: 1x1x2brickwith2studson3sides BM1  s4 = 1x1x2brickwith2studson3sides BM2  c1; //LS is saying 0 clutches and 0 studs weirdly
:: 1x1x2brickwith2studson3sides BM1  s5 = 1x1x2brickwith2studson3sides BM2  c1; //LS is saying 0 clutches and 0 studs weirdly
;: 1x1x2brickwith2studson3sides BM1  s6 = 1x1x2brickwith2studson3sides BM2  c1; //LS is saying 0 clutches and 0 studs weirdly
:: 1x1x2brickwith2studson3sides BM1  s7 = 1x1x2brickwith2studson3sides BM2  c1; //LS is saying 0 clutches and 0 studs weirdly

:: 1x1x2brickwith2studson3sides BM2  c1 = 1x1x2brickwith2studson3sides BM1  s1; //LS is saying 0 clutches and 0 studs weirdly
:: 1x1x2brickwith2studson3sides BM2  c1 = 1x1x2brickwith2studson3sides BM1  s2; //LS is saying 0 clutches and 0 studs weirdly
:: 1x1x2brickwith2studson3sides BM2  c1 = 1x1x2brickwith2studson3sides BM1  s3; //LS is saying 0 clutches and 0 studs weirdly
:: 1x1x2brickwith2studson3sides BM2  c1 = 1x1x2brickwith2studson3sides BM1  s4; //LS is saying 0 clutches and 0 studs weirdly
:: 1x1x2brickwith2studson3sides BM2  c1 = 1x1x2brickwith2studson3sides BM1  s5; //LS is saying 0 clutches and 0 studs weirdly
;: 1x1x2brickwith2studson3sides BM2  c1 = 1x1x2brickwith2studson3sides BM1  s6; //LS is saying 0 clutches and 0 studs weirdly
:: 1x1x2brickwith2studson3sides BM2  c1 = 1x1x2brickwith2studson3sides BM1  s7; //LS is saying 0 clutches and 0 studs weirdly

:: 1x1x2brickwith2studson3sides BM2  s1 = 1x1x2brickwith2studson3sides BM1  c1; //LS is saying 0 clutches and 0 studs weirdly
:: 1x1x2brickwith2studson3sides BM2  s2 = 1x1x2brickwith2studson3sides BM1  c1; //LS is saying 0 clutches and 0 studs weirdly
:: 1x1x2brickwith2studson3sides BM2  s3 = 1x1x2brickwith2studson3sides BM1  c1; //LS is saying 0 clutches and 0 studs weirdly
:: 1x1x2brickwith2studson3sides BM2  s4 = 1x1x2brickwith2studson3sides BM1  c1; //LS is saying 0 clutches and 0 studs weirdly
:: 1x1x2brickwith2studson3sides BM2  s5 = 1x1x2brickwith2studson3sides BM1  c1; //LS is saying 0 clutches and 0 studs weirdly
;: 1x1x2brickwith2studson3sides BM2  s6 = 1x1x2brickwith2studson3sides BM1  c1; //LS is saying 0 clutches and 0 studs weirdly
:: 1x1x2brickwith2studson3sides BM2  s7 = 1x1x2brickwith2studson3sides BM1  c1; //LS is saying 0 clutches and 0 studs weirdly
:: //}

:: //{ //  15444,15444 

:: 15444 BM1 c1 = 15444 BM2 s1;
:: 15444 BM1 c1 = 15444 BM2 s2; // Warning: part 'BM2(15444.dat)' only have 1 studs at '':1 '15444 BM1 c1 = 15444 BM2 s2'

:: 15444 BM1 c2 = 15444 BM2 s1;
:: 15444 BM1 c2 = 15444 BM2 s2; // Warning: part 'BM2(15444.dat)' only have 1 studs at '':1 '15444 BM1 c2 = 15444 BM2 s2'

:: 15444 BM1 s1 = 15444 BM2 c1;
:: 15444 BM1 s1 = 15444 BM2 c2;

:: 15444 BM2 c1 = 15444 BM1 s1;
:: 15444 BM2 c1 = 15444 BM1 s2; // Warning: part 'BM1(15444.dat)' only have 1 studs at '':1 '15444 BM2 c1 = 15444 BM1 s2'

:: 15444 BM2 c2 = 15444 BM1 s1;
:: 15444 BM2 c2 = 15444 BM1 s2; // Warning: part 'BM1(15444.dat)' only have 1 studs at '':1 '15444 BM2 c2 = 15444 BM1 s2'

:: 15444 BM2 s1 = 15444 BM1 c1;
:: 15444 BM2 s1 = 15444 BM1 c2;

:: //}

:: //{ // 86876,86876
:: 86876 BM1 c1 = 86876 BM2 s1; // Warning: part 'BM1(86876.dat)' only have 0 clutches.at '':1 '86876 BM1 c1 = 86876 BM2 s1'
:: 86876 BM1 c1 = 86876 BM2 s2; // Warning: part 'BM1(86876.dat)' only have 0 clutches.at '':1 '86876 BM1 c1 = 86876 BM2 s2'
:: 86876 BM1 c1 = 86876 BM2 s3; // Warning: part 'BM1(86876.dat)' only have 0 clutches.at '':1 '86876 BM1 c1 = 86876 BM2 s3'

:: 86876 BM1 c2 = 86876 BM2 s1; // Warning: part 'BM1(86876.dat)' only have 0 clutches.at '':1 '86876 BM1 c2 = 86876 BM2 s1'
:: 86876 BM1 c2 = 86876 BM2 s2; // Warning: part 'BM1(86876.dat)' only have 0 clutches.at '':1 '86876 BM1 c2 = 86876 BM2 s2'
:: 86876 BM1 c2 = 86876 BM2 s3; // Warning: part 'BM1(86876.dat)' only have 0 clutches.at '':1 '86876 BM1 c2 = 86876 BM2 s3'

:: 86876 BM1 c3 = 86876 BM2 s1; // Warning: part 'BM1(86876.dat)' only have 0 clutches.at '':1 '86876 BM1 c3 = 86876 BM2 s1'
:: 86876 BM1 c3 = 86876 BM2 s2; // Warning: part 'BM1(86876.dat)' only have 0 clutches.at '':1 '86876 BM1 c3 = 86876 BM2 s2'
:: 86876 BM1 c3 = 86876 BM2 s3; // Warning: part 'BM1(86876.dat)' only have 0 clutches.at '':1 '86876 BM1 c3 = 86876 BM2 s3'

:: 86876 BM1 s1 = 86876 BM2 c1; // Warning: part 'BM1(86876.dat)' only have 0 clutches.at '':1 '86876 BM1 s1 = 86876 BM2 c1'
:: 86876 BM1 s1 = 86876 BM2 c2; // Warning: part 'BM2(86876.dat)' only have 0 clutches.at '':1 '86876 BM1 s1 = 86876 BM2 c2'
:: 86876 BM1 s1 = 86876 BM2 c3; // Warning: part 'BM2(86876.dat)' only have 0 clutches.at '':1 '86876 BM1 s1 = 86876 BM2 c3'

:: 86876 BM1 s2 = 86876 BM2 c1; // Warning: part 'BM2(86876.dat)' only have 0 clutches.at '':1 '86876 BM1 s2 = 86876 BM2 c1'
:: 86876 BM1 s2 = 86876 BM2 c2; // Warning: part 'BM2(86876.dat)' only have 0 clutches.at '':1 '86876 BM1 s2 = 86876 BM2 c2'
:: 86876 BM1 s2 = 86876 BM2 c3; // Warning: part 'BM2(86876.dat)' only have 0 clutches.at '':1 '86876 BM1 s2 = 86876 BM2 c3'

:: 86876 BM1 s3 = 86876 BM2 c1; // Warning: part 'BM2(86876.dat)' only have 0 clutches.at '':1 '86876 BM1 s3 = 86876 BM2 c1'
:: 86876 BM1 s3 = 86876 BM2 c2; // Warning: part 'BM2(86876.dat)' only have 0 clutches.at '':1 '86876 BM1 s3 = 86876 BM2 c2'
:: 86876 BM1 s3 = 86876 BM2 c3; // Warning: part 'BM2(86876.dat)' only have 0 clutches.at '':1 '86876 BM1 s3 = 86876 BM2 c3'

:: 86876 BM2 c1 = 86876 BM1 s1; // Warning: part 'BM2(86876.dat)' only have 0 clutches.at '':1 '86876 BM2 c1 = 86876 BM1 s1'
:: 86876 BM2 c1 = 86876 BM1 s2; // Warning: part 'BM2(86876.dat)' only have 0 clutches.at '':1 '86876 BM2 c1 = 86876 BM1 s2'
:: 86876 BM2 c1 = 86876 BM1 s3; // Warning: part 'BM2(86876.dat)' only have 0 clutches.at '':1 '86876 BM2 c1 = 86876 BM1 s3'

:: 86876 BM2 c2 = 86876 BM1 s1; // Warning: part 'BM2(86876.dat)' only have 0 clutches.at '':1 '86876 BM2 c2 = 86876 BM1 s1'
:: 86876 BM2 c2 = 86876 BM1 s2; // Warning: part 'BM2(86876.dat)' only have 0 clutches.at '':1 '86876 BM2 c2 = 86876 BM1 s2'
:: 86876 BM2 c2 = 86876 BM1 s3; // Warning: part 'BM2(86876.dat)' only have 0 clutches.at '':1 '86876 BM2 c2 = 86876 BM1 s3'

:: 86876 BM2 c3 = 86876 BM1 s1; // Warning: part 'BM2(86876.dat)' only have 0 clutches.at '':1 '86876 BM2 c3 = 86876 BM1 s1'
:: 86876 BM2 c3 = 86876 BM1 s2; // Warning: part 'BM2(86876.dat)' only have 0 clutches.at '':1 '86876 BM2 c3 = 86876 BM1 s2'
:: 86876 BM2 c3 = 86876 BM1 s3; // Warning: part 'BM2(86876.dat)' only have 0 clutches.at '':1 '86876 BM2 c3 = 86876 BM1 s3'

:: 86876 BM2 s1 = 86876 BM1 c1; // Warning: part 'BM1(86876.dat)' only have 0 clutches.at '':1 '86876 BM2 s1 = 86876 BM1 c1'
:: 86876 BM2 s1 = 86876 BM1 c2; // Warning: part 'BM1(86876.dat)' only have 0 clutches.at '':1 '86876 BM2 s1 = 86876 BM1 c2'
:: 86876 BM2 s1 = 86876 BM1 c3; // Warning: part 'BM1(86876.dat)' only have 0 clutches.at '':1 '86876 BM2 s1 = 86876 BM1 c3'

:: 86876 BM2 s2 = 86876 BM1 c1; // Warning: part 'BM1(86876.dat)' only have 0 clutches.at '':1 '86876 BM2 s2 = 86876 BM1 c1'
:: 86876 BM2 s2 = 86876 BM1 c2; // Warning: part 'BM1(86876.dat)' only have 0 clutches.at '':1 '86876 BM2 s2 = 86876 BM1 c2'
:: 86876 BM2 s2 = 86876 BM1 c3; // Warning: part 'BM1(86876.dat)' only have 0 clutches.at '':1 '86876 BM2 s2 = 86876 BM1 c3'

:: 86876 BM2 s3 = 86876 BM1 c1; // Warning: part 'BM1(86876.dat)' only have 0 clutches.at '':1 '86876 BM2 s3 = 86876 BM1 c1'
:: 86876 BM2 s3 = 86876 BM1 c2; // Warning: part 'BM1(86876.dat)' only have 0 clutches.at '':1 '86876 BM2 s3 = 86876 BM1 c2'
:: 86876 BM2 s3 = 86876 BM1 c3; // Warning: part 'BM1(86876.dat)' only have 0 clutches at '':1 '86876 BM2 s3 = 86876 BM1 c3'
:: //}

:: //{ // 7133,7133
:: 7133 BM1 c1 = 7133 BM2 s1; // Warning: part 'BM1(7133.dat)' only have 0 clutches.at '':1 '7133 BM1 c1 = 7133 BM2 s1'
:: 7133 BM1 c1 = 7133 BM2 s2; // Warning: part 'BM1(7133.dat)' only have 0 clutches.at '':1 '7133 BM1 c1 = 7133 BM2 s2'
:: 7133 BM1 c1 = 7133 BM2 s3; // Warning: part 'BM1(7133.dat)' only have 0 clutches.at '':1 '7133 BM1 c1 = 7133 BM2 s3'

:: 7133 BM1 c2 = 7133 BM2 s1; // Warning: part 'BM1(7133.dat)' only have 0 clutches.at '':1 '7133 BM1 c2 = 7133 BM2 s1'
:: 7133 BM1 c2 = 7133 BM2 s2; // Warning: part 'BM1(7133.dat)' only have 0 clutches.at '':1 '7133 BM1 c2 = 7133 BM2 s2'
:: 7133 BM1 c2 = 7133 BM2 s3; // Warning: part 'BM1(7133.dat)' only have 0 clutches.at '':1 '7133 BM1 c2 = 7133 BM2 s3'

:: 7133 BM1 c3 = 7133 BM2 s1; // Warning: part 'BM1(7133.dat)' only have 0 clutches.at '':1 '7133 BM1 c3 = 7133 BM2 s1'
:: 7133 BM1 c3 = 7133 BM2 s2; // Warning: part 'BM1(7133.dat)' only have 0 clutches.at '':1 '7133 BM1 c3 = 7133 BM2 s2'
:: 7133 BM1 c3 = 7133 BM2 s3; // Warning: part 'BM1(7133.dat)' only have 0 clutches.at '':1 '7133 BM1 c3 = 7133 BM2 s3'

:: 7133 BM1 s1 = 7133 BM2 c1; // Warning: part 'BM1(7133.dat)' only have 0 clutches.at '':1 '7133 BM1 s1 = 7133 BM2 c1'
:: 7133 BM1 s1 = 7133 BM2 c2; // Warning: part 'BM2(7133.dat)' only have 0 clutches.at '':1 '7133 BM1 s1 = 7133 BM2 c2'
:: 7133 BM1 s1 = 7133 BM2 c3; // Warning: part 'BM2(7133.dat)' only have 0 clutches.at '':1 '7133 BM1 s1 = 7133 BM2 c3'

:: 7133 BM1 s2 = 7133 BM2 c1; // Warning: part 'BM2(7133.dat)' only have 0 clutches.at '':1 '7133 BM1 s2 = 7133 BM2 c1'
:: 7133 BM1 s2 = 7133 BM2 c2; // Warning: part 'BM2(7133.dat)' only have 0 clutches.at '':1 '7133 BM1 s2 = 7133 BM2 c2'
:: 7133 BM1 s2 = 7133 BM2 c3; // Warning: part 'BM2(7133.dat)' only have 0 clutches.at '':1 '7133 BM1 s2 = 7133 BM2 c3'

:: 7133 BM1 s3 = 7133 BM2 c1; // Warning: part 'BM2(7133.dat)' only have 0 clutches.at '':1 '7133 BM1 s3 = 7133 BM2 c1'
:: 7133 BM1 s3 = 7133 BM2 c2; // Warning: part 'BM2(7133.dat)' only have 0 clutches.at '':1 '7133 BM1 s3 = 7133 BM2 c2'
:: 7133 BM1 s3 = 7133 BM2 c3; // Warning: part 'BM2(7133.dat)' only have 0 clutches.at '':1 '7133 BM1 s3 = 7133 BM2 c3'

:: 7133 BM2 c1 = 7133 BM1 s1; // Warning: part 'BM2(7133.dat)' only have 0 clutches.at '':1 '7133 BM2 c1 = 7133 BM1 s1'
:: 7133 BM2 c1 = 7133 BM1 s2; // Warning: part 'BM2(7133.dat)' only have 0 clutches.at '':1 '7133 BM2 c1 = 7133 BM1 s2'
:: 7133 BM2 c1 = 7133 BM1 s3; // Warning: part 'BM2(7133.dat)' only have 0 clutches.at '':1 '7133 BM2 c1 = 7133 BM1 s3'

:: 7133 BM2 c2 = 7133 BM1 s1; // Warning: part 'BM2(7133.dat)' only have 0 clutches.at '':1 '7133 BM2 c2 = 7133 BM1 s1'
:: 7133 BM2 c2 = 7133 BM1 s2; // Warning: part 'BM2(7133.dat)' only have 0 clutches.at '':1 '7133 BM2 c2 = 7133 BM1 s2'
:: 7133 BM2 c2 = 7133 BM1 s3; // Warning: part 'BM2(7133.dat)' only have 0 clutches.at '':1 '7133 BM2 c2 = 7133 BM1 s3'

:: 7133 BM2 c3 = 7133 BM1 s1; // Warning: part 'BM2(7133.dat)' only have 0 clutches.at '':1 '7133 BM2 c3 = 7133 BM1 s1'
:: 7133 BM2 c3 = 7133 BM1 s2; // Warning: part 'BM2(7133.dat)' only have 0 clutches.at '':1 '7133 BM2 c3 = 7133 BM1 s2'
:: 7133 BM2 c3 = 7133 BM1 s3; // Warning: part 'BM2(7133.dat)' only have 0 clutches.at '':1 '7133 BM2 c3 = 7133 BM1 s3'

:: 7133 BM2 s1 = 7133 BM1 c1; // Warning: part 'BM1(7133.dat)' only have 0 clutches.at '':1 '7133 BM2 s1 = 7133 BM1 c1'
:: 7133 BM2 s1 = 7133 BM1 c2; // Warning: part 'BM1(7133.dat)' only have 0 clutches.at '':1 '7133 BM2 s1 = 7133 BM1 c2'
:: 7133 BM2 s1 = 7133 BM1 c3; // Warning: part 'BM1(7133.dat)' only have 0 clutches.at '':1 '7133 BM2 s1 = 7133 BM1 c3'

:: 7133 BM2 s2 = 7133 BM1 c1; // Warning: part 'BM1(7133.dat)' only have 0 clutches.at '':1 '7133 BM2 s2 = 7133 BM1 c1'
:: 7133 BM2 s2 = 7133 BM1 c2; // Warning: part 'BM1(7133.dat)' only have 0 clutches.at '':1 '7133 BM2 s2 = 7133 BM1 c2'
:: 7133 BM2 s2 = 7133 BM1 c3; // Warning: part 'BM1(7133.dat)' only have 0 clutches.at '':1 '7133 BM2 s2 = 7133 BM1 c3'

:: 7133 BM2 s3 = 7133 BM1 c1; // Warning: part 'BM1(7133.dat)' only have 0 clutches.at '':1 '7133 BM2 s3 = 7133 BM1 c1'
:: 7133 BM2 s3 = 7133 BM1 c2; // Warning: part 'BM1(7133.dat)' only have 0 clutches.at '':1 '7133 BM2 s3 = 7133 BM1 c2'
:: 7133 BM2 s3 = 7133 BM1 c3; // Warning: part 'BM1(7133.dat)' only have 0 clutches at '':1 '7133 BM2 s3 = 7133 BM1 c3'
:: //}

rem the below block wont work yet because multi line is not supported by this batch script yet.

:: //{ // <TEST>,<TEST>
:: 1x1DummySlab SB1 #3; ^
   1x1DummySlab SB2 #5 #yo16; ^
   SB1 c1 = NULL;
:: 1x1DummySlab SB98 #6 c1 = 1x1DummySlab SB99 #9 #yo16  s1;
:: //}

:: [LS_END]