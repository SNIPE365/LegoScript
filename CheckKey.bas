'TODO: add option to include/exclude donor parts (alt + d)
'TODO: add option to include/exclude path parts (alt + p)
'TODO: add option to include/exclude shortcut parts (alt + s)
'TODO: add option to include/exclude color parts (alt + c)
'TODO: add option to include/exclose template parts (alt + t)
'TODO: add option to include/excluse alias parts (alt + a)
'TODO: add option to include/exclude printed parts (alt + shift + p)
'TODO: add option to include/exclose stickered parts (alt + shift + s)
'TODO: add option to include/exclude multi-moulded parts which are multi colorable (alt + m)
'TODO: add option to include/exclude stickers (ctrl+shift+s)

#include "fbgfx.bi"
#include "windows.bi"

#if 0
   -sc > alt-?
   
#endif

do
   var sKey = inkey
   'print (multikey(fb.SC_LSHIFT) or multikey(fb.SC_RSHIFT)) & !"\r";
   if len(sKey)=0 then sleep 1,1 : continue do
   print GetKeyState(VK_SHIFT),
   if len(sKey)>1 then
      print -sKey[1]
   else
      print sKey, sKey[0]
   end if
loop