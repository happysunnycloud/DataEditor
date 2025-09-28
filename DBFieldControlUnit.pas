unit DBFieldControlUnit;

interface

uses
    System.Classes
  , FMX.Controls
  , FMX.StdCtrls
  , FMX.Memo
  , DBFieldUnit
  , ObjectRegistryUnit
  ;

type
  TDBFieldControl = class(TControl)
  strict private
    FDBField: TDBField;
    FLabel: TLabel;
    FMemo: TMemo;

    class var FDBFieldControlRegistry: TObjectRegistry<TDBFieldControl>;
  private
    property DBField: TDBField read FDBField;
  public
    constructor Create(AOwner: TControl; const AFDBField: TDBField); reintroduce;
    destructor Destroy; override;

    property Memo: TMemo read FMemo write FMemo;

    class property DBFieldControlRegistry: TObjectRegistry<TDBFieldControl>
      read FDBFieldControlRegistry write FDBFieldControlRegistry;

    class function FindControlByField(const AFDBField: TDBField): TDBFieldControl;
  end;

implementation

uses
    System.SysUtils
  , FMX.Types
  , DebugUnit
  ;

{ TDBFieldControl }

constructor TDBFieldControl.Create(AOwner: TControl; const AFDBField: TDBField);
begin
  if not (AOwner is TControl) then
    raise Exception.Create('TDBFieldControl.Create -> AOwner is not TContol');

  if not Assigned(AFDBField) then
    raise Exception.Create('TDBFieldControl.Create -> AFDBField is nil');

  inherited Create(AOwner);

  FDBField := AFDBField;

  Parent := AOwner;
  Width := 200;
  Height := 100;

  FLabel := TLabel.Create(Self);
  FLabel.Parent := Self;
  FLabel.Height := 30;
  FLabel.Width := 200;
  FLabel.Text := FDBField.FieldName + ' ' + FDBField.FieldType;
  FLabel.Align := TAlignLayout.Top;

  FMemo := TMemo.Create(Self);
  FMemo.Parent := Self;
  FMemo.Align := TAlignLayout.Client;
  FMemo.Lines.Text := '';

  TDBFieldControl.DBFieldControlRegistry.RegisterObject(Self);
end;

destructor TDBFieldControl.Destroy;
begin
  TDBFieldControl.DBFieldControlRegistry.UnRegisterObject(Self);

  inherited Destroy;
end;

class function TDBFieldControl.FindControlByField(
  const AFDBField: TDBField): TDBFieldControl;
var
  DBFieldControl: TDBFieldControl;
begin
  DBFieldControlRegistry.Enumerator(
    procedure (const AObject: TDBFieldControl)
    begin
      if AFDBField.FieldName = AObject.DBField.FieldName then
      begin
        DBFieldControl := AObject;

        Exit;
      end;
    end
  );

  Result := DBFieldControl;
end;

initialization
  TDBFieldControl.DBFieldControlRegistry :=
    TObjectRegistry<TDBFieldControl>.Create;

finalization
  FreeAndNil(TDBFieldControl.DBFieldControlRegistry);

end.
