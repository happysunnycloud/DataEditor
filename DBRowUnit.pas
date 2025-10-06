unit DBRowUnit;

interface

uses
    System.Generics.Collections
  , System.Classes
  ;

const
  ExcludingDDLString: array[0..4] of string = ('create', 'foreign key', 'references', '(', ')');
  ExcludingChars: array[0..2] of Char = (',', '(', ')');

type
  TDBField = class
  strict private
    FTableName: String;
    FFieldName: String;
    FFieldType: String;
    FFieldValue: String;
    FIsAutoIncrement: Boolean;
    FIsForeignKey: Boolean;
    FTableReference: String;
    FFieldReference: String;
  public
    constructor Create;

    property TableName: String read FTableName write FTableName;
    property FieldName: String read FFieldName write FFieldName;
    property FieldType: String read FFieldType write FFieldType;
    property FieldValue: String read FFieldValue write FFieldValue;
    property IsAutoIncrement: Boolean read FIsAutoIncrement write FIsAutoIncrement;
    property IsForeignKey: Boolean read FIsForeignKey write FIsForeignKey;
    property TableReference: String read FTableReference write FTableReference;
    property FieldReference: String read FFieldReference write FFieldReference;

    class function ClearString(const ADirtString: String): String;
    class function CreateDBField(
      const ATableName: String;
      const AFieldString: String): TDBField;
  end;

  // Переименовать в TDBRow
  // TDBFieldList -> TDBRow
  TDBRow = class(TList<TDBField>)
  strict private
    function ContainsExcludingDDLString(
      const ADDLString: String): Boolean;
    procedure ParseDDLString(const ADDLString: String);

    function GetField(const AName: String): TDBField;
  public
    constructor Create(const ADDLString: String = '');
    destructor Destroy; override;

    property Field[const AName: String]: TDBField read GetField;
  end;

  TDBRowList = class(TList<TDBRow>)
  strict private
    // Содержит весь состав полей с типами из DDL таблицы
    FDDLRowPattern: TDBRow;

    function GetRow(const AIndex: Integer): TDBRow;
  protected

  public
    constructor Create(const ADDLTable: String = '');
    destructor Destroy; override;

    property Row[const AIndex: Integer]: TDBRow read GetRow;
    property DDLRowPattern: TDBRow read FDDLRowPattern;

    procedure Add(const ADBRow: TDBRow);
    procedure SetDDLRowPattern(const ADDLString: String);

      procedure Clear;
  end;

implementation

uses
    System.SysUtils
  ;

{ TDBField }

constructor TDBField.Create;
begin
  FTableName := '';
  FFieldName := '';
  FFieldType := '';
  FFieldValue := '';
  FIsAutoIncrement := false;
  FIsForeignKey := false;
  FTableReference := '';
  FFieldReference := '';
end;

class function TDBField.ClearString(const ADirtString: String): String;
var
  ExcludingChar: Char;
begin
  Result := ADirtString;

  for ExcludingChar in ExcludingChars do
  begin
    Result := StringReplace(Result, ExcludingChar, '', [rfReplaceAll, rfIgnoreCase]);
  end;
end;

class function TDBField.CreateDBField(
  const ATableName: String;
  const AFieldString: String): TDBField;
var
  Splitted: TArray<String>;
  SplittedStrings: TStringList;
  ParsingString: String;
  TrimedString: String;

  FieldName: String;
  FieldType: String;
begin
  Splitted := AFieldString.Split([' ']);

  if Length(Splitted) < 2 then
    raise Exception.
      CreateFmt('TDBField.CreateDBField -> Incorrect input string: "%s"',
        [AFieldString]);

  SplittedStrings := TStringList.Create;
  try
    for ParsingString in Splitted do
    begin
      TrimedString := Trim(ParsingString);
      if TrimedString.Length > 0 then
      begin
        SplittedStrings.Add(TrimedString);
      end;
    end;

    FieldName := ClearString(SplittedStrings[0]);
    FieldType := ClearString(SplittedStrings[1]);

    Result := TDBField.Create;
    Result.TableName := ATableName;
    Result.FieldName := FieldName;
    Result.FieldType := FieldType;
    Result.IsAutoIncrement := AFieldString.Contains('autoincrement')
  finally
    FreeAndNil(SplittedStrings);
  end;
end;

{ TDBRow }

function TDBRow.ContainsExcludingDDLString(const ADDLString: String): Boolean;
var
  ExcludingString: String;
  DDLString: String;
begin
  Result := false;

  DDLString := String.LowerCase(ADDLString);
  for ExcludingString in ExcludingDDLString do
  begin
    if DDLString.Contains(ExcludingString) then
    begin
      Result := true;

      Break;
    end;
  end;
end;

procedure TDBRow.ParseDDLString(const ADDLString: String);

  procedure _ParseReference(
    const AReferenceString: String;
    var ATableReference: String;
    var AFieldReference: String);
  var
    SplittedArray: TArray<String>;
    FieldReference: String;
  begin
    SplittedArray := AReferenceString.Split([' ']);
    ATableReference := Trim(SplittedArray[1]);
    FieldReference := Trim(SplittedArray[2]);
    FieldReference := TDBField.ClearString(FieldReference);
    AFieldReference := FieldReference;
  end;

  function _PareseTableName(const ASource: String): String;
  var
    SplittedArray: TArray<String>;
  begin
    SplittedArray := ASource.Split([' ']);

    Result := SplittedArray[2];
  end;

var
  SplittedArray: TArray<String>;
  DDLString: String;
  ParsingString: String;
  TrimedString: String;
  DBField: TDBField;
  DoBreak: Boolean;
  i: Integer;
  ForeignKey: String;
  TableReference: String;
  FieldReference: String;
  Reference: String;
  ForeignKeyField: TDBField;
  TableName: String;
begin
  DDLString := ADDLString;
  SplittedArray := DDLString.Split([#10]);
  TableName := _PareseTableName(SplittedArray[0]);

  DoBreak := false;
  for DDLString in SplittedArray do
  begin
    ParsingString := String.LowerCase(DDLString);
    if not ContainsExcludingDDLString(ParsingString) then
    begin
      TrimedString := Trim(ParsingString);
      if TrimedString.Length > 0 then
      begin
        DBField := TDBField.CreateDBField(TableName, TrimedString);
        Add(DBField);
      end;
    end
    else
    begin
      // Первую строку пропускаем, в ней нет полей
      // И окончательно выходим из цикла, когда поля заканчиваются
      if not DoBreak then
        DoBreak := true
      else
        Break;
    end;
  end;

  i := 0;
  while i < Length(SplittedArray) do
  begin
    ParsingString := String.LowerCase(SplittedArray[i]);
    if ParsingString.Contains('foreign key') then
    begin
      Inc(i);

      ForeignKey := Trim(SplittedArray[i]);
      ForeignKeyField := Field[ForeignKey];
      ForeignKeyField.IsForeignKey := true;

      Inc(i, 2);

      Reference := Trim(SplittedArray[i]);
      _ParseReference(Reference, TableReference, FieldReference);

      ForeignKeyField.TableReference := TableReference;
      ForeignKeyField.FieldReference := FieldReference;
    end;

    Inc(i);
  end;
end;

function TDBRow.GetField(const AName: String): TDBField;
var
  Field: TDBField;
begin
  for Field in Self do
  begin
    if Field.FieldName = AName then
      Exit(Field);
  end;

  raise Exception.
    CreateFmt('TDBRow.GetField -> Field "%s" not found', [AName]);
end;

constructor TDBRow.Create(const ADDLString: String = '');
begin
  inherited Create;

  if ADDLString.IsEmpty then
    Exit;

  ParseDDLString(ADDLString);
end;

destructor TDBRow.Destroy;
begin
  while Count > 0 do
  begin
    Items[0].Free;
    Delete(0);
  end;

  inherited Destroy;
end;

{ TDBRowList }

constructor TDBRowList.Create(const ADDLTable: String = '');
begin
  inherited Create;

  FDDLRowPattern := nil;

  SetDDLRowPattern(ADDLTable);
end;

procedure TDBRowList.SetDDLRowPattern(const ADDLString: String);
begin
  if Assigned(FDDLRowPattern) then
    FreeAndNil(FDDLRowPattern);

  FDDLRowPattern := TDBRow.Create(ADDLString);
end;

procedure TDBRowList.Clear;
var
  i: Integer;
begin
  i := Count;
  while i > 0 do
  begin
    Dec(i);

    Items[i].Free;
    Delete(i);
  end;
end;

function TDBRowList.GetRow(const AIndex: Integer): TDBRow;
begin
  Result := Self.Items[AIndex]
end;

destructor TDBRowList.Destroy;
begin
  FreeAndNil(FDDLRowPattern);

  while Self.Count > 0 do
  begin
    Items[0].Free;
    Self.Delete(0);
  end;

  inherited Destroy;
end;

procedure TDBRowList.Add(const ADBRow: TDBRow);
begin
  if not Assigned(ADBRow) then
    raise Exception.Create('TDBRowList.Add -> ADBRow is nil');

  inherited Add(ADBRow);
end;

end.
