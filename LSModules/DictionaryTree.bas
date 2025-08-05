type TreeNodeFwd as TreeNode ptr

'0...9 A...Z  _
const iFirstAscii = asc("0")-1 , iLastAscii = asc("_")

type TreeNode
   as ubyte iMax,iCount
   as boolean bConst 
   union
      pzFinal as zstring ptr      
      apNext(iFirstAscii to iLastAscii) as TreeNodeFwd
   end union
end type

static shared as uinteger g_uTreeSize , g_uTotalEntries

function AddEntry( ptNode as TreeNode ptr ,  sName as string , sValue as string , bConst as boolean = false , bOverwrite as boolean = false ) as zstring ptr
   
   for N as long = 0 to len(sName)-1
      var iChar = sName[N] : if iChar = asc("#") then iChar = asc("^")
      if iChar >= asc("a") andalso iChar <= asc("z") then iChar -= (asc("a")-asc("A"))
      if iChar <= iFirstAscii orelse iChar > iLastAscii then return 0
      var ptNext = ptNode->apNext(iChar)
      if ptNext = 0 then 
         ptNext = new TreeNode 
         ptNode->apNext(iChar) = ptNext : ptNode->iCount += 1
         g_uTotalEntries += 1 : g_uTreeSize += sizeof(TreeNode)
      end if
      ptNode = ptNext
   next N
   if ptNode->pzFinal then
      if bOverwrite=false then return 0            
      delete( ptNode->pzFinal ) : g_uTotalEntries -= 1
   end if
   ptNode->bConst = bConst
   ptNode->pzFinal = new ubyte [len(sValue)+1]
   *ptNode->pzFinal = sValue : g_uTotalEntries += 1
   return ptNode->pzFinal
   
end function
function FindEntry( ptNode as TreeNode ptr , sName as string ) as zstring ptr
   for N as long = 0 to len(sName)-1
      var iChar = sName[N] : if iChar = asc("#") then iChar = asc("^")
      if iChar >= asc("a") andalso iChar <= asc("z") then iChar -= (asc("a")-asc("A"))
      if iChar <= iFirstAscii orelse iChar > iLastAscii then return 0
      ptNode = ptNode->apNext(iChar)
      if ptNode = 0 then return 0
   next N
   return ptNode->pzFinal
end function
private function RemoveEntry_Internal( ptNode as TreeNode ptr , sName as string , iPos as long ) as long
   if ptNode = 0 then return 0
   if iPos < len(sName) then
      var iChar = sName[iPos] : if iChar = asc("#") then iChar = asc("^")
      if iChar >= asc("a") andalso iChar <= asc("z") then iChar -= (asc("a")-asc("A"))
      if iChar <= iFirstAscii orelse iChar > iLastAscii then return 0
      iPos =  RemoveEntry_Internal( ptNode->apNext(iChar) , sName , iPos+1 )
      if iPos = 0 then return 0
      delete ptNode->apNext(iChar) : ptNode->apNext(iChar) = 0 : ptNode->iCount -= 1      
      g_uTreeSize -= sizeof(TreeNode) : g_uTotalEntries -= 1
      if ptNode->pzFinal = 0 andalso ptNode->iCount = 0 then return 1
      return 0
   end if
   if ptNode->pzFinal  then 
      if ptNode->bConst then return 0
      g_uTotalEntries -= 1
      delete( ptNode->pzFinal ) : ptNode->pzFinal = 0
   end if
   return (ptNode->iCount)=0
end function
function RemoveEntry( ptNode as TreeNode ptr , sName as string ) as boolean
   var iTemp = g_uTotalEntries
   RemoveEntry_Internal( ptNode , sName , 0 )
   return iTemp > g_uTotalEntries
end function
sub RemoveAllEntries( ptNode  as TreeNode ptr , bRemoveConsts as boolean = false )
   if ptNode = 0 then exit sub
   if ptNode->pzFinal<>0 andalso (ptNode->bConst=false orelse bRemoveConsts) then 
      delete ptNode->pzFinal : ptNode->pzFinal = 0 
      g_uTotalEntries -= 1 : ptNode->bConst = false
   end if
   for N as long = iFirstAscii+1 to iLastAscii
      if ptNode->apNext(N) then
         RemoveAllEntries( ptNode->apnext(N) , bRemoveConsts )
         if ptNode->apNext(N)->iCount=0 andalso ptNode->apNext(N)->pzFinal=0 then
            delete ptNode->apNext(N) : ptNode->apNext(N) = 0 : ptNode->iCount -= 1      
            g_uTreeSize -= sizeof(TreeNode) : g_uTotalEntries -= 1
         end if
      end if
   next N
end sub

#if 0
   dim as TreeNode tDefineList ': tDefineList.iCount = 1
   
   print AddEntry( @tDefineList , "hello" , "world" )
   print AddEntry( @tDefineList , "hello" , "not world" , , false )
   print *FindEntry( @tDefineList , "hello" )
   
   
   'Remove test
   #if 0
      AddEntry( @tDefineList , "Normal" , "Normal" )
      AddEntry( @tDefineList , "Const" , "Const" , true )
      print g_uTotalEntries
      RemoveAllEntries( @tDefineList )
      print g_uTotalEntries
      RemoveAllEntries( @tDefineList , true )
      if g_uTotalEntries then print "Failed to remove all entries"      
      AddEntry( @tDefineList , "Entries" , "Entries" )   
      RemoveEntry( @tDefineList , "Entries" )   
      AddEntry( @tDefineList , "Entries" , "Entries" )   
      AddEntry( @tDefineList , "Hello" , "Hello" )   
      AddEntry( @tDefineList , "Hell" , "Hell" )   
      AddEntry( @tDefineList , "All" , "All" )
      print g_uTotalEntries '19
      if RemoveEntry( @tDefineList , "Hell" ) = false then print "Failed to remove entry"
      print g_uTotalEntries '18
      if RemoveEntry( @tDefineList , "Hello" ) = false then print "Failed to remove entry"
      print g_uTotalEntries '12
      if RemoveEntry( @tDefineList , "Hell" ) then print "Succeded into removing an entry that does not exist"
      print g_uTotalEntries '12
      RemoveAllEntries( @tDefineList , true )
      print g_uTotalEntries '0
   #endif
   
   'benchmark test
   #if 0
      dim as long iCount
      dim as double dTmr
      
      dim as string sName="Hello",sValue="World"
      
      dTmr = timer : iCount = 0
      while (timer-dTmr) < 1
         AddEntry( @tDefineList , "Hello" , "World" )
         iCount += 1
      wend
      print "Added " & iCount & " entries/s"
      
      dTmr = timer : iCount = 0
      while (timer-dTmr) < 1
         AddEntry( @tDefineList , sName , sValue )
         iCount += 1
      wend
      print "Added " & iCount & " entries/s (pre-string)"
      
      dTmr = timer : iCount = 0
      while (timer-dTmr) < 1
         FindEntry( @tDefineList , "hElLo" )
         iCount += 1
      wend
      print "Searched " & iCount & " entries/s"
      
      dTmr = timer : iCount = 0
      while (timer-dTmr) < 1
         FindEntry( @tDefineList , sName )
         iCount += 1
      wend
      print "Searched " & iCount & " entries/s (pre-string)"
      
      dTmr = timer
      for N as long = 0 to 65535
         AddEntry( @tDefineList , "Entry" & cint(rnd*(1 shl 29)) , "Sample" )
      next N
      dTmr = timer-dTmr
      print "Added 65536 entries in " & csng(dTmr*1000) & "ms"
      print "leading to " & g_uTotalEntries & " entries and " & (g_uTreeSize+1023)\1024 & "kb of overhead"
      sleep
      
      dTmr = timer
      RemoveAllEntries( @tDefineList )
      dTmr = timer-dTmr
      print "Removed all entries in " & csng(dTmr*1000) & "ms"
   #endif   
   
   'memory test
   #if 0
      dim as string sFruits(...) = { _
         "Apple","Banana","Orange","Mango","Pineapple","Strawberry","Blueberry","Raspberry", _
         "Blackberry","Watermelon","Cantaloupe","Honeydew","Grapes","Kiwi","Papaya","Guava","Lychee", _
         "Passionfruit","Pomegranate","Cherry","Peach","Plum","Apricot","Nectarine","Fig","Date", _
         "Coconut","Lemon","Lime","Tangerine","Clementine","Mandarin","Grapefruit","Jackfruit", _
         "Durian","Dragonfruit","Starfruit","Mulberry","Gooseberry","Elderberry","Boysenberry", _
         "Currant","Persimmon","Jujube","Sapodilla","Rambutan","Longan","Soursop", _
         "Tamarind","UgliFruit","Salak","Quince","Cranberry","Barberry","Loquat","Breadfruit", _
         "Chempedak","Marang","Feijoa","Atemoya","Cupuacu","MiracleFruit","Medlar","Yuzu", _
         "Kumquat","Calamansi","BuddhasHand","HornedMelon","Bael","Lucuma","Santol","Mamoncillo", _
         "Hawthorn","Ackee","RoseApple","SugarApple","IndianFig","CactusPear","SeaGrape", _
         "MountainApple","VelvetApple","Cloudberry","Chokecherry","WhiteCurrant","RedCurrant", _
         "BlackCurrant","Bilberry","Jostaberry","Serviceberry","Huckleberry","Pawpaw","Naranjilla", _
         "CamuCamu","Langsat","Ambarella","Canistel","MonkeyOrange","Biriba","DesertLime","DavidsonsPlum", _
         "FingerLime","IllawarraPlum" _   
      }
      for N as long = 0 to ubound(sFruits)
         if AddEntry( @tDefineList , sFruits(N) , sFruits(N) )=0 then
            print "Failed to add '"+sFruits(N)+"'"
         end if
      next N
      print "database overhead: " & (g_uTreeSize+1023)\1024 & "kb"
   #endif
   
   sleep
#endif




      
      
      



