@echo off
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

:: [LS_BEGIN]
:: //{ 87087,87087
:: 87087 BM1 #15 c1 = 87087 BM2 #1  s1; // collision between BM1 c1 and BM2 s1
:: 87087 BM1 #15 s2 = 87087 BM2 #1  c1;
:: 87087 BM1 #15 s1 = 87087 BM2 #1  c1;
:: 87087 BM2 #1  c1 = 87087 BM1 #15 s1; // collision between BM2 c1 and BM1 s1
:: 87087 BM2 #1  c1 = 87087 BM1 #15 s2;
:: 87087 BM2 #1  s1 = 87087 BM1 #15 c1;
:: 87087 BM2 #15 s2 = 87087 BM1 #1  c1;
:: //}

:: //{ 47905,47905
:: 47905 BM1 #15 s1 = 47905 BM2 #1  c1;
:: 47905 BM1 #15 s2 = 47905 BM2 #1  c1;
:: 47905 BM1 #15 s3 = 47905 BM2 #1  c1;
:: 47905 BM2 #1  c1 = 47905 BM1 #15 s1;
:: 47905 BM2 #1  c1 = 47905 BM1 #15 s2;
:: 47905 BM2 #1  c1 = 47905 BM1 #15 s3;
:: 47905 BM1 #15 c1 = 47905 BM2 #1  s1;
:: 47905 BM1 #15 c1 = 47905 BM2 #1  s2;
:: 47905 BM1 #15 c1 = 47905 BM2 #1  s3;
:: 47905 BM2 #1  s1 = 47905 BM1 #15 c1;
:: 47905 BM2 #1  s2 = 47905 BM1 #15 c1;
:: 47905 BM2 #1  s3 = 47905 BM1 #15 c1;
:: //}

:: [LS_END]
