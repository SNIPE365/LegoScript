#include "crt.bi"

#ifndef HaveMain
#error "don't compile this"
#endif

function WildMatch( sWildText as string , sCompare as string , iCaseSensitive as boolean = false ) as boolean
  dim as integer iTxt, iCmp
  
  /' if any of them is empty... then result is direct '/
  if sCompare[0] = 0 then return false  
  do
    var iCT = sWildText[iTxt]
    iTxt += 1
    var iCC = sCompare[iCmp]
    iCmp += 1 
    /' #print iTxt-1;" ";chr(iCT),iCmp-1;" ";chr(iCC) '/
    select case iCT
    case 0        : return iCC = 0 /' once it text reachs end.. it's a success '/
    case asc("^"),asc("~") /' white space (at least 1, at least 0) '/
      dim as long iNum = 0
      do
        select case iCC
        case asc(" "),asc(!"\r"),asc(!"\n"),asc(!"\t") 
          iNum += 1 : iCC = sCompare[iCmp] : iCmp += 1
        case else
          if iCT=asc("^") andalso iNum=0 then return false /' must at least have one blank '/
          iCmp -= 1 : continue do,do /' continue repeating same char '/
        end select
      loop          
    case asc("?") : /' if it's a single char wild '/
      /' we're done if reached end of comparsion '/
      /' and it will be true if next wildtext is also done '/
      if iCC=0 then return sWildText[iTxt]=0        
    case asc("*")       
      var iCT2 = sWildText[iTxt]
      /' if matching anything after then it will be true if it's the end of wildtext '/
      if iCT2 = 0 then return true
      /' if is not another wildcard then must continue checking '/
      if iCT2 <> asc("?") andalso iCT2 <> asc("*") then         
        /' if end of compare text happened then it's false! '/
        if iCC = 0 then return false
        /' if found matching char then continue matching '/
        if iCT2 = asc("^") orelse asc("~") then
          select case iCC
          case asc(" "),asc(!"\r"),asc(!"\n"),asc(!"\t") 
            iCmp -= 1 : continue do
          end select
        elseif iCaseSensitive then
          if iCC=iCT2 then iTxt += 1: continue do
        else
          if ToLower(iCC)=ToLower(iCT2) then iTxt += 1: continue do
        end if
        /' otherwise goes back on wildtext (to compare against *) again '/
        iTxt -= 1 : continue do
      end if
      /' next is also a wildcard, so we will process that '/
    case else /' is a direct comparsion... '/
      /' if compare string finished or didnt match then we failed '/
      if iCC=0 then return false
      if iCaseSensitive then
        if iCC<>iCT then return false
      else
        if ToLower(iCC)<>ToLower(iCT) then return false
      end if
    end select
  loop
end function