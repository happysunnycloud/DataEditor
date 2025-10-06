unit DBFieldControlUnit;

interface

uses
    System.Classes
  , FMX.Controls
  , FMX.StdCtrls
  , FMX.Memo
  , DBRowUnit
  , ObjectRegistryUnit
  ;

type
  TDBFieldControl = class;
  TRegistry = TObjectRegistry<TDBFieldControl>;

  TDBFieldControlRegistry = class(TRegistry)
  strict private
  public
    constructor Create;
    destructor Destroy; override;

    function FindControlByField(const AFDBField: TDBField): TDBFieldControl;
  end;

  TDBFieldControl = class(TControl)
  strict private
    FRegistryRef: TDBFieldControlRegistry;
    FDBField: TDBField;
    FLabel: TLabel;
    FMemo: TMemo;
  private
    property DBField: TDBField read FDBField;
  public
    constructor Create(
      const ARegistryRef: TDBFieldControlRegistry;
      const AOwner: TControl;
      const AFDBField: TDBField); reintroduce;
    destructor Destroy; override;

    property Memo: TMemo read FMemo write FMemo;
  end;

implementation

uses
    System.SysUtils
  , FMX.Types
  , DebugUnit
  ;

{ TDBFieldControl }

constructor TDBFieldControl.Create(
  const ARegistryRef: TDBFieldControlRegistry;
  const AOwner: TControl;
  const AFDBField: TDBField);
var
  ForeignKey: String;
begin
  if not Assigned(ARegistryRef) then
    raise Exception.Create('TDBFieldControl.Create -> ARegistryRef is nil');

  if not (AOwner is TControl) then
    raise Exception.Create('TDBFieldControl.Create -> AOwner is not TContol');

  if not Assigned(AFDBField) then
    raise Exception.Create('TDBFieldControl.Create -> AFDBField is nil');

  inherited Create(AOwner);

  FRegistryRef := ARegistryRef;

  FDBField := AFDBField;

  Parent := AOwner;

  FLabel := TLabel.Create(Self);
  FLabel.Parent := Self;
  FLabel.Height := 30;
  FLabel.Width := 200;
  ForeignKey := '';
  if FDBField.ISForeignKey then
    ForeignKey := Format(' is foreign key ref: %s (%s)',
      [FDBField.TableReference, FDBField.FieldReference]);
  FLabel.Text := FDBField.FieldName + ' ' + FDBField.FieldType + ForeignKey;
  FLabel.Align := TAlignLayout.Top;

  FMemo := TMemo.Create(Self);
  FMemo.Parent := Self;
  FMemo.Align := TAlignLayout.Client;
  FMemo.Lines.Text := '';
  FMemo.Enabled := not FDBField.IsAutoIncrement;

  Width := 200;
  Height := 100;
  if FDBField.FieldType = 'integer' then
    Height := FLabel.Height + 25;

  FRegistryRef.RegisterObject(Self);
end;

destructor TDBFieldControl.Destroy;
begin
  FRegistryRef.UnRegisterObject(Self);

  inherited Destroy;
end;

{ TDBFieldControlRegistry }

constructor TDBFieldControlRegistry.Create;
begin
  inherited;
end;

destructor TDBFieldControlRegistry.Destroy;
var
  DBFieldControl: TDBFieldControl;
begin
  while Count > 0 do
  begin
    DBFieldControl := FirstObject;
    FreeAndNil(DBFieldControl);
  end;

  inherited;
end;

function TDBFieldControlRegistry.FindControlByField(
  const AFDBField: TDBField): TDBFieldControl;
var
  DBFieldControl: TDBFieldControl;
begin
  BackwardEnumerator(
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

end.
