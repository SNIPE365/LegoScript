#include "crt.bi"

dim as string sText
do
   var iChar = getchar()
   if iChar < 0 then exit do
   print chr(iChar);
loop 
