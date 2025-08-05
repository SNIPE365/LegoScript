#include "windows.bi"
#include "win\commdlg.bi"

dim as OPENFILENAME tOpen
dim as zstring*32768 zFile = any : zFile[0]=0
with tOpen
   .lStructSize = sizeof(tOpen)
   .hwndOwner = GetConsoleWindow()
   .lpstrFilter = @!"Lego Script Files\0*.ls\0All Files\0*.*\0\0"
   .nFilterIndex = 0 '.ls
   .lpstrFile = @zFile
   .nMaxFile = 32767
   .lpstrInitialDir = NULL
   .lpstrTitle = NULL
   .Flags = OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_NOCHANGEDIR
   if GetOpenFileName( @tOpen ) = 0 then end
   print "["+*.lpstrFile+"]"
   sleep
end with


