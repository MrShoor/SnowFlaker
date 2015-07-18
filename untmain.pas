unit untMain;

{$mode objfpc}{$H+}

interface

uses
  LCLType, Classes, SysUtils, FileUtil, PrintersDlgs, Forms, Controls, Graphics,
  Dialogs, ComCtrls, ExtCtrls, untPrimitives, mutils, cutils, types, printers,
  Menus, ExtDlgs;

type

  { TfrmMain }

  TEditTool = (etNone, etLine, etFlood);
  TDragStyle = (dsNone, dsDragSelection, dsDragWithReselect, dsRectSelection);
  TPseudoCursorSide = (pcNone, pcLeaf, pcPreview);

  TfrmMain = class(TForm)
    ImageList: TImageList;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    OpenDialog: TOpenDialog;
    Panel1: TPanel;
    pbSnowFlake: TPaintBox;
    pbLeaf: TPaintBox;
    SaveDialog: TSaveDialog;
    SaveMenu: TPopupMenu;
    PrinterSetupDialog: TPrinterSetupDialog;
    SavePictureDialog: TSavePictureDialog;
    Splitter1: TSplitter;
    ToolBar1: TToolBar;
    tbLine: TToolButton;
    tbFlood: TToolButton;
    tbPrint: TToolButton;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    tbNew: TToolButton;
    tbOpen: TToolButton;
    tbSave: TToolButton;
    ToolButton3: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure pbLeafDblClick(Sender: TObject);
    procedure pbLeafMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbLeafMouseLeave(Sender: TObject);
    procedure pbLeafMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure pbLeafMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbLeafMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure pbLeafPaint(Sender: TObject);
    procedure pbSnowFlakeMouseLeave(Sender: TObject);
    procedure pbSnowFlakeMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure pbSnowFlakePaint(Sender: TObject);
    procedure tbFloodClick(Sender: TObject);
    procedure tbLineClick(Sender: TObject);
    procedure tbNewClick(Sender: TObject);
    procedure tbOpenClick(Sender: TObject);
    procedure tbPrintClick(Sender: TObject);
    procedure tbSaveClick(Sender: TObject);
    procedure ToolButton3Click(Sender: TObject);
  private
    FActiveFilePath: string;
    FModified: Boolean;
    function GetPrevVertex: TVertex;
    procedure SetActiveFilePath(AValue: string);
    procedure SetModified(AValue: Boolean);
    procedure SetPrevVertex(AValue: TVertex);
    procedure UpdateCaption;

    procedure DoSaveAs;
    procedure DoSaveToFile(const FileName: string);
    procedure DoLoadFromFile(const FileName: string);
    procedure DoSaveToPic(const FileName: string);
  strict private
    FPrims: TPrimitivesCollection;
    FEditTool: TEditTool;
    FPrevVertex: IWeakRef;
    FLastMovePoint: TPoint;
    FLastDownPoint: TPoint;
    FWasDrag: Boolean;
    FDragStyle: TDragStyle;
    FPrimForReselect: TPrimitive;

    FLastMovePointOnPreview: TPoint;
    FPseudoCursorMode: TPseudoCursorSide;

    FScale: TVec2;
    FTranslate: TVec2;

    property Modified: Boolean read FModified write SetModified;
    property ActiveFilePath: string read FActiveFilePath write SetActiveFilePath;

    function LeafTransform: TMat3;
    function SnowFlakeTransform(quadrant: Integer; const AreaRect: TRect): TMat3;

    property PrevVertex: TVertex read GetPrevVertex write SetPrevVertex;
    procedure UpdatePrimMoveState(const Transform: TMat3; x,y: Integer);
    procedure DeselectAll;
    procedure SmartPrimitiveDelete(const prim: TPrimitive);
    procedure SmartVertexDelete(const vert: TVertex);
    procedure CleanDenegenrateSplines;
    procedure SelectSinglePrim(const prim: TPrimitive);
    procedure SelectEditTool(const Mode: TEditTool; SwitchButton: Boolean = True);
    procedure DrawToolGraphic(ACanvas: TCanvas);
    procedure DrawLeafPseudoCursors;
    procedure DrawSnowFlakePseudoCursors;
    procedure DrawCross(const ACanvas: TCanvas; const Transform: TMat3; const v: TVec2);
  private
    procedure RenderLeaf(ACanvas: TCanvas);
    procedure RenderSnowFlake(ACanvas: TCanvas; const Rct: TRect);
    procedure RenderLeafForPrint(ACanvas: TCanvas; const PaperSize: TVec2; const CornerOffset: TVec2);
  public
    { public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses Math, unthint;

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FPrims := TPrimitivesCollection.Create;
  FScale := Vec(1, 1);
  FTranslate := Vec(30, pbLeaf.ClientHeight-30);
  UpdateCaption;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FPrims);
end;

procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var I: Integer;
begin
  if (Key = VK_DELETE) and not (ssLeft in Shift) then
  begin
    for I := FPrims.Count - 1 downto 0 do
      if FPrims[I].Selected then
        SmartPrimitiveDelete(FPrims[I]);
    CleanDenegenrateSplines;
    Invalidate;
  end;
end;

procedure TfrmMain.MenuItem1Click(Sender: TObject);
begin
  DoSaveAs;
end;

procedure TfrmMain.MenuItem2Click(Sender: TObject);
begin
  if SavePictureDialog.Execute then
    DoSaveToPic(SavePictureDialog.FileName);
end;

procedure TfrmMain.pbLeafDblClick(Sender: TObject);
var prim: TPrimitive;
    spline, newspline: TSpline;
    vert: TVertex;
    T: Single;
    offset: TVec2;
begin
  spline := TSpline(FPrims.GetHitPrim(LeafTransform, FLastDownPoint.x, FLastDownPoint.y, TSpline));
  if assigned(spline) then
  begin
    if spline.GetHitT(LeafTransform, FLastDownPoint.x, FLastDownPoint.y, T) then
    begin
      offset := Lerp(spline.Offset1, -spline.Offset2, T) * T;
      spline.Offset1 := spline.Offset1 * T;
      spline.Offset2 := spline.Offset2 * (1 - T);

      vert := FPrims.CreateVertex;
      vert.Coord := Inv(LeafTransform) * Vec(FLastDownPoint.x, FLastDownPoint.y);
      newspline := FPrims.CreateSpline;
      newspline.Pt2 := spline.Pt2;
      newspline.Pt1 := vert;
      spline.Pt2 := vert;

      if spline.IsStraightLine then
        newspline.SetStraightLine
      else
      begin
        newspline.Offset2 := spline.Offset2;
        newspline.Offset1 := offset;
        spline.Offset2 := -offset;
        spline.Offset1 := spline.Offset1;
      end;

      Modified := True;
      Invalidate;
    end;
  end
  else
  begin
    prim := FPrims.GetHitPrim(LeafTransform, FLastDownPoint.x, FLastDownPoint.y);
    if prim = nil then
    begin
      vert := FPrims.CreateVertex;
      vert.Coord := Inv(LeafTransform) * Vec(FLastDownPoint.x, FLastDownPoint.y);
      SelectEditTool(etLine);
      PrevVertex := vert;

      Modified := True;
      Invalidate;
    end;
    if prim is TVertex then
    begin
      SelectEditTool(etLine);
      PrevVertex := TVertex(prim);
      Invalidate;
    end;
  end;
end;

procedure TfrmMain.pbLeafMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var v: TVertex;
    spline: TSpline;
    prim: TPrimitive;
    flood: TFlood;
begin
  FWasDrag := False;
  FLastDownPoint := Point(X, Y);
  SetCaptureControl(pbLeaf);

  if Button = mbLeft then
  begin
    case FEditTool of
      etNone:
        begin
          prim := FPrims.GetHitPrim(LeafTransform, X, Y);
          if Assigned(prim) then
          begin
            if prim.Selected then
              FDragStyle := dsDragSelection
            else
            begin
              FDragStyle := dsDragWithReselect;
              FPrimForReselect := prim;
            end;
          end
          else
            FDragStyle := dsRectSelection;
        end;
      etLine:
        begin
          prim := FPrims.GetHitPrim(LeafTransform, X, Y, TVertex);
          if Assigned(prim) then
            v := TVertex(prim)
          else
          begin
            v := FPrims.CreateVertex;
            v.Coord := Inv(LeafTransform) * Vec(X, Y);
            Modified := True;
          end;

          if v <> PrevVertex then
          begin
            if Assigned(PrevVertex) then
            begin
              spline := FPrims.CreateSpline;
              spline.Pt1 := PrevVertex;
              spline.Pt2 := v;
              spline.SetStraightLine;
              Modified := True;
            end;

            if Assigned(prim) And Assigned(PrevVertex) then
              PrevVertex := nil //close contour
            else
              PrevVertex := v; //start or continue contour

            Invalidate;
          end;
        end;
      etFlood:
        begin
          prim := FPrims.GetHitPrim(LeafTransform, X, Y, TFlood);
          if Assigned(prim) then
          begin
            flood := TFlood(prim);
            flood.Selected := True;
          end
          else
          begin
            flood := FPrims.CreateFlood;
            flood.Coord := Inv(LeafTransform) * Vec(X, Y);
            Modified := True;
          end;
        end;
    end;

  end;
end;

procedure TfrmMain.pbLeafMouseLeave(Sender: TObject);
begin
  FPseudoCursorMode := pcNone;
  Invalidate;
end;

procedure TfrmMain.pbLeafMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
const DRAGTRESHOLD = 5;
  procedure DragSelectedPrims;
  var I: Integer;
  begin
    for I := 0 to FPrims.Count - 1 do
      if FPrims[I].Selected then
      begin
        FPrims[I].Drag(LeafTransform, FLastMovePoint.X, FLastMovePoint.Y, X, Y);
      end;
    Modified := True;
    Invalidate;
  end;

var dir: TVec2;
begin
  FPseudoCursorMode := pcPreview;

  if Not FWasDrag then
  begin
    FWasDrag := ((abs(FLastDownPoint.x - X)>DRAGTRESHOLD) or (abs(FLastDownPoint.y - Y)>DRAGTRESHOLD))
                and (Shift * [ssLeft, ssRight] <> []);
    if FWasDrag then
    begin
      FLastMovePoint := FLastDownPoint;
    end;
  end;

  if FWasDrag then
  begin
    if (ssLeft in Shift) and (FEditTool = etNone) then
    begin
      case FDragStyle of
        dsRectSelection:
          begin
            if [ssCtrl, ssShift] * Shift = [] then DeselectAll;
          end;
        dsDragSelection:
          begin
            DragSelectedPrims;
          end;
        dsDragWithReselect:
          begin
            SelectSinglePrim(FPrimForReselect);
            DragSelectedPrims;
            FDragStyle := dsDragSelection;
          end;
      end;
    end
    else
    if ssRight in Shift then
    begin
      dir := Vec(X, Y) - Vec(FLastMovePoint.x, FLastMovePoint.y);
      FTranslate := FTranslate + dir;
      Invalidate;
    end;
  end;

  if Shift*[ssLeft, ssRight] = [] then
    UpdatePrimMoveState(LeafTransform, X, Y);

  FLastMovePoint := Point(X, Y);
end;

procedure TfrmMain.pbLeafMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var prim: TPrimitive;
    rct: TRect;
    v: TVec2;
    Trans: TMat3;
    i: Integer;
begin
  SetCaptureControl(Nil);
  if FWasDrag then
  begin
    if (Button = mbLeft) and (FDragStyle = dsRectSelection) then
    begin
      rct.Left := Min(FLastMovePoint.x, FLastDownPoint.x);
      rct.Top := Min(FLastMovePoint.y, FLastDownPoint.y);
      rct.Right := Max(FLastMovePoint.x, FLastDownPoint.x);
      rct.Bottom := Max(FLastMovePoint.y, FLastDownPoint.y);
      Trans := LeafTransform;
      for i := 0 to FPrims.Count - 1 do
      begin
        prim := FPrims.Prim[i];
        if prim is TVertex then
          v := TVertex(prim).Coord
        else
        if prim is TFlood then
          v := TFlood(prim).Coord
        else
          Continue;

        v := Trans * v;
        if PtInRect(rct, Point(trunc(v.x), trunc(v.y))) then
        begin
          if ssCtrl in Shift then
            prim.Selected := not prim.Selected
          else
            prim.Selected := True;
        end;
      end;
    end;
    FDragStyle := dsNone;
    FWasDrag := False;
    Invalidate;
  end
  else
  begin
    FDragStyle := dsNone;
    if Button = mbRight then
    begin
      if FEditTool = etNone then
      begin
        prim := FPrims.GetHitPrim(LeafTransform, X, Y);
        if Assigned(prim) and prim.Moved then
        begin
          SmartPrimitiveDelete(prim);
          CleanDenegenrateSplines;
        end;
      end
      else
      begin
        SelectEditTool(etNone);
        Invalidate;
      end;
      Exit;
    end;

    if Button = mbLeft then
    begin
      case FEditTool of
        etNone:
          begin
            if Not (ssCtrl in Shift) then DeselectAll;
            prim := FPrims.GetHitPrim(LeafTransform, X, Y);
            if Assigned(prim) then
            begin
              prim.Selected := Not Prim.Selected;
              Invalidate;
            end;
          end;
        etLine:
          begin
            if PrevVertex = nil then
              SelectEditTool(etNone);
          end;
        etFlood:
          begin
            SelectEditTool(etNone);
          end;
      end;
    end;
  end;
end;

procedure TfrmMain.pbLeafMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var OldCur: TVec2;
begin
  OldCur := Inv(LeafTransform) * Vec(MousePos.x, MousePos.y);
  FScale := FScale * (Vec(1,1) + Vec(WheelDelta, WheelDelta) * 0.0005);
  OldCur := LeafTransform * OldCur;
  FTranslate := FTranslate + Vec(MousePos.x - OldCur.x, MousePos.y - OldCur.y);
  Invalidate;
  Handled := True;
end;

procedure TfrmMain.pbLeafPaint(Sender: TObject);
begin
  pbLeaf.Canvas.Pen.Color:=clBlack;
  RenderLeaf(pbLeaf.Canvas);
  pbLeaf.Canvas.Pen.Color:=clRed;
  DrawToolGraphic(pbLeaf.Canvas);
  pbLeaf.Canvas.Pen.Color:=clGreen;
  DrawLeafPseudoCursors;
end;

procedure TfrmMain.pbSnowFlakeMouseLeave(Sender: TObject);
begin
  FPseudoCursorMode := pcNone;
  Invalidate;
end;

procedure TfrmMain.pbSnowFlakeMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  FPseudoCursorMode := pcLeaf;
  FLastMovePointOnPreview := Point(X, Y);
  Invalidate;
end;

procedure TfrmMain.pbSnowFlakePaint(Sender: TObject);
begin
  RenderSnowFlake(pbSnowFlake.Canvas, pbSnowFlake.ClientRect);
  pbSnowFlake.Canvas.Pen.Color:=clLime;
  DrawSnowFlakePseudoCursors;
end;

procedure TfrmMain.tbFloodClick(Sender: TObject);
begin
  if tbFlood.Down then
    SelectEditTool(etFlood, False)
  else
    SelectEditTool(etNone, False);
end;

procedure TfrmMain.tbLineClick(Sender: TObject);
begin
  if tbLine.Down then
    SelectEditTool(etLine, False)
  else
    SelectEditTool(etNone, False);
end;

procedure TfrmMain.tbNewClick(Sender: TObject);
begin
  FPrims.Clear;
  FPrimForReselect := Nil;
  Modified := False;
  ActiveFilePath := '';
  Invalidate;
end;

procedure TfrmMain.tbOpenClick(Sender: TObject);
begin
  if OpenDialog.Execute then
    DoLoadFromFile(OpenDialog.FileName);
end;

procedure TfrmMain.tbPrintClick(Sender: TObject);
var rct, physRct: TRect;
    w, h, offset: Integer;
begin
  if Printer.Printers.Count = 0 then
  begin
    ShowMessage('Error: Printers not found');
    Exit;
  end;

  if PrinterSetupDialog.Execute then
  begin
    Printer.BeginDoc;
    try
      rct := Printer.PaperSize.PaperRect.WorkRect;
      physRct := Printer.PaperSize.PaperRect.PhysicalRect;
      w := rct.Right - rct.Left;
      h := rct.Bottom - rct.Top;
      if w > h then
        offset := Max(rct.Left - physRct.Left, Max(rct.Top - physRct.Top, physRct.Bottom - rct.Bottom))
      else
        offset := Max(rct.Left - physRct.Left, Max(rct.Top - physRct.Top, physRct.Right - rct.Right));

      w := physRct.Right - physRct.Left;
      h := physRct.Bottom - physRct.Top;
      w := w - offset * 2;
      h := h - offset * 2;
      RenderLeafForPrint(Printer.Canvas, Vec(w, h), Vec(offset - rct.Left, offset - rct.Top));
    finally
      Printer.EndDoc;
    end;
  end;
end;

procedure TfrmMain.tbSaveClick(Sender: TObject);
begin
  if ActiveFilePath <> '' then
    DoSaveToFile(ActiveFilePath)
  else
    DoSaveAs;
end;

procedure TfrmMain.ToolButton3Click(Sender: TObject);
begin
  if assigned(frmhint) then
    frmhint.Show;
end;

function TfrmMain.GetPrevVertex: TVertex;
begin
  if FPrevVertex = Nil then Exit(Nil);
  Result := TVertex(FPrevVertex.Obj);
end;

procedure TfrmMain.SetActiveFilePath(AValue: string);
begin
  if FActiveFilePath=AValue then Exit;
  FActiveFilePath:=AValue;
  UpdateCaption;;
end;

procedure TfrmMain.SetModified(AValue: Boolean);
begin
  if FModified=AValue then Exit;
  FModified:=AValue;
  UpdateCaption;
end;

procedure TfrmMain.SetPrevVertex(AValue: TVertex);
begin
  if AValue = nil then
    FPrevVertex := nil
  else
    FPrevVertex := AValue.WeakRef;
end;

procedure TfrmMain.UpdateCaption;
var ModifyStr, FileStr: string;
begin
  if Modified then
    ModifyStr:='*'
  else
    ModifyStr:='';

  if ActiveFilePath='' then
    FileStr := 'New snowflake'
  else
    FileStr := ActiveFilePath;

  Caption := Format('SnowFlaker - %s%s', [ModifyStr, FileStr]);
end;

procedure TfrmMain.DoSaveAs;
begin
  if SaveDialog.Execute then
    DoSaveToFile(SaveDialog.FileName);
end;

procedure TfrmMain.DoSaveToFile(const FileName: string);
var fs: TFileStream;
begin
  try
    fs := TFileStream.Create(UTF8ToSys(FileName), fmCreate);
    try
      FPrims.SaveToStream(fs);
      ActiveFilePath := FileName;
      Modified := False;
    finally
      fs.Free;
    end;
  except
    on e: EFCreateError do ShowMessageFmt('Unable to create file: "%s"', [FileName]);
  end;
end;

procedure TfrmMain.DoLoadFromFile(const FileName: string);
var fs: TFileStream;
begin
  try
    fs := TFileStream.Create(UTF8ToSys(FileName), fmOpenRead);
    try
      FPrims.Clear;
      FPrims.LoadFromStream(fs);
      ActiveFilePath := FileName;
      Modified := False;
    finally
      fs.Free;
    end;
  except
    on e: EFCreateError do ShowMessageFmt('Unable to create file: "%s"', [FileName]);
  end;
end;

procedure TfrmMain.DoSaveToPic(const FileName: string);
var png: TPortableNetworkGraphic;
    offset: Integer;
begin
  png := TPortableNetworkGraphic.Create;
  try
    png.PixelFormat := pf24bit;
    png.Width := 2048;
    png.Height := 2048;
    offset := 0;
    png.Canvas.Brush.Color:=clWhite;
    png.Canvas.Brush.Style:=bsSolid;
    png.Canvas.FillRect(Rect(0, 0, png.Width, png.Height));
    RenderLeafForPrint(png.Canvas, Vec(png.Width-offset*2, png.Height-offset*2), Vec(offset, offset));
    try
      png.SaveToFile(FileName);
    except
      on e: EFCreateError do ShowMessageFmt('Unable to create file: "%s"', [FileName]);
    end;
  finally
    png.Free;
  end;
end;

function TfrmMain.LeafTransform: TMat3;
begin
  Result := Mat(Vec(FScale.x, 0), Vec(0, -FScale.y), FTranslate);
end;

function TfrmMain.SnowFlakeTransform(quadrant: Integer; const AreaRect: TRect): TMat3;
var AreaRad, AreaScale: Single;
    NewX, NewY, NewPos: TVec2;
    sn, cs: Float;
begin
  Result := ZeroMat3;

  quadrant := quadrant mod 12;
  AreaRad := FPrims.CalcMaxRad;
  if AreaRad = 0 then Exit;
  AreaScale := Min( (AreaRect.Right-AreaRect.Left), (AreaRect.Bottom-AreaRect.Top) ) / AreaRad * 0.5;
  if AreaScale = 0 then Exit;
  NewPos.x := (AreaRect.Right + AreaRect.Left) * 0.5;
  NewPos.y := (AreaRect.Top + AreaRect.Bottom) * 0.5;

  SinCos((quadrant div 2) * Pi/3 + Pi/6, sn, cs);
  NewX := Vec(sn, cs)*AreaScale;
  NewY := Vec(-NewX.y, NewX.x);
  if quadrant mod 2 = 0 then NewX := -NewX;
  Result := Mat(NewX, NewY, NewPos);
end;

procedure TfrmMain.UpdatePrimMoveState(const Transform: TMat3; x,y: Integer);
var I: Integer;
    prim: TPrimitive;
begin
  for I := 0 to FPrims.Count - 1 do
    FPrims[i].Moved := False;

  prim := nil;
  case FEditTool of
    etNone: prim := FPrims.GetHitPrim(Transform, x, y);
    etLine: prim := FPrims.GetHitPrim(Transform, x, y, TVertex);
  end;

  if assigned(prim) then
    prim.Moved := True;
  Invalidate;
end;

procedure TfrmMain.DeselectAll;
var I: Integer;
begin
  For I := 0 To FPrims.Count - 1 do
    FPrims[I].Selected := False;
  Invalidate;
end;

procedure TfrmMain.SmartPrimitiveDelete(const prim: TPrimitive);
begin
  if prim = nil then Exit;
  if prim is TVertex then
    SmartVertexDelete(TVertex(prim))
  else
    prim.Free;

  Modified := True;
  Invalidate;
end;

procedure TfrmMain.SmartVertexDelete(const vert: TVertex);
var prim: TPrimitive;
    splines: array [0..1] of TSpline;
    vertices: array [0..1] of TVertex;
    splineIndex: Integer;
    i: Integer;
begin
  splineIndex := 0;
  for i := 0 to FPrims.Count - 1 do
  begin
    prim := FPrims[i];
    if prim is TSpline then
    begin
      if TSpline(prim).Pt1 = nil then Continue;
      if TSpline(prim).Pt2 = nil then Continue;
      if TSpline(prim).Pt1 = TSpline(prim).Pt2 then Continue;
      if (TSpline(prim).Pt1 = vert) or (TSpline(prim).Pt2 = vert) then
      begin
        if splineIndex = 2 then
        begin
          Inc(splineIndex);
          break;
        end;
        splines[splineIndex] := TSpline(prim);
        Inc(splineIndex);
      end;
    end;
  end;
  if splineIndex = 2 then
  begin
    for i := 0 to 1 do
    begin
      if splines[i].Pt1 = vert then
        vertices[i] := splines[i].Pt2
      else
        vertices[i] := splines[i].Pt1;
    end;
    splines[0].Pt1 := vertices[0];
    splines[0].Pt2 := vertices[1];
    splines[0].SetStraightLine;
    vert.Free;
  end
  else
    vert.Free;
end;

procedure TfrmMain.CleanDenegenrateSplines;
var I: Integer;
    spline: TSpline;
begin
  for I := FPrims.Count - 1 downto 0 do
    if FPrims[I] is TSpline then
    begin
      spline := TSpline(FPrims[I]);
      if ((spline.Pt1 = nil) or (spline.Pt2 = nil)) or (spline.Pt1 = spline.Pt2) then
        spline.Free;
    end;
end;

procedure TfrmMain.SelectSinglePrim(const prim: TPrimitive);
begin
  DeselectAll;
  if assigned(prim) then
  begin
    prim.Selected := True;
    Invalidate;
  end;
end;

procedure TfrmMain.SelectEditTool(const Mode: TEditTool; SwitchButton: Boolean);
begin
  if SwitchButton then
  begin
    case Mode of
      etNone:
        begin
          tbLine.Down := False;
          tbFlood.Down := False;
        end;
      etLine:
        begin
          tbLine.Down := True;
          tbFlood.Down := False;
        end;
      etFlood:
        begin
          tbLine.Down := False;
          tbFlood.Down := True;
        end;
    end;
  end;

  case Mode of
    etNone : pbLeaf.Cursor := crDefault;
    etLine : pbLeaf.Cursor := crCross;
    etFlood: pbLeaf.Cursor := crCross;
  end;
  FEditTool := Mode;
  PrevVertex := Nil;
end;

procedure TfrmMain.DrawToolGraphic(ACanvas: TCanvas);
var v: TVec2;
    movedVert: TVertex;
    lx, ly, hx, hy: Integer;
    OldPenColor: TColor;
begin
  case FEditTool of
    etNone:
      begin
        OldPenColor := ACanvas.Pen.Color;
        if (FDragStyle = dsRectSelection) then
        begin
          lx := Min(FLastDownPoint.x, FLastMovePoint.x);
          ly := Min(FLastDownPoint.y, FLastMovePoint.y);
          hx := Max(FLastDownPoint.x, FLastMovePoint.x);
          hy := Max(FLastDownPoint.y, FLastMovePoint.y);
          ACanvas.Brush.Style:=bsClear;
          ACanvas.Pen.Color := clGray;
          ACanvas.Rectangle(Rect(lx, ly, hx, hy));
          ACanvas.Pen.Color := OldPenColor;
        end;
      end;
    etLine:
      begin
        movedVert := TVertex(FPrims.GetHitPrim(LeafTransform, FLastMovePoint.x, FLastMovePoint.y, TVertex));
        if Assigned(movedVert) then
        begin
          ACanvas.Brush.Style:=bsSolid;
          ACanvas.Brush.Color:=ACanvas.Pen.Color;
          v := LeafTransform * movedVert.Coord;
          ACanvas.Ellipse(Trunc(v.x) - 5, Trunc(v.y) - 5, Trunc(v.x) + 5, Trunc(v.y) + 5);
          ACanvas.Brush.Style:=bsClear;
        end
        else
        begin
          if PrevVertex = nil then
            ACanvas.Ellipse(FLastMovePoint.x - 5, FLastMovePoint.y - 5, FLastMovePoint.x + 5, FLastMovePoint.y + 5);
        end;

        if Assigned(PrevVertex) then
        begin
          v := LeafTransform * PrevVertex.Coord;
          ACanvas.MoveTo(Trunc(v.x), Trunc(v.y));
          ACanvas.LineTo(FLastMovePoint);
        end
      end;
    etFlood:
      begin
        ACanvas.Rectangle(FLastMovePoint.x - 5, FLastMovePoint.y - 5, FLastMovePoint.x + 5, FLastMovePoint.y + 5);
      end;
  end;
end;

procedure TfrmMain.DrawLeafPseudoCursors;
var rct: TRect;
    v: TVec2;
    fi: Single;
    quadrant: Single;
begin
  if FPseudoCursorMode <> pcLeaf then Exit;

  rct := pbSnowFlake.ClientRect;
  v := Vec(FLastMovePointOnPreview.x - (rct.Left+rct.Right)*0.5, (rct.Top+rct.Bottom)*0.5 - FLastMovePointOnPreview.y);
  fi := arctan2(v.y, v.x) + Pi;
  quadrant := fi / (pi/6);
  v := Inv(SnowFlakeTransform(Trunc(quadrant), rct)) * Vec(FLastMovePointOnPreview.x, FLastMovePointOnPreview.y);
  DrawCross(pbLeaf.Canvas, LeafTransform, v);
end;

procedure TfrmMain.DrawSnowFlakePseudoCursors;
var I: Integer;
    v: TVec2;
    cline1, cline2: TLine2D;
begin
  if FPseudoCursorMode <> pcPreview then Exit;

  cline1.Norm := Vec(1, 0);
  cline1.Offset := 0;
  cline2.Norm := Vec(-sin(Pi/3), cos(Pi/3));
  cline2.Offset := 0;
  v := Inv(LeafTransform) * Vec(FLastMovePoint.x, FLastMovePoint.y);
  if (Dot(cline1.Norm, v) < 0) or (Dot(cline2.Norm, v) < 0) then Exit;

  for I := 0 to 11 do
    DrawCross(pbSnowFlake.Canvas, SnowFlakeTransform(I, pbSnowFlake.ClientRect), v);
end;

procedure TfrmMain.DrawCross(const ACanvas: TCanvas; const Transform: TMat3;
  const v: TVec2);
var v2: TVec2;
begin
  v2 := Transform * v;
  if IsInfinite(v2.x) or IsInfinite(v2.y) then Exit;
  if IsNan(v2.x) or IsNan(v2.y) then Exit;
  ACanvas.MoveTo(Trunc(v2.x), Trunc(v2.y) - 5);
  ACanvas.LineTo(Trunc(v2.x), Trunc(v2.y) + 6);
  ACanvas.MoveTo(Trunc(v2.x) - 5, Trunc(v2.y));
  ACanvas.LineTo(Trunc(v2.x) + 6, Trunc(v2.y));
end;

procedure TfrmMain.RenderLeaf(ACanvas: TCanvas);
  procedure RenderBounds;
  var v: TVec2;
  begin
    v := LeafTransform * Vec(0, 10000);
    ACanvas.MoveTo(Trunc(v.x), Trunc(v.y));

    v := LeafTransform * Vec(0, 0);
    ACanvas.LineTo(Trunc(v.x), Trunc(v.y));

    v := LeafTransform * (Vec(Cos(Pi/3), Sin(Pi/3))*10000);
    ACanvas.LineTo(Trunc(v.x), Trunc(v.y));
  end;
var I: Integer;
begin
  RenderBounds;

  for I := 0 to FPrims.Count - 1 do
    FPrims[I].Draw(LeafTransform, ACanvas);

  ACanvas.Brush.Style:=bsSolid;
  ACanvas.Brush.Color:=clWhite;
end;

procedure TfrmMain.RenderSnowFlake(ACanvas: TCanvas; const Rct: TRect);
  procedure RenderPrimitives(const Transform: TMat3; PrimType: TPrimitiveClass; const ClipLine1, ClipLine2: TLine2D);
  var I: Integer;
  begin
    for I := 0 to FPrims.Count - 1 do
    begin
      if FPrims[I] is PrimType then
        FPrims[I].DrawFinal(Transform, ACanvas, ClipLine1, ClipLine2);
    end;
  end;

var I: Integer;
    cline1, cline2: TLine2D;
begin
  ACanvas.Brush.Color := clBlack;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.FillRect(pbSnowFlake.ClientRect);
  ACanvas.Pen.Color := clWhite;

  cline1.Norm := Vec(1, 0);
  cline1.Offset := 0;
  cline2.Norm := Vec(-sin(Pi/3), cos(Pi/3));
  cline2.Offset := 0;

  for I := 0 to 11 do
    RenderPrimitives( SnowFlakeTransform(I, pbSnowFlake.ClientRect), TSpline, cline1, cline2 );

  for I := 0 to 11 do
    RenderPrimitives( SnowFlakeTransform(I, pbSnowFlake.ClientRect), TFlood, cline1, cline2 );
end;

procedure TfrmMain.RenderLeafForPrint(ACanvas: TCanvas; const PaperSize: TVec2; const CornerOffset: TVec2);
var PaperTransform: TMat3;
  procedure RenderPrimitives(const Transform: TMat3; PrimType: TPrimitiveClass; const ClipLine1, ClipLine2: TLine2D);
  var I: Integer;
  begin
    for I := 0 to FPrims.Count - 1 do
    begin
      if FPrims[I] is PrimType then
        FPrims[I].DrawFinal(Transform, ACanvas, ClipLine1, ClipLine2);
    end;
  end;

  procedure DrawActionArrow (const pt1, dir: TVec2; ActionIndex: Integer);
    function RotateMat(fi: Single): TMat3;
    var sn, cs: Float;
    begin
      sincos(fi, sn, cs);
      Result := Mat(Vec(cs, -sn), Vec(sn, cs));
    end;
  var i: Integer;
      v1, v2, vdir: TVec2;
      leftDir, rightDir, arrowStart: TVec2;
  begin
    v1 := PaperTransform * pt1;
    v2 := PaperTransform * (pt1 + dir);
    vdir := (v1 - v2)*0.25;
    leftDir  := RotateMat(Pi*0.1)  * vdir;
    rightDir := RotateMat(-Pi*0.1) * vdir;

    ACanvas.MoveTo( Trunc(v1.x), Trunc(v1.y) );
    ACanvas.LineTo( Trunc(v2.x), Trunc(v2.y) );
    for i:= 0 to ActionIndex - 1 do
    begin
      arrowStart := Lerp(v1, v2, 1 - 0.2*i);
      ACanvas.MoveTo( Trunc(arrowStart.x), Trunc(arrowStart.y) );
      ACanvas.LineTo( Trunc(arrowStart.x+leftDir.x), Trunc(arrowStart.y+leftDir.y) );

      ACanvas.MoveTo( Trunc(arrowStart.x), Trunc(arrowStart.y) );
      ACanvas.LineTo( Trunc(arrowStart.x+rightDir.x), Trunc(arrowStart.y+rightDir.y) );
    end;
  end;

  procedure DrawSnowCircle(MinPaperSize: Single);
  var VCenter: TVec2;
  begin
    VCenter := PaperTransform * (Vec(MinPaperSize, MinPaperSize)*0.5);
    ACanvas.Ellipse(Trunc(VCenter.x - MinPaperSize*0.5), Trunc(VCenter.y - MinPaperSize*0.5),
                    Trunc(VCenter.x + MinPaperSize*0.5), Trunc(VCenter.y + MinPaperSize*0.5));
  end;

  procedure DrawMergeLine(MinPaperSize: Single);
  const Pi6 = Pi + Pi / 12;
  var VStart, VCenter: TVec2;
  begin
    VStart := Vec( 0, MinPaperSize*0.5 - MinPaperSize*0.5*sin(Pi6)/cos(Pi6) );
    VCenter := Vec(MinPaperSize, MinPaperSize)*0.5;
    VStart := PaperTransform * VStart;
    VCenter := PaperTransform * VCenter;
    ACanvas.MoveTo(Trunc(VStart.x), Trunc(VStart.y));
    ACanvas.LineTo(Trunc(VCenter.x), Trunc(VCenter.y));
  end;

var
    AreaRad: Single;
    AreaScale: Single;
    MinPaperSize: Single;
    CenterPos: TVec2;
    cline1, cline2: TLine2D;
    PrintLeafTransform: TMat3;
begin
  MinPaperSize := Min( (PaperSize.x), (PaperSize.y) );
  if PaperSize.x > PaperSize.y then
  begin
    PaperTransform := Mat( Vec(1,0), Vec(0,1),  CornerOffset ) *
                      Mat( Vec(1,0), Vec(0,1),  Vec(MinPaperSize, MinPaperSize)*0.5) *
                      Mat( Vec(0,-1), Vec(1,0), Vec(0,0) ) *
                      Mat( Vec(1,0), Vec(0,1), -Vec(MinPaperSize, MinPaperSize)*0.5);
  end
  else
    PaperTransform := Mat( Vec(1,0), Vec(0,1),  CornerOffset );

  ACanvas.Rectangle(Trunc(CornerOffset.x), Trunc(CornerOffset.y),
                    Trunc(CornerOffset.x+Min(PaperSize.x, PaperSize.y)), Trunc(CornerOffset.y+Min(PaperSize.x, PaperSize.y)));

  AreaRad := FPrims.CalcMaxRad*1.05;
  if AreaRad = 0 then Exit;
  AreaScale := MinPaperSize / AreaRad * 0.5;
  CenterPos.x := MinPaperSize*0.5;
  CenterPos.y := CenterPos.x;
  if AreaScale = 0 then Exit;

  DrawActionArrow(Vec(MinPaperSize, 0), Vec(-MinPaperSize*0.06*3, MinPaperSize*0.06), 1);
  DrawActionArrow(Vec(0, MinPaperSize), Vec( MinPaperSize*0.06, -MinPaperSize*0.06*3), 2);
  DrawActionArrow(Vec(0, MinPaperSize), Vec( MinPaperSize*0.06*3, -MinPaperSize*0.06), 3);
  DrawSnowCircle(MinPaperSize);

  ACanvas.Pen.Color:=clDkGray;
  DrawMergeLine(MinPaperSize);
  ACanvas.Pen.Color:=clBlack;

  cline1.Norm := Vec(1, 0);
  cline1.Offset := 0;
  cline2.Norm := Vec(-sin(Pi/3), cos(Pi/3));
  cline2.Offset := 0;

  PrintLeafTransform := Mat(Vec(-AreaScale, 0), Vec(0, AreaScale), CenterPos) * Mat(Pi*0.25-Pi);
  RenderPrimitives( PaperTransform * PrintLeafTransform, TSpline, cline1, cline2);
end;

end.
