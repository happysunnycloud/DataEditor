unit DataConnectorUnit;

interface

uses
    System.Generics.Collections
  , DBRowUnit
  ;

type
  TForeignKey = class(TDBField)
  end;

//  TForeignKeyObj = class(TObject)
//  strict private
//    FTableName: String;
//    FFieldName: String;
//    FTableReference: String;
//    FFieldReference: String;
//    FHasUpdateCascade: Boolean;
//    FHasDeleteCascade: Boolean;
//  public
//    constructor Create(
//      const ATableName: String;
//      const AFieldName: String;
//      const ATableReference: String;
//      const AFieldReference: String;
//      const AHasUpdateCascade: Boolean;
//      const AHasDeleteCascade: Boolean);
//
//    property TableName: String read FTableName write FTableName;
//    property FieldName: String read FFieldName write FFieldName;
//    property TableReference: String read FTableReference write FTableReference;
//    property FieldReference: String read FFieldReference write FFieldReference;
//    property HasUpdateCascade: Boolean read FHasUpdateCascade write FHasUpdateCascade;
//    property HasDeleteCascade: Boolean read FHasDeleteCascade write FHasDeleteCascade;
//  end;

  TForeignKeyObjList = TList<TForeignKey>;

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

  TDataConnector = class
  strict private
  public
    class procedure GetForeignKeys(
      const ATableName: String;
      const AForeignKeyTableObjList: TForeignKeyTableObjList); //overload;
  end;

implementation

uses
    System.SysUtils
  , FMX.Forms
  , DataFormUnit
  , DebugUnit
  ;

{ TForeignKeyTableObj }

constructor TForeignKeyTableObj.Create(const ATableName: String);
begin
  FTableName := ATableName;
  FForeignKeyObjList := TForeignKeyObjList.Create;
end;

destructor TForeignKeyTableObj.Destroy;
var
  ForeignKey: TForeignKey;
begin
  while FForeignKeyObjList.Count > 0 do
  begin
    ForeignKey := FForeignKeyObjList[0];
    ForeignKey.Free;
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

{ TDataConnector }

class procedure TDataConnector.GetForeignKeys(
  const ATableName: String;
  const AForeignKeyTableObjList: TForeignKeyTableObjList);
var
  DataForm: TDataForm;
  Form: TCommonCustomForm;
  DBRowList: TDBRowList;
  DBRow: TDBRow;
  DBField: TDBField;
  ForeignKey: TForeignKey;
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
    if DBRowList.DDLRowPattern.Count = 0 then
      Continue;

    TableName := DataForm.Caption;

    ForeignKeyTableObj := TForeignKeyTableObj.Create(TableName);

    DBRow := DBRowList.DDLRowPattern;
    for DBField in DBRow do
    begin
      TDebug.ODS(DBField.FieldName);
      if DBField.TableReference = ATableName then
      begin
        ForeignKey := TForeignKey.Create;
        ForeignKey.CopyFrom(DBField);
        ForeignKeyTableObj.ForeignKeyObjList.Add(ForeignKey);
      end;
    end;

    if ForeignKeyTableObj.ForeignKeyObjList.Count > 0 then
      AForeignKeyTableObjList.Add(ForeignKeyTableObj)
    else
      FreeAndNil(ForeignKeyTableObj);
  end;
end;

end.
