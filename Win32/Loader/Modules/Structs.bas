#ifndef NULL
  const NULL = cast(any ptr,0)
#endif

/'

**** checks ****
'does the format accept TABS instead of SPACES to separate the parameters???
****************

desktop\ldcad\shadow 
desktop\ldcad\ldraw\parts

1 <colour> x y z a b c d e f g h i <file>
2 <colour> x1 y1 z1 x2 y2 z2
3 <colour> x1 y1 z1 x2 y2 z2 x3 y3 z3
4 <colour> x1 y1 z1 x2 y2 z2 x3 y3 z3 x4 y4 z4
5 <colour> x1 y1 z1 x2 y2 z2 x3 y3 z3 x4 y4 z4
'/

'dim shared as string sFilenames
'redim shared as long aDatFiles()

type LineType1Struct          'line type 1
   as single fX,fY,fZ,fA,fB,fC,fD,fE,fF,fG,fH,fI
   as ulong  lModelIndex
end type
type LineType2Struct          'line type 2
   as single fX1,fY1,fZ1,fX2,fY2,fZ2
end type
type LineType3Struct          'line type 3
   as single fX1,fY1,fZ1,fX2,fY2,fZ2,fX3,fY3,fZ3
end type
type LineType4Struct          'line type 4
   as single fX1,fY1,fZ1,fX2,fY2,fZ2,fX3,fY3,fZ3,fX4,fY4,fZ4
end type
type LineType5Struct          'line type 5
   as single fX1,fY1,fZ1,fX2,fY2,fZ2,fX3,fY3,fZ3,fX4,fY4,fZ4
end type

type PartStruct
   bType      as ubyte   'type ID (line/primitves   
   union                 'flags
      bFlags  as ubyte   'optional flags/bitfield???
   end union   
   union                 'color/data
      wColour as ushort
      wData   as ushort
   end union
   union                 '> type specific data
      _1 as LineType1Struct
      _2 as LineType2Struct
      _3 as LineType3Struct
      _4 as LineType4Struct
      _5 as LineType5Struct      
   end union   
end type

type DATFile  
  iPartCount      as long                  'number of parts in this file
  dim as PartStruct tParts( (1 shl 25)-1 ) 'maximum number of parts (dynamic)
end type
type ModelList
   iFilenameOffset as long                 'offset for the file name string
   pModel          as DATFile ptr          'ptr to the model structure
end type   
