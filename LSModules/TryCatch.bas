'#define __fbc -gen gcc -O 3 -asm intel

#include once "crt.bi"
#include once "windows.bi"
#include once "crt/setjmp.bi"

#macro _Internal_Redefine_( _Name , _Value )
  '#print " ok"
  '#print _Name
  '#print _Value
  '#print " ok1"
  #if (not defined(_Name)) andalso _Name <> _Value
    #define _Name _Value
  #endif
  '#print " ok2"
#endmacro
#macro _Redefine_( _Name , _FUNC , _LIN , _Value )        
  #define __Temp__ _Value##_FUNC##_LIN  
  _Internal_Redefine_( _Name , __Temp__ )
  #undef __Temp__
#endmacro

#macro Try()
  #ifndef __TryCatchError__
    scope
      #ifdef _InsideTry_
        #error " another Try() without EndTry()"
        end scope
        #define __TryCatchError__
      #else      
        #define _InsideTry_        
        __FB_UNIQUEID_PUSH__( TryCatch )
        _Redefine_(_Catch_,__FB_UNIQUEID__( TryCatch ),__LINE__,CatchLabel)
        _Redefine_(_Catch2_,__FB_UNIQUEID__( TryCatch ),__LINE__,AfterCatch)        
        static __env as jmp_buf
        static __veh as any ptr
        if setjmp(@__env) then goto _Catch_        
      
        asm
          push offset 2f
          push 1      
          call _AddVectoredExceptionHandler@8
          jmp 1f
                
          2:      
          mov eax, [esp+4]   'EXCEPTION_POINTERS
          mov eax, [eax+4]   '->ContextRecord
          sub dword ptr [eax+offsetof(CONTEXT,ESP)], 12 'ret,arg2,arg1
          mov dword ptr [eax+offsetof(CONTEXT,EIP)], offset _longjmp
          mov eax, [eax+offsetof(CONTEXT,ESP)]
          mov dword ptr [eax+4], offset __env
          mov dword ptr [eax+8], 1            
          mov eax, -1 'EXCEPTION_CONTINUE_EXECUTION      
          ret 4
          
          1:
          mov [__veh], eax
        end asm
        scope
      #endif
  #endif  
#endmacro
#macro Try2(_FUN_)
  #ifndef __TryCatchError__
    scope
      #ifdef _InsideTry_
        #error " another Try() without EndTry()"
        end scope
        #define __TryCatchError__
      #else
        #define _InsideTry_        
        __FB_UNIQUEID_PUSH__( TryCatch )
        _Redefine_(_Catch_,_FUN_,__LINE__,CatchLabel)
        _Redefine_(_Catch2_,_FUN_,__LINE__,AfterCatch)        
        static __env as jmp_buf
        static __veh as any ptr
        if setjmp(@__env) then goto _Catch_        
      
        asm
          push offset 2f
          push 1      
          call _AddVectoredExceptionHandler@8
          jmp 1f
                
          2:      
          mov eax, [esp+4]   'EXCEPTION_POINTERS
          mov eax, [eax+4]   '->ContextRecord
          sub dword ptr [eax+offsetof(CONTEXT,ESP)], 12 'ret,arg2,arg1
          mov dword ptr [eax+offsetof(CONTEXT,EIP)], offset _longjmp
          mov eax, [eax+offsetof(CONTEXT,ESP)]
          mov dword ptr [eax+4], offset __env
          mov dword ptr [eax+8], 1            
          mov eax, -1 'EXCEPTION_CONTINUE_EXECUTION      
          ret 4
          
          1:
          mov [__veh], eax
        end asm
        scope
      #endif
  #endif  
#endmacro


  #define Throw() goto _Catch_

  #macro Catch()    
    #ifndef __TryCatchError__
        #if (not defined(_InsideTry_))
          #error " Catch() without Try()"
          #define __TryCatchError__
        #elseif defined(_InsideCatch2_)
          #error " more than one Catch() inside a Try()/EndTry() block"
          #define __TryCatchError__
        #else
          end scope
          #define _InsideCatch2_          
          scope
          #define _InsideCatch_
          goto _Catch2_              
          _Catch_:    
          scope
        #endif    
    #endif
  #endmacro
  #macro EndCatch()
    #ifndef __TryCatchError__
        #if (not defined(_InsideTry_))
          #error " EndCatch() without Try() (and Catch() inside)"
          #define __TryCatchError__
        #elseif (not defined(_InsideCatch_))
          #error " EndCatch() without Catch()"
          end scope
          _Catch_:
          #define __TryCatchError__
        #else
          end scope
          '#undef _InsideCatch_
          _Catch2_:            
          end scope
        #endif
    #endif
  #endmacro
  
  #define IfCatch(xcept) Catch()
  #macro Finally()
    #ifndef __TryCatchError__
      #if (not defined(_InsideTry_))
        #error " Finally() without Try()"
        #define __TryCatchError__
      #elseif (not defined(_InsideCatch2_))
        #error " Finally() without Catch() (it must appear AFTER the EndCatch())"
        end scope
        _Catch_:      
        #define __TryCatchError__
      #elseif (defined(_InsideCatch_))
        end scope
        end scope
        #error " Finally() inside catch() block"  
        _Catch2_:
        #define __TryCatchError__
        
      #else
        scope
          #define _InsideFinally_
      #endif
    #endif
  #endmacro
  #macro EndFinally()      
    #ifndef __TryCatchError__
      #if (not defined(_InsideFinally_))
        #error " EndFinally() without Finally()"
      #else
        end scope
      #endif
    #endif
  #endmacro

#macro EndTry()
    #ifndef __TryCatchError__
      #if (not defined(_InsideTry_))
        #error " EndTry() without Try()"      
      #elseif (defined(_InsideCatch_))
        end scope
        #error " EndTry() inside Catch() block"
      #elseif (defined(_InsideFinally_))
        end scope
        #error " EndTry() inside Finally() block"
      #else
        #if (not defined(_InsideCatch2_))
          end scope
          goto _Catch2_
          _Catch_:    
          _Catch2_:
        #endif
        asm      
          push [__veh]
          call _RemoveVectoredExceptionHandler@4
        end asm
      #endif
    #endif
    #undef __TryCatchError__
    __FB_UNIQUEID_POP__( TryCatch )
  end scope
#endmacro

#if 0
  do
    Try()
      scope        
        puts("before error")  
        dim as integer A = 32
        asm ud2
                
        Catch()
          puts("Exception...")          
        EndCatch()    
        
        Finally()
          puts("after catch/try")
        EndFinally()
        
      end scope
      
    EndTry()
    
    puts("after try")
    
    #if 1
    Try()
      Catch()
      EndCatch()
    EndTry()
    #endif
  loop
  
  sleep
#endif
  