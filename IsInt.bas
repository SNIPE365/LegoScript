#ifndef HaveMain
#error "don't compile this"
#endif

function IsInt(num as string, ExpStr as string) as boolean  /' TODO I think ExpStr should be a string ptr here '/
   if len(num)=0 or len(ExpStr)=0 then return false
   for i as integer = 0 to len(num)-1 step 1 /' we can short-circuit this by only checking if the first and last '/
                                          /' characters of the string are numeric, rather than every character. '/
      if ExpStr[i] = asc("#") then
         #print "found # in string: 'ExpStr' at index", i
            select case asc(num,i)
               case asc("0") to asc("9")
                  
               case else
                  return false 'If any character is not numeric then the string is not a numeric string, return false.
         end select
      end if
   next

   return true ' If all characters are digits, return true and were done.
end function

dim num as string = "5" /' BUGBUG if n = "" we get true when it should be false. '/
#print len(num)
dim ExpStr as string = "a#b"

if IsInt(num, ExpStr) = true then
    color 3
    print "num is an integer string"
else
    color 4
    print "num is not an integer string"
end if

sleep()
