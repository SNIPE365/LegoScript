@echo off
set F1=%userprofile%\Desktop\LS\Win32\ComboBox.bas"
set F2=%userprofile%\Desktop\LS\Win32\Loader\ViewModel.bas"
set F3=%userprofile%\Desktop\LS\Win32\Loader\LoadLDR.bas"
set F4=%userprofile%\Desktop\LS\Win32\Loader\Modules\Model.bas"

start %F1%
timeout 1
start %F2%
start %F3%
start %F4%
rem start "%F5%" 
rem start "%F6%"
rem start "%F7%"