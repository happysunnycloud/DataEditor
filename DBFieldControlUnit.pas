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
  public
    constructor Create(
      const ARegistryRef: TDBFieldControlRegistry;
      const AOwner: TControl;
      const AFDBField: TDBField); reintroduce;
    destructor Destroy; override;

    property DBField: TDBField read FDBField;
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
  PrimaryKeyAttribute: String;
  AutoIncrementAttribute: String;
  NotNullAttribute: String;
  UniqueAttribute: String;
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
  if FDBField.IsForeignKey then
    ForeignKey := Format(' is foreign key ref: %s (%s)',
      [FDBField.TableReference, FDBField.FieldReference]);

  PrimaryKeyAttribute := '';
  if FDBField.IsPrimaryKey then
    PrimaryKeyAttribute := ' (primary key)';

  AutoIncrementAttribute := '';
  if FDBField.IsAutoIncrement then
    AutoIncrementAttribute := ' (autoincrement)';

  NotNullAttribute := '';
  if FDBField.IsNotNull then
    NotNullAttribute := ' (not null)';

  UniqueAttribute := '';
  if FDBField.IsUnique then
    UniqueAttribute := ' (unique)';

  FLabel.Text :=
    Concat(
      FDBField.FieldName,
      ' ',
      FDBField.FieldType,
      PrimaryKeyAttribute,
      AutoIncrementAttribute,
      UniqueAttribute,
      NotNullAttribute,
      ForeignKey);

  FLabel.Align := TAlignLayout.Top;

  FMemo := TMemo.Create(Self);
  FMemo.Parent := Self;
  FMemo.Align := TAlignLayout.Client;
  FMemo.Lines.Text := '';
  FMemo.Enabled := not FDBField.IsPrimaryKey and not FDBField.IsAutoIncrement;

  Width := 200;
  Height := 100;
  if FDBField.FieldType = FIELD_TYPE_INTEGER then
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
    procedure (const AObject: TDBFieldControl; var ABreak: Boolean)
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
