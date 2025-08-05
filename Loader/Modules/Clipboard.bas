#ifndef __Main
  #error " Don't compile this one"
#endif  

#include once "windows.bi"

declare function SetClipboard(MYSTRING as string) as integer
declare function SetClipboardW(MYSTRING as wstring ptr) as integer
declare function GetClipboard() as string

function SetClipboard(MYSTRING as string) as integer  
  function = 0
  do  
    if OpenClipboard(NULL) = 0 then return 0
    if EmptyClipboard() = 0 then exit do
    dim as zstring ptr MYCLIPPTR
    dim as hglobal MYCLIPHAN
    MYCLIPHAN = GlobalAlloc(GMEM_MOVEABLE or GMEM_SHARE	, len(MYSTRING)+1 )
    MYCLIPPTR = GlobalLock(MYCLIPHAN)
    if MYCLIPHAN = 0 or MYCLIPPTR = 0 then exit do
    *MYCLIPPTR = MYSTRING
    GlobalUnlock(MYCLIPPTR)
    if SetClipboardData(CF_TEXT,MYCLIPHAN) = 0 then exit do
    function = 1 : exit do
  loop
  CloseClipboard()
end function
function SetClipboardW(MYSTRING as wstring ptr) as integer  
  if OpenClipboard(null) = 0 then return 0
  if EmptyClipboard() = 0 then return 0
  dim as wstring ptr MYCLIPPTR
  dim as hglobal MYCLIPHAN
  MYCLIPHAN = GlobalAlloc(GMEM_MOVEABLE or GMEM_SHARE	, len(*MYSTRING)*2+1 )
  MYCLIPPTR = GlobalLock(MYCLIPHAN)
  if MYCLIPHAN = 0 or MYCLIPPTR = 0 then return 0
  *MYCLIPPTR = *MYSTRING
  GlobalUnlock(MYCLIPPTR)
  if SetClipboardData(CF_UNICODETEXT,MYCLIPHAN) = 0 then return 0
  if CloseClipboard() = 0 then return 0
  return 1
end function

function GetClipboard() as string
  OpenClipboard(null)  
  dim as zstring ptr MYCLIPPTR
  dim as hglobal MYCLIPHAN
  MYCLIPHAN = GetClipboardData(CF_TEXT)
  MYCLIPPTR = GlobalLock(MYCLIPHAN)
  function = *MYCLIPPTR
  GlobalUnlock(MYCLIPPTR)  
  CloseClipboard()
end function

function GetBitmapFromClipboard() as any ptr
  if OpenClipboard(null) = 0 then return 0
  dim as BITMAPINFO ptr MYDIB
  dim as hglobal MYCLIPHAN
  #if 0
    MYCLIPHAN = GetClipboardData(CF_DIB)
    if MYCLIPHAN then
      MYDIB = GlobalLock(MYCLIPHAN)
      function = MYDIB
      with MYDIB->bmiHeader
        'print .biWidth , .biheight
      end with
      GlobalUnlock(MYDIB)  
      GlobalFree(MYCLIPHAN)
    else
      function = null
    end if
  #endif
  DeleteObject(GetClipboardData(CF_BITMAP))
  
  CloseClipboard()
end function