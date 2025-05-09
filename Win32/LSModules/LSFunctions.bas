scope 'add separators
   var sSeparators = !"\9 \r\n/;"
   for N as long = 0 to len(sSeparators)-1
      g_bSeparators( sSeparators[N] ) or= stToken
   next N
   var sOperators  = !"="
   for N as long = 0 to len(sOperators)-1
      g_bSeparators( sOperators[N] ) or= stOperator
   next N
end scope

#define ErrInfo( _N ) (_N)

function ReadTokenNumber( sToken as string , iStart as long = 0 , bSigned as long = false ) as long
   dim as long iResult, iSign = 1
   if bSigned andalso sToken[iStart] = asc("-") then iStart += 1 : iSign = -1
   for N as long = iStart to len(sToken)-1
      select case sToken[N]
      case asc("0") to asc("9")
         iResult = iResult*10+(sToken[N]-asc("0"))
         if iResult < 0 then return ErrInfo(ecNumberOverflow)
      case else
         return ErrInfo(ecNotANumber)
      end select
   next N
   return iResult*iSign
end function
function IsTokenNumeric( sToken as string , iStart as long = 0 ) as long
   for N as long = iStart to len(sToken)-1
      if (cuint(sToken[N])-asc("0")) > 9 then return false
   next N
   return true
end function
function IsPrimative( sToken as string ) as long
   if len(sToken)=0 then return false
   for N as long = 0 to len(sToken)-1
      select case sToken[0]
      case asc("a") to asc("z"),asc("0") to asc("9"),asc("_")
         rem valid chars for primatives
      case else
         return false
      end select
   next N
   return true
end function
function IsValidPartName( sToken as string ) as long   
   if len(sToken)=0 then return false
   select case sToken[0]
   case asc("A") to asc("Z")
      rem valid initial chars for part names
   case else
      return false
   end select
   for N as long = 1 to len(sToken)-1
      select case sToken[N]
      case asc("A") to asc("Z"),asc("a") to asc("z")
         rem valid chars for part names
      case asc("0") to asc("9"),asc("_")
         rem valid chars for part names
      case else
         return false
      end select
   next N
   return true 
end function

function ParseColor( sToken as string ) as long
   var iLen = len(sToken), bHasHex = false, iTokenStart = 1
   if iLen < 1 orelse sToken[0] <> asc("#") then return ErrInfo(ecFailedToParse)
   dim as ulong uColor
   if (iLen-iTokenStart) = 6 then '#RRGGBB
      for N as long = iTokenStart to iLen-1
         select case sToken[N]
         case asc("0") to asc("9"): uColor = uColor*16+sToken[N]-asc("0")
         case asc("a") to asc("f"): uColor = uColor*16+sToken[N]-asc("a")+10
         case asc("A") to asc("F"): uColor = uColor*16+sToken[N]-asc("A")+10
         case else: return ErrInfo(ecFailedToParse)
         end select
      next N
      return uColor+&h1000000
   elseif (iLen-iTokenStart) = 4 then '#0RGB
      if sToken[iTokenStart]=asc("0") then
         iTokenStart += 1 : bHasHex = true
      end if
   end if
   if (iLen-iTokenStart) = 3 then '#RGB
      if sToken[iTokenStart]=asc("0") then bHasHex = 1
      for N as long = iTokenStart to iLen-1
         select case sToken[N]
         case asc("0") to asc("9"): uColor = uColor*256+(((sToken[N]-asc("0")   )*255)\15)
         case asc("a") to asc("f"): uColor = uColor*256+(((sToken[N]-asc("a")+10)*255)\15) : bHasHex = 1
         case asc("A") to asc("F"): uColor = uColor*256+(((sToken[N]-asc("A")+10)*255)\15) : bHasHex = 1
         case else: return ErrInfo(ecFailedToParse)
         end select
      next N
      if bHasHex then return uColor+&h1000000
   end if
   'decimal color index
   uColor = 0
   for N as long = iTokenStart to iLen-1
      select case sToken[N]
      case asc("0") to asc("9"): uColor = uColor*10+sToken[N]-asc("0")
      case else: return ErrInfo(ecFailedToParse)
      end select      
      if uColor > 10999 then return ErrInfo(ecFailedToParse)
   next N
   return uColor
end function

function FindPartName( sName as string ) as long
   if len(sName) < 1 then return ErrInfo(ecNotFound)
   for N as long = 1 to g_iPartCount-1
      with g_tPart(N)
         if .sName = sName then return N
      end with
   next N
   return ErrInfo(ecNotFound)
end function
function FindModelIndex( sPart as string ) as long
   'g_sFilenames '/255{Index}/0'Name'/0'
   var iPos = instr(g_sFilenames,"\"+lcase(sPart)+".dat")-1
   if iPos<0 then return ErrInfo(ecNotFound)   
   do 
      iPos -= 1
      if g_sFilenames[iPos]=0 then exit do
   loop
   return *cptr(long ptr,@g_sFilenames[iPos-4])
end function
function LoadPartModel( byref tPart as PartStructLS ) as long
   with tPart      
      if .iModelIndex >= 0 then return ErrInfo(ecSuccess) 'already loaded
      'load model
      dim as string sModel
      if LoadFile( .sPrimative , sModel ) = 0 then 'LoadLDR::LoadFile
         return ErrInfo(ecFailedToLoad) 'part failed to load file
      end if
      var pModel = LoadModel( strptr(sModel) , .sPrimative ) 'LoadLDR::LoadModel
      if pModel=0 then return ErrInfo(ecFailedToParse)                      'part failed to parse
      .iModelIndex = pModel->iModelIndex             
      .sPrimative = mid(.sPrimative,instrrev(.sPrimative,"\")+1)      
      'generate snap if not generated yet
      'var pModel = g_tModels(.iModelIndex).pModel
      if pModel->pData = 0 then   
         pModel->pData = new PartSnap
         var pSnap = cptr(PartSnap ptr,pModel->pData)
         SnapModel( pModel , *pSnap )         
      end if
      'calculate model size
      'SizeModel( pModel , .tSize ) 'Model::SizeModel
      'deteact part cathegory
      .bPartCat = DetectPartCathegory( pModel ) 'Model::DetectPartCathegory
   end with
   return ErrInfo(ecSuccess)
end function
function AddPartName( sName as string , sPart as string ) as long   
         
   'skip '0 prefix (as no part name start with a '0')
   'var bPartPrefix =  (sPart[0]=asc("0"))
   'if bPartPrefix then with *Cast_fbStr(sPart) : .pzData += 1 : .iLen -= 1 : end with
   if (g_iPartCount > ubound(g_tPart)) then
      redim preserve g_tPart( ubound(g_tPart)+_cPartMin+1 )
   end if
   
   var iIndex = FindModelIndex( sPart )
   memset( @g_tPart( g_iPartCount ) , 0 , sizeof(PartStructLS) )
   with g_tPart( g_iPartCount )
      .sName      = sName
      .sPrimative = sPart+".dat"
      .iModelIndex = -1 : .iColor = -1
      
      if iIndex < 0 then         
         'if bPartPrefix then with *Cast_fbStr(sPart) : .pzData -= 1 : .iLen += 1 : end with
         .bFoundPart = FindFile(.sPrimative)<>0 'part name not found
      else
         .bFoundPart = true 'part found previously
         .iModelIndex = iIndex
         'if bPartPrefix then with *Cast_fbStr(sPart) : .pzData -= 1 : .iLen += 1 : end with   
      end if
         
   end with   
   
   g_iPartCount += 1
   return g_iPartCount-1
   
end function
function AddConnection( byref tConn as PartConnLS ) as long   
   if (g_iConnCount > ubound(g_tConn)) then
      redim preserve g_tConn( ubound(g_tConn)+_cConnMin+1 )
   end if
   g_tConn( g_iConnCount ) = tConn : g_iConnCount += 1
   return g_iConnCount-1
end function

function SafeText( sInput as string ) as string
   dim as string sResult
   for N as long = 0 to len(sInput)-1
      select case sInput[N]      
      case 0 to 31,128 to 255 : sResult += "%"+hex(sInput[N],2)
      case else
         sResult += chr(sInput[N])
      end select
   next N
   return sResult
end function      
