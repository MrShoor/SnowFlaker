unit untPrimitives;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, mutils, cutils;

type
  TPrimitivesCollection = class;

  { TPrimitive }

  TPrimitive = class (TWeakedObject)
  private
    FID: Integer;
    FCollection: TPrimitivesCollection;
    FMoved: Boolean;
    FSelected: Boolean;
  public
    property ID: Integer read FID;

    property Selected: Boolean read FSelected write FSelected;
    property Moved: Boolean read FMoved write FMoved;

    procedure Draw(const Transform: TMat3; const Canvas: TCanvas); virtual; abstract;
    procedure DrawFinal(const Transform: TMat3; const Canvas: TCanvas; const ClipLine1, ClipLine2: TLine2D); virtual; abstract;
    function HitTest(const Transform: TMat3; x,y: Integer; out distance: Single): Boolean; virtual; abstract;
    procedure Drag(const Transform: TMat3; FromX, FromY: Integer; ToX, ToY: Integer); virtual; abstract;

    constructor Create(Const AOwner: TPrimitivesCollection; const AID: Integer);
    destructor Destroy; override;
  end;

  TPrimitiveClass = class of TPrimitive;

  { TVertex }

  TVertex = class (TPrimitive)
  private
    FCoord: TVec2;
  public
    property Coord: TVec2 read FCoord write FCoord;

    procedure Draw(const Transform: TMat3; const Canvas: TCanvas); override;
    procedure DrawFinal(const Transform: TMat3; const Canvas: TCanvas; const ClipLine1, ClipLine2: TLine2D); override;
    function HitTest(const Transform: TMat3; x,y: Integer; out distance: Single): Boolean; override;
    procedure Drag(const Transform: TMat3; FromX, FromY: Integer; ToX, ToY: Integer); override;
  end;

  { TSpline }

  TSpline = class (TPrimitive)
  private
    const HitDistance_Offset = 4;
    const HitDistance_Line = 3;
  private
    FIsStraightLine: Boolean;

    FOffset1: TVec2;
    FOffset2: TVec2;
    FPt1: IWeakRef;
    FPt2: IWeakRef;
    function GetPt1: TVertex;
    function GetPt2: TVertex;
    procedure SetPt1(AValue: TVertex);
    procedure SetPt2(AValue: TVertex);
  public
    property Pt1: TVertex read GetPt1 write SetPt1;
    property Pt2: TVertex read GetPt2 write SetPt2;
    property Offset1: TVec2 read FOffset1 write FOffset1;
    property Offset2: TVec2 read FOffset2 write FOffset2;

    function IsStraightLine: Boolean;
    procedure SetStraightLine;
    function GetHitT(const Transform: TMat3; x,y: Integer; out T: Single): Boolean; overload;

    procedure Draw(const Transform: TMat3; const Canvas: TCanvas); override;
    procedure DrawFinal(const Transform: TMat3; const Canvas: TCanvas; const ClipLine1, ClipLine2: TLine2D); override;
    function HitTest(const Transform: TMat3; x,y: Integer; out ADistance: Single): Boolean; override;
    procedure Drag(const Transform: TMat3; FromX, FromY: Integer; ToX, ToY: Integer); override;
  end;

  { TFlood }

  TFlood = class (TPrimitive)
  private
    FCoord: TVec2;
  public
    property Coord: TVec2 read FCoord write FCoord;

    procedure Draw(const Transform: TMat3; const Canvas: TCanvas); override;
    procedure DrawFinal(const Transform: TMat3; const Canvas: TCanvas; const ClipLine1, ClipLine2: TLine2D); override;
    function HitTest(const Transform: TMat3; x,y: Integer; out distance: Single): Boolean; override;
    procedure Drag(const Transform: TMat3; FromX, FromY: Integer; ToX, ToY: Integer); override;
  end;

  { TPrimitivesCollection }

  TPrimitivesCollection = class (TObject)
  private
    FPrims: TList;
    FMaxID: Integer;
    function GenPrimID: Integer;

    function GetPrim(index: Integer): TPrimitive;
  protected
    procedure NotifyDestroy(Sender: TPrimitive); virtual;
  public
    property Prim[index: Integer]: TPrimitive read GetPrim; default;
    function Count: Integer;
    procedure Clear;

    function GetHitPrim(const Transform: TMat3; x,y: Integer): TPrimitive; overload;
    function GetHitPrim(const Transform: TMat3; x,y: Integer; PrimType: TPrimitiveClass): TPrimitive; overload;

    function CreateVertex: TVertex;
    function CreateSpline: TSpline;
    function CreateFlood: TFlood;
    function CalcMaxSize: TVec2;
    function CalcMaxRad: Single;

    procedure SaveToStream(const stream: TStream);
    procedure LoadFromStream(const stream: TStream);

    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses Math;

{ TFlood }

procedure TFlood.Draw(const Transform: TMat3; const Canvas: TCanvas);
var v: TVec2;
    Size: Integer;
begin
  v := Transform * FCoord;

  if FSelected then
  begin
    Canvas.Brush.Color:=Canvas.Pen.Color;
    Canvas.Brush.Style:=bsSolid;
  end
  else
    Canvas.Brush.Style:=bsClear;

  if Moved or Selected then
    Canvas.Pen.Width := 2
  else
    Canvas.Pen.Width := 1;

  if FMoved then
    Size := 5
  else
    Size := 4;

  Canvas.Rectangle(Trunc(v.x)-Size, Trunc(v.y)-Size, Trunc(v.x)+Size+1, Trunc(v.y)+Size+1);
  Canvas.Pen.Width := 1;
end;

procedure TFlood.DrawFinal(const Transform: TMat3; const Canvas: TCanvas; const ClipLine1, ClipLine2: TLine2D);
var v: TVec2;
begin
  if (Dot(ClipLine1.Norm, FCoord) + ClipLine1.Offset < 0) or
     (Dot(ClipLine2.Norm, FCoord) + ClipLine2.Offset < 0) then
     Exit;

  v := Transform * FCoord;

  Canvas.Brush.Style:=bsSolid;
  Canvas.Brush.Color:=clWhite;
  Canvas.FloodFill(Trunc(v.x), Trunc(v.y), clWhite, TFillStyle.fsBorder);
end;

function TFlood.HitTest(const Transform: TMat3; x, y: Integer; out
  distance: Single): Boolean;
var v: TVec2;
begin
  v.x := x;
  v.y := y;
  distance := Len( v - Transform*FCoord );
  Result := distance < 5;
end;

procedure TFlood.Drag(const Transform: TMat3; FromX, FromY: Integer; ToX,
  ToY: Integer);
var InvTrans: TMat3;
    FromPt, ToPt: TVec2;
begin
  InvTrans := Inv(Transform);
  FromPt := InvTrans * Vec(FromX, FromY);
  ToPt := InvTrans * Vec(ToX, ToY);
  FCoord := FCoord + (ToPt - FromPt);
end;

{ TPrimitive }

constructor TPrimitive.Create(const AOwner: TPrimitivesCollection; const AID: Integer);
begin
  FCollection := AOwner;
  FID := AID;
end;

destructor TPrimitive.Destroy;
begin
  if Assigned(FCollection) then
    FCollection.NotifyDestroy(Self);
  inherited Destroy;
end;

{ TSpline }

function TSpline.GetPt1: TVertex;
begin
  if FPt1 = Nil then Exit(Nil);
  Result := TVertex(FPt1.Obj);
end;

function TSpline.GetPt2: TVertex;
begin
  if FPt2 = Nil then Exit(Nil);
  Result := TVertex(FPt2.Obj);
end;

procedure TSpline.SetPt1(AValue: TVertex);
begin
  if AValue = nil then
    FPt1 := nil
  else
    FPt1 := AValue.WeakRef;
end;

procedure TSpline.SetPt2(AValue: TVertex);
begin
  if AValue = nil then
    FPt2 := nil
  else
    FPt2 := AValue.WeakRef;
end;

function TSpline.IsStraightLine: Boolean;
begin
  Result := FIsStraightLine;
end;

procedure TSpline.SetStraightLine;
begin
  if Pt1 = nil then Exit;
  if Pt2 = nil then Exit;
  FIsStraightLine := True;
  Offset1 := Lerp(Pt1.Coord, Pt2.Coord, 0.25) - Pt1.Coord;
  Offset2 := Lerp(Pt1.Coord, Pt2.Coord, 0.75) - Pt2.Coord;
end;

function TSpline.GetHitT(const Transform: TMat3; x, y: Integer; out T: Single): Boolean;
const TESS_COUNT = 30;
var pt: array [0..3] of TVec2;
    i: Integer;
    curpt: TVec2;
    seg: TSegment2D;
    dummy, dist: Single;
begin
  if Pt1 = nil then Exit;
  if Pt2 = nil then Exit;
  if Pt1.HitTest(Transform, x, y, dummy) then Exit;
  if Pt2.HitTest(Transform, x, y, dummy) then Exit;

  pt[0] := Transform * Pt1.Coord;
  pt[1] := Transform * (Pt1.Coord+Offset1);
  pt[2] := Transform * (Pt2.Coord+Offset2);
  pt[3] := Transform * Pt2.Coord;

  curpt := Vec(x, y);

  seg.Pt2 := Bezier3(pt[0],pt[1],pt[2],pt[3], 0);
  for i := 1 to TESS_COUNT do
  begin
    T := i/TESS_COUNT;
    seg.Pt1 := seg.Pt2;
    seg.Pt2 := Bezier3(pt[0],pt[1],pt[2],pt[3], T);
    dist := Distance(curpt, seg);
    if dist <= HitDistance_Line then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

procedure TSpline.Draw(const Transform: TMat3; const Canvas: TCanvas);
  procedure DrawPoint(const v: TVec2; size: Integer);
  begin
    Canvas.Ellipse(Trunc(v.x)-Size, Trunc(v.y)-Size, Trunc(v.x)+Size+1, Trunc(v.y)+Size+1);
  end;
const TESS_COUNT = 50;
var pt: array [0..3] of TVec2;
    i, tcount: Integer;
    v: TVec2;
    Size: Integer;
begin
  if Pt1 = nil then Exit;
  if Pt2 = nil then Exit;
  if FIsStraightLine then SetStraightLine;

  pt[0] := Transform * Pt1.Coord;
  pt[1] := Transform * (Pt1.Coord+Offset1);
  pt[2] := Transform * (Pt2.Coord+Offset2);
  pt[3] := Transform * Pt2.Coord;

  if Moved or Selected then
    Canvas.Pen.Width := 2
  else
    Canvas.Pen.Width := 1;

  v := Bezier3(pt[0],pt[1],pt[2],pt[3], 0);
  Canvas.MoveTo(Trunc(v.x), Trunc(v.y));

  if FIsStraightLine then tcount := 1 else tcount := TESS_COUNT;
  for i := 1 to tcount do
  begin
    v := Bezier3(pt[0],pt[1],pt[2],pt[3], i / tcount);
    Canvas.LineTo(Trunc(v.x), Trunc(v.y));
  end;
  Canvas.Pen.Width := 1;

  Size := 2;
  Canvas.Brush.Color:=Canvas.Pen.Color;
  Canvas.Brush.Style:=bsClear;
  if Moved or Selected then
  begin
    if not FIsStraightLine then
    begin
      Canvas.MoveTo(Trunc(pt[0].x), Trunc(pt[0].y));
      Canvas.LineTo(Trunc(pt[1].x), Trunc(pt[1].y));
      Canvas.MoveTo(Trunc(pt[3].x), Trunc(pt[3].y));
      Canvas.LineTo(Trunc(pt[2].x), Trunc(pt[2].y));
    end;

    if Selected then
      Canvas.Brush.Style:=bsSolid;

    if FMoved then Inc(Size);
    if FSelected then Inc(Size);
  end;
  DrawPoint(pt[1], Size);
  DrawPoint(pt[2], Size);
end;

procedure TSpline.DrawFinal(const Transform: TMat3; const Canvas: TCanvas; const ClipLine1, ClipLine2: TLine2D);
  function ClipSegment(var seg: TSegment2D): boolean;
  var IntPt: TVec2;
      Outside1, Outside2: Boolean;
  begin
    Outside1 := (Dot(ClipLine1.Norm, seg.Pt1) + ClipLine1.Offset) < 0;
    Outside2 := (Dot(ClipLine1.Norm, seg.Pt2) + ClipLine1.Offset) < 0;
    if Outside1 and Outside2 then Exit(False);
    if Intersection(seg, ClipLine1, IntPt) then
    begin
      if Outside1 then
        seg.Pt1 := IntPt
      else
        seg.Pt2 := IntPt;
    end;

    Outside1 := (Dot(ClipLine2.Norm, seg.Pt1) + ClipLine2.Offset) < 0;
    Outside2 := (Dot(ClipLine2.Norm, seg.Pt2) + ClipLine2.Offset) < 0;
    if Outside1 and Outside2 then Exit(False);
    if Intersection(seg, ClipLine2, IntPt) then
    begin
      if Outside1 then
        seg.Pt1 := IntPt
      else
        seg.Pt2 := IntPt;
    end;
    Result := True;
  end;
  procedure DrawSegment(const seg: TSegment2D);
  var v: TVec2;
  begin
    v := Transform * seg.Pt1;
    Canvas.MoveTo(Trunc(v.x), Trunc(v.y));
    v := Transform * seg.Pt2;
    Canvas.LineTo(Trunc(v.x), Trunc(v.y));
    Canvas.LineTo(Trunc(v.x)+1, Trunc(v.y)+1);
  end;

const TESS_COUNT = 50;
var pt: array [0..3] of TVec2;
    i: Integer;
    seg, segclipped: TSegment2D;
    tcount: Integer;
begin
  if Pt1 = nil then Exit;
  if Pt2 = nil then Exit;

  if FIsStraightLine then tcount := 1 else tcount := TESS_COUNT;

  pt[0] := Pt1.Coord;
  pt[1] := Pt1.Coord+Offset1;
  pt[2] := Pt2.Coord+Offset2;
  pt[3] := Pt2.Coord;

  Canvas.Pen.Width := 1;
  seg.Pt2 := Bezier3(pt[0],pt[1],pt[2],pt[3], 0);
  for i := 1 to tcount do
  begin
    seg.Pt1 := seg.Pt2;
    seg.Pt2 := Bezier3(pt[0],pt[1],pt[2],pt[3], i / tcount);
    segclipped := seg;
    if ClipSegment(segclipped) then
      DrawSegment(segclipped);
  end;
end;

function TSpline.HitTest(const Transform: TMat3; x, y: Integer; out ADistance: Single): Boolean;
const TESS_COUNT = 30;
var pt: array [0..3] of TVec2;
    i: Integer;
    curpt, dir: TVec2;
    seg: TSegment2D;
    dummy: Single;
    tcount: Integer;
begin
  Result := False;
  if Pt1 = nil then Exit;
  if Pt2 = nil then Exit;
  if Pt1.HitTest(Transform, x, y, dummy) then Exit;
  if Pt2.HitTest(Transform, x, y, dummy) then Exit;
  if FIsStraightLine then SetStraightLine;

  pt[0] := Transform * Pt1.Coord;
  pt[1] := Transform * (Pt1.Coord+Offset1);
  pt[2] := Transform * (Pt2.Coord+Offset2);
  pt[3] := Transform * Pt2.Coord;

  curpt := Vec(x, y);

  dir := pt[1] - curpt;
  if dot(dir, dir) <= sqr(HitDistance_Offset) then
  begin
    Result := True;
    ADistance := Len(dir);
    Exit;
  end;

  dir := pt[2] - curpt;
  if dot(dir, dir) <= sqr(HitDistance_Offset) then
  begin
    Result := True;
    ADistance := Len(dir);
    Exit;
  end;

  seg.Pt2 := Bezier3(pt[0],pt[1],pt[2],pt[3], 0);
  if FIsStraightLine then tcount := 1 else tcount := TESS_COUNT;
  for i := 1 to tcount do
  begin
    seg.Pt1 := seg.Pt2;
    seg.Pt2 := Bezier3(pt[0],pt[1],pt[2],pt[3], i / tcount);
    ADistance := Distance(curpt, seg);
    if ADistance <= HitDistance_Line then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

procedure TSpline.Drag(const Transform: TMat3; FromX, FromY: Integer; ToX, ToY: Integer);
var InvTrans: TMat3;
    FromPt, ToPt: TVec2;
    OffPt: array [0..1] of TVec2;
    I: Integer;
    OffPtIndex: Integer;
    Distance: Single;
begin
  If Pt1 = Nil Then Exit;
  If Pt2 = Nil Then Exit;
  FIsStraightLine := False;

  InvTrans := Inv(Transform);
  FromPt := Vec(FromX, FromY);
  ToPt := Vec(ToX, ToY);

  OffPt[0] := Transform * (Pt1.Coord+Offset1);
  OffPt[1] := Transform * (Pt2.Coord+Offset2);

  OffPtIndex := -1;
  Distance := 10000;
  for I := 0 to 1 do
  begin
    if (LenSqr(OffPt[I]-FromPt)<Distance) then
    begin
      Distance := Min(Distance, LenSqr(OffPt[I]-FromPt));
      OffPtIndex := I;
    end;
  end;
  if Distance > sqr(HitDistance_Offset) then
  begin
    OffPt[0] := OffPt[0] + (ToPt - FromPt);
    OffPt[1] := OffPt[1] + (ToPt - FromPt);
    OffPt[0] := InvTrans * OffPt[0];
    OffPt[1] := InvTrans * OffPt[1];
    if not Pt1.Selected then Offset1 := OffPt[0] - Pt1.Coord;
    if not Pt2.Selected then Offset2 := OffPt[1] - Pt2.Coord;
    Exit;
  end;

  OffPt[OffPtIndex] := OffPt[OffPtIndex] + (ToPt - FromPt);
  OffPt[OffPtIndex] := InvTrans * OffPt[OffPtIndex];
  case OffPtIndex of
    0: if not Pt1.Selected then Offset1 := OffPt[0] - Pt1.Coord;
    1: if not Pt2.Selected then Offset2 := OffPt[1] - Pt2.Coord;
  end;
end;

{ TPrimitivesCollection }

function TPrimitivesCollection.GenPrimID: Integer;
begin
  Inc(FMaxID);
  Result := FMaxID;
end;

function TPrimitivesCollection.GetPrim(index: Integer): TPrimitive;
begin
  Result := TPrimitive(FPrims.Items[index]);
end;

procedure TPrimitivesCollection.NotifyDestroy(Sender: TPrimitive);
begin
  FPrims.Remove(Sender);
end;

function TPrimitivesCollection.Count: Integer;
begin
  Result := FPrims.Count;
end;

procedure TPrimitivesCollection.Clear;
var I: Integer;
begin
  for I := FPrims.Count - 1 downto 0 do
    TPrimitive(FPrims.Items[I]).Free;
  Assert(FPrims.Count=0);
  FMaxID := 0;
end;

function TPrimitivesCollection.GetHitPrim(const Transform: TMat3; x, y: Integer): TPrimitive;
var I: Integer;
    dist, mindist: Single;
begin
  Result := nil;
  mindist := 100000;
  for I := 0 to Count - 1 do
  begin
    if Prim[I].HitTest(Transform, x, y, dist) then
      if dist < mindist then
        begin
          Result := Prim[I];
          mindist := dist;
        end;
  end;
end;

function TPrimitivesCollection.GetHitPrim(const Transform: TMat3; x,
  y: Integer; PrimType: TPrimitiveClass): TPrimitive;
var I: Integer;
    dist, mindist: Single;
begin
  Result := nil;
  mindist := 100000;
  for I := 0 to Count - 1 do
  begin
    if Prim[I] is PrimType then
    begin
      if Prim[I].HitTest(Transform, x, y, dist) then
        if dist < mindist then
          begin
            Result := Prim[I];
            mindist := dist;
          end;
    end;
  end;
end;

function TPrimitivesCollection.CreateVertex: TVertex;
begin
  Result := TVertex.Create(Self, GenPrimID);
  FPrims.Add(Result);
end;

function TPrimitivesCollection.CreateSpline: TSpline;
begin
  Result := TSpline.Create(Self, GenPrimID);
  FPrims.Add(Result);
end;

function TPrimitivesCollection.CreateFlood: TFlood;
begin
  Result := TFlood.Create(Self, GenPrimID);
  FPrims.Add(Result);
end;

function TPrimitivesCollection.CalcMaxSize: TVec2;
var i: Integer;
    p: TPrimitive;
    spline: TSpline absolute p;
begin
  Result := Vec(0, 0);
  for i := 0 to Count - 1 do
  begin
    p := Prim[i];
    if p is TSpline then
    begin
      if (spline.Pt1 = nil) or (spline.Pt2 = nil) then
        Continue;
      Result := Max(Result, Abs(spline.Pt1.Coord));
      Result := Max(Result, Abs(spline.Pt2.Coord));
      Result := Max(Result, Abs(spline.Pt1.Coord + spline.Offset1));
      Result := Max(Result, Abs(spline.Pt2.Coord + spline.Offset2));
    end
    else
    if p is TFlood then
      Result := Max(Result, Abs(TFlood(p).Coord));
  end;
end;

function TPrimitivesCollection.CalcMaxRad: Single;
var i: Integer;
    p: TPrimitive;
    spline: TSpline absolute p;
begin
  Result := 0;
  for i := 0 to Count - 1 do
  begin
    p := Prim[i];
    if p is TSpline then
    begin
      if (spline.Pt1 = nil) or (spline.Pt2 = nil) then
        Continue;
      Result := Max(Result, Len(spline.Pt1.Coord));
      Result := Max(Result, Len(spline.Pt2.Coord));
      Result := Max(Result, Len(spline.Pt1.Coord + spline.Offset1));
      Result := Max(Result, Len(spline.Pt2.Coord + spline.Offset2));
    end
    else
    if p is TFlood then
      Result := Max(Result, Len(TFlood(p).Coord));
  end;
end;

procedure TPrimitivesCollection.SaveToStream(const stream: TStream);
var i: Integer;
    primcount: Integer;
    id: Integer;
    v: TVec2;
begin
  //save vertices
  primcount := 0;
  for i := 0 to Count - 1 do
    if Prim[i] is TVertex then
      Inc(primcount);
  stream.WriteBuffer(primcount, SizeOf(primcount));
  for i := 0 to Count - 1 do
    if Prim[i] is TVertex then
    begin
      id := Prim[i].ID;
      v := TVertex(Prim[i]).Coord;
      stream.WriteBuffer(id, SizeOf(id));
      stream.WriteBuffer(v, SizeOf(v));
    end;

  //save splines
  primcount := 0;
  for i := 0 to Count - 1 do
    if Prim[i] is TSpline then
      Inc(primcount);
  stream.WriteBuffer(primcount, SizeOf(primcount));
  for i := 0 to Count - 1 do
    if Prim[i] is TSpline then
    begin
      id := Prim[i].ID;
      stream.WriteBuffer(id, SizeOf(id));
      if Assigned(TSpline(Prim[i]).Pt1) then id := TSpline(Prim[i]).Pt1.ID else id := -1;
      stream.WriteBuffer(id, SizeOf(id));
      if Assigned(TSpline(Prim[i]).Pt2) then id := TSpline(Prim[i]).Pt2.ID else id := -1;
      stream.WriteBuffer(id, SizeOf(id));
      v := TSpline(Prim[i]).Offset1;
      stream.WriteBuffer(v, SizeOf(v));
      v := TSpline(Prim[i]).Offset2;
      stream.WriteBuffer(v, SizeOf(v));
    end;

  //save floods
  primcount := 0;
  for i := 0 to Count - 1 do
    if Prim[i] is TFlood then
      Inc(primcount);
  stream.WriteBuffer(primcount, SizeOf(primcount));
  for i := 0 to Count - 1 do
    if Prim[i] is TFlood then
    begin
      id := Prim[i].ID;
      v := TFlood(Prim[i]).Coord;
      stream.WriteBuffer(id, SizeOf(id));
      stream.WriteBuffer(v, SizeOf(v));
    end;
end;

procedure TPrimitivesCollection.LoadFromStream(const stream: TStream);
  function FindVertexByID(const ID: Integer): TVertex;
  var I: Integer;
  begin
    Result := nil;
    if ID < 0 then Exit;
    for I := 0 to Count - 1 do
      if (Prim[I] is TVertex) and (Prim[I].ID = ID) then Exit(TVertex(Prim[I]));
  end;
var IDOffset: Integer;
    i: Integer;
    primcount: Integer;
    id: Integer;
    v: TVec2;
    vert: TVertex;
    spline: TSpline;
    flood: TFlood;
begin
  primcount := 0;
  id := 0;
  v := Vec(0,0);
  IDOffset := FMaxID;

  //read vertices
  stream.ReadBuffer(primcount, SizeOf(primcount));
  for i := 0 to primcount - 1 do
  begin
    stream.ReadBuffer(id, SizeOf(id));
    vert := TVertex.Create(Self, id + IDOffset);
    FPrims.Add(vert);
    FMaxID := Max(FMaxID, id + IDOffset);

    stream.ReadBuffer(v, SizeOf(v));
    vert.Coord := v;
  end;

  //read splines
  stream.ReadBuffer(primcount, SizeOf(primcount));
  for i := 0 to primcount - 1 do
  begin
    stream.ReadBuffer(id, SizeOf(id));
    spline := TSpline.Create(Self, id + IDOffset);
    FPrims.Add(spline);
    FMaxID := Max(FMaxID, id + IDOffset);

    stream.ReadBuffer(id, SizeOf(id));
    spline.Pt1 := FindVertexByID(id);
    stream.ReadBuffer(id, SizeOf(id));
    spline.Pt2 := FindVertexByID(id);

    stream.ReadBuffer(v, SizeOf(v));
    spline.Offset1 := v;
    stream.ReadBuffer(v, SizeOf(v));
    spline.Offset2 := v;
  end;

  //read floods
  stream.ReadBuffer(primcount, SizeOf(primcount));
  for i := 0 to primcount - 1 do
  begin
    stream.ReadBuffer(id, SizeOf(id));
    flood := TFlood.Create(Self, id + IDOffset);
    FPrims.Add(flood);
    FMaxID := Max(FMaxID, id + IDOffset);

    stream.ReadBuffer(v, SizeOf(v));
    flood.Coord := v;
  end;
end;

constructor TPrimitivesCollection.Create;
begin
  FPrims := TList.Create;
  FMaxID := 0;
end;

destructor TPrimitivesCollection.Destroy;
begin
  Clear;
  FreeAndNil(FPrims);
  inherited Destroy;
end;

{ TVertex }

procedure TVertex.Draw(const Transform: TMat3; const Canvas: TCanvas);
var v: TVec2;
    Size: Integer;
begin
  v := Transform * FCoord;

  if FSelected then
  begin
    Canvas.Brush.Color:=Canvas.Pen.Color;
    Canvas.Brush.Style:=bsSolid;
  end
  else
    Canvas.Brush.Style:=bsClear;

  if Moved or Selected then
    Canvas.Pen.Width := 2
  else
    Canvas.Pen.Width := 1;

  if FMoved then
    Size := 5
  else
    Size := 4;

  Canvas.Ellipse(Trunc(v.x)-Size, Trunc(v.y)-Size, Trunc(v.x)+Size+1, Trunc(v.y)+Size+1);
  Canvas.Pen.Width := 1;
end;

procedure TVertex.DrawFinal(const Transform: TMat3; const Canvas: TCanvas; const ClipLine1, ClipLine2: TLine2D);
begin

end;

function TVertex.HitTest(const Transform: TMat3; x,y: Integer; out distance: Single): Boolean;
var v: TVec2;
begin
  v.x := x;
  v.y := y;
  distance := Len( v - Transform*FCoord );
  Result := distance < 5;
end;

procedure TVertex.Drag(const Transform: TMat3; FromX, FromY: Integer; ToX, ToY: Integer);
var InvTrans: TMat3;
    FromPt, ToPt: TVec2;
begin
  InvTrans := Inv(Transform);
  FromPt := InvTrans * Vec(FromX, FromY);
  ToPt := InvTrans * Vec(ToX, ToY);
  FCoord := FCoord + (ToPt - FromPt);
end;

end.

