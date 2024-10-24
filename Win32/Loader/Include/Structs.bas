#ifndef __Main
  #error " Don't compile this one"
#endif  

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

#if 0
type StudInfo
   as single fX,fY,fZ
end type
type ClutchInfo as StudInfo
type AliasInfo as StudInfo
type AxleInfo as StudInfo
#endif

const cShadowMaxSecs = 8

enum SubpartType
   spUnknown
   spStud
   spClutch
   spAxle
   spAxlehole 
   spPin
   spPinhole   
end enum
enum ShadowScale
   ss_None
   ss_YOnly
   ss_ROnly
   ss_YandR
end enum   
enum ShadowCaps
   sc_None 'The shape is open ended. e.g. a male axle or female beam hole.
   sc_One  'The shape has one closed ending, which one depends on the gender. For male shapes it will be A (bottom) and for female shapes it will be B (top).
   sc_Two  'The shape is closed (blocked) at both sides. e.g. the male bar of a minifig suitcase handle.
   sc_A    'A: The bottom is closed / blocked. e.g. a stud.
   sc_B    'B: The top is closed / blocked. e.g. an anti stud.
end enum   
type ShadowGrid
   as byte  Xcnt,Zcnt   'negative values means CENTERED
   as ubyte Xstep,Zstep
end type   
enum ShadowSecShape '
   sss_Invalid
   sss_Round    ' R: Round.
   sss_Axle     ' A: Axle.
   sss_Square   ' S: Square.
   sss_FlexPrev '_L: Flexible radius wise extension to the previous block's specs. This will be needed for e.g. the tip of an technic connector pin. Although it is slightly larger it allows for (temporary) compression while sliding the pin inside e.g. a beam hole.
   sss_FlexNext 'L_: Same as _L but as an extension to the next section instead of the previous one.
end enum   
type ShadowSec
   bshape     as byte 'ShadowSecShape
   bLength    as byte 
   wFixRadius as short   
end type
enum ShadowInfoType
   sit_Invalid
   sit_Include
   sit_Cylinder
end enum   
type ShadowStruct
   bType:3    as ubyte     'ShadowInfoType 
   bSecCnt:3  as ubyte     'Number of secs in tSecs()
   bRecurse:2 as ubyte     'Recursion level (0 to 3) is enough?
   union
      bFlags     as ubyte
      type
         bFlagMirror  :1 as ubyte '0=None  , 1=Color Mirror
         bFlagMale    :1 as ubyte '0=Female, 1=Male
         bFlagCenter  :1 as ubyte 
         bFlagSlide   :1 as ubyte
         bFlagHasGrid :1 as ubyte
      end type
   end union
   bScale    as ubyte      'ShadowScale
   bCaps     as ubyte      'ShadowCaps
   fPosX     as single     'X position
   fPosY     as single     'Y position
   fPosZ     as single     'Y position
   fOri(9-1) as single     '3x3 matrix (orientation)
   tGrid     as ShadowGrid 'caps are replicated based on a grid
   tSecs(cShadowMaxSecs-1)  as ShadowSec  'max 8 secs
   'ID        as string
   'Group     as string
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
  'this info is filled dynamically based on studs/clutches etc... (also including the shadow info)
  iShadowCount    as long                  'number of entries in the shadow dynamic array
  paShadow        as ShadowStruct ptr
  as PartStruct tParts( (1 shl 25)-1 ) 'maximum number of parts (dynamic)
end type
type ModelList
   iFilenameOffset as long                 'offset for the file name string
   pModel          as DATFile ptr          'ptr to the model structure
end type   
