#define cMarginL _pct(1.25)
#define cMarginR _RightP(-1.25)
#define cMarginT _pct(3)
#define cRow(_N) _pct((5)*_N)    
'#define cBorderRow _BtN(wcRadOther,-19)
'#define cBigRow _pct(10)    

'#define cLabelWidS _pct(12)    
'#define cLabelWidB _pct(18)    

var IdPrevCtl=0 'previous control ID
    
#define _NextRow  _BtP(IdPrevCtl,0.5)    
#define _NextRowB _BtP(IdPrevCtl,1.5)    
#define _NextCol  _RtP(IdPrevCtl,1)
#define _NextCol0 _RtN(IdPrevCtl,0)
#define _SameCol  _LtN(IdPrevCtl,0)
#define _SameColR _LtP(IdPrevCtl,0.5)
#define _SameColL _LtP(IdPrevCtl,-.0.5)
#define _SameRow  _TpN(IdPrevCtl,0)

#define _SameRowU _TpP(IdPrevCtl,-0.5)
#define _SameRowD _TpP(IdPrevCtl,+0.5)
#define _SameRowDD _TpP(IdPrevCtl,+1)

'#define _SameRowS _TpP(IdPrevCtl,-0.5)
'#define _SameRowB _TpP(IdPrevCtl,+0.5)

#define ReferenceControl( _I ) IdPrevCtl = (_I)