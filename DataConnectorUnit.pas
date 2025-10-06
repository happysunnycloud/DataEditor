unit DataConnectorUnit;

interface

uses
    System.Generics.Collections
  ;

type
  TForeignKeyObj = class(TObject)
  strict private
    FTableName: String;
    FFieldName: String;
    FTableReference: String;
    FFieldReference: String;
  public
    constructor Create(
      const ATableName: String;
      const AFieldName: String;
      const ATableReference: String;
      const AFieldReference: String);

    property TableName: String read FTableName write FTableName;
    property FieldName: String read FFieldName write FFieldName;
    property TableReference: String read FTableReference write FTableReference;
    property FieldReference: String read FFieldReference write FFieldReference;
  end;

  TForeignKeyObjList = TList<TForeignKeyObj>;

  TForeignKeyTableObj = class
  strict private
    FTableName: String;
    FForeignKeyObjList: TForeignKeyObjList;
  public
    constructor Create(const ATableName: String);
    destructor Destroy; override;

    property TableName: String
      read FTableName write FTableName;
    property ForeignKeyObjList: TForeignKeyObjList
      read FForeignKeyObjList write FForeignKeyObjList;
  end;

  TForeignKeyTableObjList = class(TList<TForeignKeyTableObj>)
  strict private
    function GetForeignKeyTableObj(const ATAbleName: String): TForeignKeyTableObj;
  public
    destructor Destroy; override;

    property ForeignKeyTableObj[const ATAbleName: String]: TForeignKeyTableObj
      read GetForeignKeyTableObj;
  end;

  TForeignKey = record
    TableName: String;
    FieldName: String;
    TableReference: String;
    FieldReference: String;
  public
    procedure Reset;
  end;

  TForeignKeyArray = TArray<TForeignKey>;

  TForeignKeyTable = record
    TableName: String;
    ForeignKeyArray: TForeignKeyArray;
  public
    procedure Reset;
  end;

  TForeignKeyTableArray = TArray<TForeignKeyTable>;

  TDataConnector = class
  strict private
  public
    class procedure GetForeignKeys(
      const ATableName: String;
      var AForeignKeyTableArray: TForeignKeyTableArray); overload;
    class procedure GetForeignKeys(
      const ATableName: String;
      const AForeignKeyTableObjList: TForeignKeyTableObjList); overload;
  end;

  TForeignKeyArrayHelper = record helper for TForeignKeyArray
  public
    procedure Add(const AVal: TForeignKey);
  end;

  TForeignKeyTableRef = ^TForeignKeyTable;

  TForeignKeyTableArrayHelper = record helper for TForeignKeyTableArray
  private
    function GetForeignKeyTable(const ATableName: String): TForeignKeyTable; overload;
  public
    procedure Add(const AVal: TForeignKeyTable);
    property ForeignKeyTable[const ATableName: String]: TForeignKeyTable
      read GetForeignKeyTable;
    function GetForeignKeyTableRef(
      const ATableName: String): TForeignKeyTableRef;
  end;

implementation

uses
    System.SysUtils
  , FMX.Forms
  , DataFormUnit
  , DBRowUnit
  , DebugUnit
  ;

{ TForeignKeyObj }

constructor TForeignKeyObj.Create(
  const ATableName: String;
  const AFieldName: String;
  const ATableReference: String;
  const AFieldReference: String);
begin
  FTableName := ATableName;
  FFieldName := AFieldName;
  FTableReference := ATableReference;
  FFieldReference := AFieldReference;
end;

{ TForeignKeyTableObj }

constructor TForeignKeyTableObj.Create(const ATableName: String);
begin
  FTableName := ATableName;
  FForeignKeyObjList := TForeignKeyObjList.Create;
end;

destructor TForeignKeyTableObj.Destroy;
var
  ForeignKeyObj: TForeignKeyObj;
begin
  while FForeignKeyObjList.Count > 0 do
  begin
    ForeignKeyObj := FForeignKeyObjList[0];
    ForeignKeyObj.Free;
    FForeignKeyObjList.Delete(0);
  end;

  FreeAndNil(FForeignKeyObjList);

  inherited;
end;

{ TForeignKeyTableObjList }

destructor TForeignKeyTableObjList.Destroy;
begin
  while Count > 0 do
  begin
    Items[0].Free;
    Delete(0);
  end;

  inherited;
end;

function TForeignKeyTableObjList.GetForeignKeyTableObj(
  const ATAbleName: String): TForeignKeyTableObj;
var
  ForeignKeyTableObj: TForeignKeyTableObj;
begin
  Result := nil;

  for ForeignKeyTableObj in Self do
  begin
    if ForeignKeyTableObj.TableName = ATAbleName then
      Exit(ForeignKeyTableObj);
  end;
end;

{ TForeignKey }

procedure TForeignKey.Reset;
begin
  TableName := '';
  FieldName := '';
  TableReference := '';
  FieldReference := '';
end;

{ TForeignKeyTable }

procedure TForeignKeyTable.Reset;
begin
  TableName := '';
  SetLength(ForeignKeyArray, 0);
end;

{ TForeignKeyArrayHelper }

procedure TForeignKeyArrayHelper.Add(const AVal: TForeignKey);
begin
  SetLength(Self, Length(Self) + 1);
  Self[Length(Self) - 1] := AVal;
end;

{ TForeignKeyTableArrayHelper }

procedure TForeignKeyTableArrayHelper.Add(const AVal: TForeignKeyTable);
begin
  SetLength(Self, Length(Self) + 1);
  Self[Length(Self) - 1] := AVal;
end;

function TForeignKeyTableArrayHelper.GetForeignKeyTable(
  const ATableName: String): TForeignKeyTable;
var
  EmptyForeignKeyTable: TForeignKeyTable;
  ForeignKeyTable: TForeignKeyTable;
begin
  for ForeignKeyTable in Self do
    if ForeignKeyTable.TableName = ATableName then
      Exit(ForeignKeyTable);

  EmptyForeignKeyTable.TableName := '';
  Result := EmptyForeignKeyTable;
end;

function TForeignKeyTableArrayHelper.GetForeignKeyTableRef(
  const ATableName: String): TForeignKeyTableRef;
var
  ForeignKeyTable: TForeignKeyTable;
  ForeignKeyTableRef: TForeignKeyTableRef;
begin
  Result := nil;

  for ForeignKeyTable in Self do
    if ForeignKeyTable.TableName = ATableName then
    begin
      ForeignKeyTableRef := @ForeignKeyTable;
      Exit(ForeignKeyTableRef);
    end;
end;

{ TDataConnector }

class procedure TDataConnector.GetForeignKeys(
  const ATableName: String;
  var AForeignKeyTableArray: TForeignKeyTableArray);
var
  DataForm: TDataForm;
  Form: TCommonCustomForm;
  DBRowList: TDBRowList;
  DBRow: TDBRow;
  DBField: TDBField;
  ForeignKey: TForeignKey;
  i, j: Integer;
  TableName: String;
  ForeignKeyTable: TForeignKeyTable;
begin
  j := 0;
  i := Screen.FormCount;
  while i > 0 do
  begin
    Dec(i);

    Form := Screen.Forms[i];
    if Form is TDataForm then
      DataForm := Form as TDataForm
    else
      Continue;

    if DataForm.Caption = ATableName then
      Continue;

    DBRowList := DataForm.DBRowList;
    if DBRowList.Count = 0 then
      Continue;

    TableName := DataForm.Caption;
    ForeignKeyTable.TableName := TableName;
    AForeignKeyTableArray.Add(ForeignKeyTable);

    TDebug.ODS('-----');
    DBRow := DBRowList.DDLRowPattern;
    for DBField in DBRow do
    begin
      TDebug.ODS(DBField.FieldName);
      if DBField.TableReference = ATableName then
      begin
        ForeignKey.TableName := DBField.TableName;
        ForeignKey.FieldName := DBField.FieldName;
        ForeignKey.TableReference := DBField.TableReference;
        ForeignKey.FieldReference := DBField.FieldReference;

        AForeignKeyTableArray[j].ForeignKeyArray.Add(ForeignKey);
      end;
    end;

    Inc(j);
    TDebug.ODS('-----');
  end;
end;

class procedure TDataConnector.GetForeignKeys(
  const ATableName: String;
  const AForeignKeyTableObjList: TForeignKeyTableObjList);
var
  DataForm: TDataForm;
  Form: TCommonCustomForm;
  DBRowList: TDBRowList;
  DBRow: TDBRow;
  DBField: TDBField;
  ForeignKeyObj: TForeignKeyObj;
  i: Integer;
  TableName: String;
  ForeignKeyTableObj: TForeignKeyTableObj;
begin
  i := Screen.FormCount;
  while i > 0 do
  begin
    Dec(i);

    Form := Screen.Forms[i];
    if Form is TDataForm then
      DataForm := Form as TDataForm
    else
      Continue;

    if DataForm.Caption = ATableName then
      Continue;

    DBRowList := DataForm.DBRowList;
    if DBRowList.Count = 0 then
      Continue;

    TableName := DataForm.Caption;

    ForeignKeyTableObj := TForeignKeyTableObj.Create(TableName);
    AForeignKeyTableObjList.Add(ForeignKeyTableObj);

    TDebug.ODS('-----');
    DBRow := DBRowList.DDLRowPattern;
    for DBField in DBRow do
    begin
      TDebug.ODS(DBField.FieldName);
      if DBField.TableReference = ATableName then
      begin
        ForeignKeyObj := TForeignKeyObj.Create(
          DBField.TableName,
          DBField.FieldName,
          DBField.TableReference,
          DBField.FieldReference
        );

//        ForeignKey.TableName := DBField.TableName;
//        ForeignKey.FieldName := DBField.FieldName;
//        ForeignKey.TableReference := DBField.TableReference;
//        ForeignKey.FieldReference := DBField.FieldReference;

        AForeignKeyTableObjList.Last.ForeignKeyObjList.Add(ForeignKeyObj);
      end;
    end;

    TDebug.ODS('-----');
  end;
end;

end.
