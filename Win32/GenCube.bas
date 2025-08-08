dim as integer iP

chdir exepath()
mkdir "cube"

open "CubeC.ls" for output as #2
for Y as long = -5 to 4
   dim as string sText
   for X as long = -5 to 4
      for Z as long = -5 to 4
         iP += 1 '24866 P ; 3005 B
         var iC = (sqr(X*X+Z*Z)+Y+100) mod 100
         sText += "3005 B" & iP & " #" & iC & " #xo" & X*20 & " #yo" & Y*8 & " #zo" & Z*20 & " s1 = NULL;" !"\r\n"
      next Z   
   next X
   'open "Cube\cube" & Y & ".ls" for output as #1 : print #1, sText : close #1
   'print #2, "#include ""Cube\cube" & Y & ".ls"""
   print #2, sText
next Y   
close #2

print "done"
sleep

