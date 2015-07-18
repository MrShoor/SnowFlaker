unit mutils;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$define NoInline}

interface

uses
  Classes, SysUtils;

const
  EPS = 0.000005;

type

  { TVec2 }

  TVec2 = record
    x, y: Single;
  end;

  { TVec3 }

  TVec3 = record
  case Byte of
    0: (x, y, z: Single);
    1: (xy: TVec2);
  end;

  { TMat2 }

  TMat2 = record
  private
    function GetCol(index: Integer): TVec2;               {$IFNDEF NoInline} inline; {$ENDIF}
    procedure SetCol(index: Integer; const Value: TVec2); {$IFNDEF NoInline} inline; {$ENDIF}
  public
    property Col[index: Integer]: TVec2 read GetCol write SetCol;
  case Byte of
    0: (f: array [0..1,0..1] of Single);
    1: (Row: array [0..1] of TVec2);
  end;

  { TMat3 }

  TMat3 = record
  private
    function GetCol(index: Integer): TVec3;               {$IFNDEF NoInline} inline; {$ENDIF}
    procedure SetCol(index: Integer; const Value: TVec3); {$IFNDEF NoInline} inline; {$ENDIF}
  public
    property Col[index: Integer]: TVec3 read GetCol write SetCol;
  case Byte of
    0: (f: array [0..2,0..2] of Single);
    1: (Row: array [0..2] of TVec3);
  end;

  TLine2D = record
  case Byte of
    0: (A, B, C: Single);
    1: (Norm: TVec2; Offset: Single);
    2: (V: TVec3);
  end;

  { TSegment2D }

  TSegment2D = record
  public
    Pt1, Pt2: TVec2;
    function Line(normalized: Boolean = False): TLine2D;
  end;

const
  IdentityMat3: TMat3 = (f: ((1,0,0), (0,1,0), (0,0,1)));
  ZeroMat3: TMat3 = (f: ((0,0,0), (0,0,0), (0,0,0)));

Operator + (const v1, v2: TVec2): TVec2; {$IFNDEF NoInline} inline; {$ENDIF}
Operator - (const v1, v2: TVec2): TVec2; {$IFNDEF NoInline} inline; {$ENDIF}
Operator * (const v1, v2: TVec2): TVec2; {$IFNDEF NoInline} inline; {$ENDIF}
Operator * (const v1: TVec2; s: Single): TVec2; {$IFNDEF NoInline} inline; {$ENDIF}
Operator / (const v1, v2: TVec2): TVec2; {$IFNDEF NoInline} inline; {$ENDIF}
Operator / (const v1: TVec2; s: Single): TVec2; {$IFNDEF NoInline} inline; {$ENDIF}
Operator - (const v: TVec2): TVec2; {$IFNDEF NoInline} inline; {$ENDIF}

Operator + (const v1, v2: TVec3): TVec3; {$IFNDEF NoInline} inline; {$ENDIF}
Operator - (const v1, v2: TVec3): TVec3; {$IFNDEF NoInline} inline; {$ENDIF}
Operator * (const v1, v2: TVec3): TVec3; {$IFNDEF NoInline} inline; {$ENDIF}
Operator * (const v1: TVec3; s: Single): TVec3; {$IFNDEF NoInline} inline; {$ENDIF}
Operator / (const v1, v2: TVec3): TVec3; {$IFNDEF NoInline} inline; {$ENDIF}
Operator / (const v1: TVec3; s: Single): TVec3; {$IFNDEF NoInline} inline; {$ENDIF}
Operator - (const v: TVec3): TVec3; {$IFNDEF NoInline} inline; {$ENDIF}

Operator + (const m1, m2: TMat2): TMat2; {$IFNDEF NoInline} inline; {$ENDIF}
Operator - (const m1, m2: TMat2): TMat2; {$IFNDEF NoInline} inline; {$ENDIF}
Operator * (const m1, m2: TMat2): TMat2; {$IFNDEF NoInline} inline; {$ENDIF}
Operator * (const m: TMat2; v: TVec2): TVec2; {$IFNDEF NoInline} inline; {$ENDIF}
Operator * (const m1: TMat2; s: Single): TMat2; {$IFNDEF NoInline} inline; {$ENDIF}
Operator / (const m1: TMat2; s: Single): TMat2; {$IFNDEF NoInline} inline; {$ENDIF}
Operator - (const m: TMat2): TMat2; {$IFNDEF NoInline} inline; {$ENDIF}

Operator + (const m1, m2: TMat3): TMat3; {$IFNDEF NoInline} inline; {$ENDIF}
Operator - (const m1, m2: TMat3): TMat3; {$IFNDEF NoInline} inline; {$ENDIF}
Operator * (const m1, m2: TMat3): TMat3; {$IFNDEF NoInline} inline; {$ENDIF}
Operator * (const m: TMat3; v: TVec3): TVec3; {$IFNDEF NoInline} inline; {$ENDIF}
Operator * (const m: TMat3; v: TVec2): TVec2; {$IFNDEF NoInline} inline; {$ENDIF}
Operator * (const m1: TMat3; s: Single): TMat3; {$IFNDEF NoInline} inline; {$ENDIF}
Operator / (const m1: TMat3; s: Single): TMat3; {$IFNDEF NoInline} inline; {$ENDIF}
Operator - (const m: TMat3): TMat3; {$IFNDEF NoInline} inline; {$ENDIF}

function Vec(const x, y: Single): TVec2; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Vec(const x, y, z: Single): TVec3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Vec(const xy: TVec2; z: Single): TVec3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Mat(const newX, newY: TVec2): TMat3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Mat(const newX, newY, newPos: TVec2): TMat3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Mat(const Rotate: Single): TMat3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Mat(const Rotate: Single; newPos: TVec2): TMat3; overload; {$IFNDEF NoInline} inline; {$ENDIF}

function Dot(const v1, v2: TVec2): Single; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Dot(const v1, v2: TVec3): Single; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Cross(const v1, v2: TVec2): Single; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Cross(const v1, v2: TVec3): TVec3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function LenSqr(const v: TVec2): Single; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function LenSqr(const v: TVec3): Single; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Len(const v: TVec2): Single; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Len(const v: TVec3): Single; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Normalize(const v: TVec2): TVec2; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Normalize(const v: TVec3): TVec3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function SetLen(const v: TVec2; newLen: Single): TVec2; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function SetLen(const v: TVec3; newLen: Single): TVec3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Lerp(const v1, v2: Single; s: Single): Single; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Lerp(const v1, v2: TVec2; s: Single): TVec2; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Lerp(const v1, v2: TVec3; s: Single): TVec3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Abs(const V: TVec2): TVec2; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Abs(const V: TVec3): TVec3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Min(const A, B: TVec2): TVec2; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Min(const A, B: TVec3): TVec3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Max(const A, B: TVec2): TVec2; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Max(const A, B: TVec3): TVec3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Clamp(const v: single; minval, maxval: Single): single; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Clamp(const v: TVec2; minval, maxval: Single): TVec2; overload; {$IFNDEF NoInline} inline; {$ENDIF}
function Clamp(const v: TVec3; minval, maxval: Single): TVec3; overload; {$IFNDEF NoInline} inline; {$ENDIF}

function Intersection(const Line1, Line2: TLine2D): TVec2; overload;{$IFNDEF NoInline} inline; {$ENDIF}
function Intersection(const Seg: TSegment2D; const Line: TLine2D; out IntPoint: TVec2): Boolean; overload;{$IFNDEF NoInline} inline; {$ENDIF}
function Distance(const Pt: TVec2; const Seg: TSegment2D): Single; overload;{$IFNDEF NoInline} inline; {$ENDIF}
function Projection(const Pt: TVec2; const Line: TLine2D): TVec2; overload;{$IFNDEF NoInline} inline; {$ENDIF}

function Transpose(const m: TMat2): TMat2; overload;{$IFNDEF NoInline} inline; {$ENDIF}
function Transpose(const m: TMat3): TMat3; overload;{$IFNDEF NoInline} inline; {$ENDIF}
function Det(const m: TMat2): single; overload;{$IFNDEF NoInline} inline; {$ENDIF}
function Det(const m: TMat3): single; overload;{$IFNDEF NoInline} inline; {$ENDIF}
function Inv(const m: TMat2): TMat2; overload;{$IFNDEF NoInline} inline; {$ENDIF}
function Inv(const m: TMat3): TMat3; overload;{$IFNDEF NoInline} inline; {$ENDIF}

function IsPow2(Num: LongInt): Boolean;
function NextPow2(Num: LongInt): LongInt;

function Bezier3(const pt1, pt2, pt3, pt4: TVec2; t: single): TVec2; overload; {$IFNDEF NoInline} inline; {$ENDIF}

implementation

uses Math;

function Vec(const x, y: Single): TVec2; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := x;
  Result.y := y;
end;

function Vec(const x, y, z: Single): TVec3; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := x;
  Result.y := y;
  Result.z := z;
end;

function Vec(const xy: TVec2; z: Single): TVec3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.xy := xy;
  Result.z := z;
end;

function Mat(const newX, newY: TVec2): TMat3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.Col[0] := Vec(newX, 0);
  Result.Col[1] := Vec(newY, 0);
  Result.Col[2] := Vec(0, 0, 1);
end;

function Mat(const newX, newY, newPos: TVec2): TMat3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.Col[0] := Vec(newX, 0);
  Result.Col[1] := Vec(newY, 0);
  Result.Col[2] := Vec(newPos, 1);
end;

function Mat(const Rotate: Single): TMat3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
var sn, cs: float;
begin
  sincos(Rotate, sn, cs);
  Result := Mat(Vec(cs,  sn), Vec(sn, -cs));
end;

function Mat(const Rotate: Single; newPos: TVec2): TMat3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
var sn, cs: float;
begin
  sincos(Rotate, sn, cs);
  Result := Mat( Vec(cs,  sn),
                 Vec(sn, -cs),
                 newPos        );
end;

Operator + (const v1, v2: TVec2): TVec2; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := v1.x + v2.x;
  Result.y := v1.y + v2.y;
end;

Operator - (const v1, v2: TVec2): TVec2; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := v1.x - v2.x;
  Result.y := v1.y - v2.y;
end;

Operator * (const v1, v2: TVec2): TVec2; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := v1.x * v2.x;
  Result.y := v1.y * v2.y;
end;

Operator * (const v1: TVec2; s: Single): TVec2; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := v1.x * s;
  Result.y := v1.y * s;
end;

Operator / (const v1, v2: TVec2): TVec2; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := v1.x / v2.x;
  Result.y := v1.y / v2.y;
end;

Operator / (const v1: TVec2; s: Single): TVec2; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result := v1 * (1/s);
end;

Operator - (const v: TVec2): TVec2; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := - v.x;
  Result.y := - v.y;
end;

Operator + (const v1, v2: TVec3): TVec3; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := v1.x + v2.x;
  Result.y := v1.y + v2.y;
  Result.z := v1.z + v2.z;
end;

Operator - (const v1, v2: TVec3): TVec3; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := v1.x - v2.x;
  Result.y := v1.y - v2.y;
  Result.z := v1.z - v2.z;
end;

Operator * (const v1, v2: TVec3): TVec3; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := v1.x * v2.x;
  Result.y := v1.y * v2.y;
  Result.z := v1.z * v2.z;
end;

Operator * (const v1: TVec3; s: Single): TVec3; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := v1.x * s;
  Result.y := v1.y * s;
  Result.z := v1.z * s;
end;

Operator / (const v1, v2: TVec3): TVec3; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := v1.x / v2.x;
  Result.y := v1.y / v2.y;
  Result.z := v1.z / v2.z;
end;

Operator / (const v1: TVec3; s: Single): TVec3; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result := v1 * (1/s);
end;

Operator - (const v: TVec3): TVec3; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := - v.x;
  Result.y := - v.y;
  Result.z := - v.z;
end;

operator+(const m1, m2: TMat2): TMat2;
begin
  Result.Row[0] := m1.Row[0] + m2.Row[0];
  Result.Row[1] := m1.Row[1] + m2.Row[1];
end;

operator-(const m1, m2: TMat2): TMat2;
begin
  Result.Row[0] := m1.Row[0] - m2.Row[0];
  Result.Row[1] := m1.Row[1] - m2.Row[1];
end;

operator*(const m1, m2: TMat2): TMat2;
var i, j: Integer;
begin
  for j := 0 to 1 do
    for i := 0 to 1 do
      Result.f[i, j] := Dot(m1.Row[i], m2.Col[j]);
end;

operator*(const m: TMat2; v: TVec2): TVec2;
begin
  Result.x := Dot(m.Row[0], v);
  Result.y := Dot(m.Row[1], v);
end;

operator*(const m1: TMat2; s: Single): TMat2;
begin
  Result.Row[0] := m1.Row[0] * s;
  Result.Row[1] := m1.Row[1] * s;
end;

operator/(const m1: TMat2; s: Single): TMat2;
begin
  Result := m1 * (1/s);
end;

operator-(const m: TMat2): TMat2;
begin
  Result.Row[0] := - m.Row[0];
  Result.Row[1] := - m.Row[1];
end;

Operator + (const m1, m2: TMat3): TMat3; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.Row[0] := m1.Row[0] + m2.Row[0];
  Result.Row[1] := m1.Row[1] + m2.Row[1];
  Result.Row[2] := m1.Row[2] + m2.Row[2];
end;

Operator - (const m1, m2: TMat3): TMat3; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.Row[0] := m1.Row[0] - m2.Row[0];
  Result.Row[1] := m1.Row[1] - m2.Row[1];
  Result.Row[2] := m1.Row[2] - m2.Row[2];
end;

Operator * (const m1, m2: TMat3): TMat3; {$IFNDEF NoInline} inline; {$ENDIF}
var i, j: Integer;
begin
  for j := 0 to 2 do
    for i := 0 to 2 do
      Result.f[i, j] := Dot(m1.Row[i], m2.Col[j]);
end;

Operator * (const m: TMat3; v: TVec3): TVec3; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := Dot(m.Row[0], v);
  Result.y := Dot(m.Row[1], v);
  Result.z := Dot(m.Row[2], v);
end;

Operator * (const m: TMat3; v: TVec2): TVec2; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := Dot(m.Row[0].xy, v);
  Result.y := Dot(m.Row[1].xy, v);
  Result := Result + m.Col[2].xy;
end;

Operator * (const m1: TMat3; s: Single): TMat3; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.Row[0] := m1.Row[0] * s;
  Result.Row[1] := m1.Row[1] * s;
  Result.Row[2] := m1.Row[2] * s;
end;

Operator / (const m1: TMat3; s: Single): TMat3; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result := m1 * (1/s);
end;

Operator - (const m: TMat3): TMat3; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.Row[0] := - m.Row[0];
  Result.Row[1] := - m.Row[1];
  Result.Row[2] := - m.Row[2];
end;

function Dot(const v1, v2: TVec2): Single; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result := v1.x * v2.x + v1.y * v2.y;
end;

function Dot(const v1, v2: TVec3): Single; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result := v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
end;

function Cross(const v1, v2: TVec2): Single; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result := v1.x * v2.y - v1.y * v2.x;
end;

function Cross(const v1, v2: TVec3): TVec3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  result.x := (v1.y*v2.z) - (v1.z*v2.y);
  result.y := (v1.z*v2.x) - (v1.x*v2.z);
  result.z := (v1.x*v2.y) - (v1.y*v2.x);
end;

function LenSqr(const v: TVec2): Single; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result := dot(v, v);
end;

function LenSqr(const v: TVec3): Single; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result := dot(v, v);
end;

function Len(const v: TVec2): Single; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result := sqrt(dot(v, v));
end;

function Len(const v: TVec3): Single; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result := sqrt(dot(v, v));
end;

function Normalize(const v: TVec2): TVec2; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result := v / Len(v);
end;

function Normalize(const v: TVec3): TVec3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result := v / Len(v);
end;

function SetLen(const v: TVec2; newLen: Single): TVec2; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result := v / Len(v) * newLen;
end;

function SetLen(const v: TVec3; newLen: Single): TVec3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result := v / Len(v) * newLen;
end;

function Lerp(const v1, v2: Single; s: Single): Single; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result := v1 + s * (v2 - v1);
end;

function Lerp(const v1, v2: TVec2; s: Single): TVec2; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := v1.x + s * (v2.x-v1.x);
  Result.y := v1.y + s * (v2.y-v1.y);
end;

function Lerp(const v1, v2: TVec3; s: Single): TVec3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := v1.x + s * (v2.x-v1.x);
  Result.y := v1.y + s * (v2.y-v1.y);
  Result.z := v1.z + s * (v2.z-v1.z);
end;

function Abs(const V: TVec2): TVec2;
begin
  Result.x := abs(V.x);
  Result.y := abs(V.y);
end;

function Abs(const V: TVec3): TVec3;
begin
  Result.x := abs(V.x);
  Result.y := abs(V.y);
  Result.z := abs(V.z);
end;

function Min(const A, B: TVec2): TVec2; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := Math.Min(A.x, B.x);
  Result.y := Math.Min(A.y, B.y);
end;
function Min(const A, B: TVec3): TVec3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := Min(A.x, B.x);
  Result.y := Min(A.y, B.y);
  Result.z := Min(A.z, B.z);
end;
function Max(const A, B: TVec2): TVec2; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := Max(A.x, B.x);
  Result.y := Max(A.y, B.y);
end;
function Max(const A, B: TVec3): TVec3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.x := Max(A.x, B.x);
  Result.y := Max(A.y, B.y);
  Result.z := Max(A.z, B.z);
end;
function Clamp(const v: single; minval, maxval: Single): single; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
    Result := min(maxval, max(minval, v));
end;
function Clamp(const v: TVec2; minval, maxval: Single): TVec2; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
    Result.x := min(maxval, max(minval, v.x));
    Result.y := min(maxval, max(minval, v.y));
end;
function Clamp(const v: TVec3; minval, maxval: Single): TVec3; overload; {$IFNDEF NoInline} inline; {$ENDIF}
begin
    Result.x := min(maxval, max(minval, v.x));
    Result.y := min(maxval, max(minval, v.y));
    Result.z := min(maxval, max(minval, v.z));
end;

function IsPow2(Num: LongInt): Boolean;
begin
  Result := (Num and -Num) = Num;
end;

function NextPow2(Num: LongInt): LongInt; //http://graphics.stanford.edu/~seander/bithacks.html#RoundUpPowerOf2
begin
  Dec(Num);
  Num := Num Or (Num Shr 1);
  Num := Num Or (Num Shr 2);
  Num := Num Or (Num Shr 4);
  Num := Num Or (Num Shr 8);
  Num := Num Or (Num Shr 16);
  Result := Num + 1;
end;

function Bezier3(const pt1, pt2, pt3, pt4: TVec2; t: single): TVec2;
var t2: single;
begin
  t2 := 1 - t;
  Result := pt1*(t2*t2*t2) + pt2*(3*t*t2*t2) + pt3*(3*t*t*t2) + pt4*(t*t*t);
end;

function Intersection(const Line1, Line2: TLine2D): TVec2; overload;{$IFNDEF NoInline} inline; {$ENDIF}
var m: TMat2;
    b: TVec2;
begin
  m.Row[0] := Line1.Norm;
  m.Row[1] := Line2.Norm;
  b.x := - Line1.Offset;
  b.y := - Line2.Offset;
  Result := Inv(m) * b;
end;

function Intersection(const Seg: TSegment2D; const Line: TLine2D; out
  IntPoint: TVec2): Boolean;
var dir: TVec2;
begin
  IntPoint := Intersection(Line, Seg.Line);
  dir := Seg.Pt2 - Seg.Pt1;
  Result := (Dot(IntPoint - Seg.Pt1, dir) >= 0) and (Dot(IntPoint - Seg.Pt2, dir) <= 0);
end;

function Distance(const Pt: TVec2; const Seg: TSegment2D): Single;
var dir, v1, v2: TVec2;
    segline: TLine2D;
begin
  dir := Seg.Pt2 - Seg.Pt1;
  v1 := Pt - Seg.Pt1;
  v2 := Pt - Seg.Pt2;
  if (Dot(v1, dir) > 0) and (Dot(v2, dir) < 0) then
  begin
    segline := Seg.Line(True);
    Result := abs(dot(segline.Norm, Pt) + segline.C);
  end
  else
  begin
    Result := Min(LenSqr(v1), LenSqr(v2));
    Result := sqrt(Result);
  end;
end;

function Projection(const Pt: TVec2; const Line: TLine2D): TVec2;
var C: Single;
begin
  C := Dot(Pt, Line.Norm) + Line.Offset;
  Result := Pt + Line.Norm*C;
end;

function Transpose(const m: TMat2): TMat2; overload;{$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.Row[0] := m.Col[0];
  Result.Row[1] := m.Col[1];
end;

function Transpose(const m: TMat3): TMat3; overload;{$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result.Row[0] := m.Col[0];
  Result.Row[1] := m.Col[1];
  Result.Row[2] := m.Col[2];
end;

function Det(const m: TMat2): single; overload;{$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result := m.f[0,0]*m.f[1,1] - m.f[0,1]*m.f[1,0];
end;

function Det(const m: TMat3): single; overload;{$IFNDEF NoInline} inline; {$ENDIF}
begin
  Result := Dot(m.Row[0], Cross(m.Row[1], m.Row[2]));
end;

function Inv(const m: TMat2): TMat2; overload;{$IFNDEF NoInline} inline; {$ENDIF}
var
  D : Single;
begin
  D := 1 / Det(m);
  Result.f[0, 0] := m.f[1, 1] * D;
  Result.f[0, 1] := -m.f[0, 1] * D;
  Result.f[1, 0] := -m.f[1, 0] * D;
  Result.f[1, 1] := m.f[0, 0] * D;
end;

function Inv(const m: TMat3): TMat3; overload;{$IFNDEF NoInline} inline; {$ENDIF}
var
  D : Single;
begin
  D := 1 / Det(m);
  Result.f[0, 0] := (m.f[1, 1] * m.f[2, 2] - m.f[1, 2] * m.f[2, 1]) * D;
  Result.f[0, 1] := (m.f[2, 1] * m.f[0, 2] - m.f[0, 1] * m.f[2, 2]) * D;
  Result.f[0, 2] := (m.f[0, 1] * m.f[1, 2] - m.f[1, 1] * m.f[0, 2]) * D;
  Result.f[1, 0] := (m.f[1, 2] * m.f[2, 0] - m.f[1, 0] * m.f[2, 2]) * D;
  Result.f[1, 1] := (m.f[0, 0] * m.f[2, 2] - m.f[2, 0] * m.f[0, 2]) * D;
  Result.f[1, 2] := (m.f[1, 0] * m.f[0, 2] - m.f[0, 0] * m.f[1, 2]) * D;
  Result.f[2, 0] := (m.f[1, 0] * m.f[2, 1] - m.f[2, 0] * m.f[1, 1]) * D;
  Result.f[2, 1] := (m.f[2, 0] * m.f[0, 1] - m.f[0, 0] * m.f[2, 1]) * D;
  Result.f[2, 2] := (m.f[0, 0] * m.f[1, 1] - m.f[0, 1] * m.f[1, 0]) * D;
end;

{ TSegment2D }

function TSegment2D.Line(normalized: Boolean = False): TLine2D;
var v: TVec2;
begin
  v := Pt2 - Pt1;
  Result.Norm := Vec(-v.y, v.x);
  if normalized then Result.Norm := Normalize(Result.Norm);
  Result.Offset := -Dot(Pt1, Result.Norm);
end;

{ TMat2 }

function TMat2.GetCol(index: Integer): TVec2;
begin
  Result.x := f[0, index];
  Result.y := f[1, index];
end;

procedure TMat2.SetCol(index: Integer; const Value: TVec2);
begin
  f[0, index] := Value.x;
  f[1, index] := Value.y;
end;

{ TMat3 }

function TMat3.GetCol(index: Integer): TVec3;
begin
  Result.x := f[0, index];
  Result.y := f[1, index];
  Result.z := f[2, index];
end;

procedure TMat3.SetCol(index: Integer; const Value: TVec3);
begin
  f[0, index] := Value.x;
  f[1, index] := Value.y;
  f[2, index] := Value.z;
end;


initialization
    SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);

end.

