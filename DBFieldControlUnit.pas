unit DBFieldControlUnit;

interface

uses
    System.Classes
  , FMX.Controls
  , FMX.StdCtrls
  , FMX.Memo
  , DBFieldUnit
  ;

type
  TDBFieldControl = class(TControl)
  strict private
    FDBField: TDBField;
    FLabel: TLabel;
    FMemo: TMemo;
  public
    constructor Create(AOwner: TControl; const AFDBField: TDBField); reintroduce;

    property Memo: TMemo read FMemo write FMemo;
  end;

implementation

uses
    System.SysUtils
  , FMX.Types
  ;

{ TDBFieldControl }

constructor TDBFieldControl.Create(AOwner: TControl; const AFDBField: TDBField);
begin
  inherited Create(AOwner);

  if not (AOwner is TControl) then
    raise Exception.Create('TDBFieldControl.Create -> AOwner is not TContol');

  FDBField := AFDBField;

  if not Assigned(FDBField) then
    raise Exception.Create('TDBFieldControl.Create -> AFDBField is nil');

  Parent := AOwner;
  Width := 200;
  Height := 100;

  FLabel := TLabel.Create(AOwner);
  FLabel.Parent := Self;
  FLabel.Height := 30;
  FLabel.Width := 200;
  FLabel.Text := 'Field';
  FLabel.Align := TAlignLayout.Top;

  FMemo := TMemo.Create(AOwner);
  FMemo.Parent := Self;
  FMemo.Align := TAlignLayout.Client;
  FMemo.Lines.Text := '';
end;

end.
