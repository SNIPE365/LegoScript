@echo off
setlocal enabledelayedexpansion

set Threads=0
for /F %%A in (LStests/crashes.txt) do (    
  echo '%%A'
  start /b cmd /c timeout 2 >nul
  set /a Threads=!Threads!+1
  if !Threads! == 64 (
    set Threads=0
    call :WaitFinish
  )
)

echo Waiting for processes to finish
call :WaitFinish
echo Done!
goto :EOF

:WaitFinish
  tasklist /FI "IMAGENAME eq timeout.exe" /NH | find /I "timeout" >nul
  if %ERRORLEVEL% == 1 GOTO :EOF
  timeout 1 >nul
goto :WaitFinish


