#include "fbgfx.bi"

screenres 640,480

dim as boolean bPressed

ScreenRes 640, 480
Do
   Dim e as fb.EVENT = any
   while (ScreenEvent(@e))
      Select Case e.type
      Case fb.EVENT_MOUSE_MOVE
         if bPressed then
            Print "mouse moved to " & e.x & "," & e.y & " (delta " & e.dx & "," & e.dy & ")"
         end if
      case fb.EVENT_MOUSE_BUTTON_PRESS
         if e.button = fb.BUTTON_LEFT then bPressed = true
      case fb.EVENT_MOUSE_BUTTON_RELEASE
         if e.button = fb.BUTTON_LEFT then bPressed = false
      end select
   wend
   sleep 1,1   
loop
