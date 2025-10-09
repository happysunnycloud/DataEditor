unit DBRowUnit;

interface

uses
    System.Generics.Collections
  , System.Classes
  ;

const
  ExcludingDDLString: array[0..4] of string = ('create', 'foreign key', 'references', '(', ')');
  ExcludingChars: array[0..2] of Char = (',', '(', ')');

const
  NULL_ID = -1;
  FIELD_TYPE_TEXT = 'text';
  FIELD_TYPE_INTEGER = 'integer';

type
  TDBField = class
  strict private
    FTableName: String;
    FFieldName: String;
    FFieldType: String;
    FFieldValue: String;
    FIsPrimaryKey: Boolean;
    FIsAutoIncrement: Boolean;
    FIsNotNull: Boolean;
    FIsUnique: Boolean;
    FIsForeignKey: Boolean;
    FHasUpdateCascade: Boolean;
    FHasDeleteCascade: Boolean;
    FTableReference: String;
    FFieldReference: String;
  public
    constructor Create;

    property TableName: String read FTableName write FTableName;
    property FieldName: String read FFieldName write FFieldName;
    property FieldType: String read FFieldType write FFieldType;
    property FieldValue: String read FFieldValue write FFieldValue;
    property IsPrimaryKey: Boolean read FIsPrimaryKey write FIsPrimaryKey;
    property IsAutoIncrement: Boolean read FIsAutoIncrement write FIsAutoIncrement;
    property IsNotNull: Boolean read FIsNotNull write FIsNotNull;
    property IsUnique: Boolean read FIsUnique write FIsUnique;
    property IsForeignKey: Boolean read FIsForeignKey write FIsForeignKey;
    property HasUpdateCascade: Boolean read FHasUpdateCascade write FHasUpdateCascade;
    property HasDeleteCascade: Boolean read FHasDeleteCascade write FHasDeleteCascade;
    property TableReference: String read FTableReference write FTableReference;
    property FieldReference: String read FFieldReference write FFieldReference;

    procedure CopyFrom(const ADBField: TDBField);

    class function ClearString(const ADirtString: String): String;
    class function CreateDBField(
      const ATableName: String;
      const AFieldString: String): TDBField;

    class function CreateDefaulDBField(
      const ATableName: String;
      const AFieldName: String;
      const AFieldType: String;
      const AFieldValue: String = ''): TDBField;
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
  FIsPrimaryKey := false;
  FIsAutoIncrement := false;
  FIsNotNull := false;;
  FIsUnique := false;
  FIsForeignKey := false;
  FHasUpdateCascade := false;
  FHasDeleteCascade := false;
  FTableReference := '';
  FFieldReference := '';
end;

class function TDBField.CreateDefaulDBField(
  const ATableName: String;
  const AFieldName: String;
  const AFieldType: String;
  const AFieldValue: String = ''): TDBField;
begin
  Result := TDBField.Create;
  Result.TableName := ATableName;
  Result.FieldName := AFieldName;
  Result.FieldType := AFieldType;
  if AFieldValue.Length > 0 then
  begin
    Result.FieldValue := AFieldValue
  end
  else
  begin
    if Result.FieldType = FIELD_TYPE_INTEGER then
      Result.FieldValue := '0';
  end;
end;

procedure TDBField.CopyFrom(const ADBField: TDBField);
begin
  FTableName := ADBField.TableName;
  FFieldName := ADBField.FieldName;
  FFieldType := ADBField.FieldType;
  FFieldValue := ADBField.FieldValue;
  FIsPrimaryKey := ADBField.IsPrimaryKey;
  FIsAutoIncrement := ADBField.IsAutoIncrement;
  FIsForeignKey := ADBField.IsForeignKey;
  FHasUpdateCascade := ADBField.HasUpdateCascade;
  FHasDeleteCascade := ADBField.HasDeleteCascade;
  FTableReference := ADBField.TableReference;
  FFieldReference := ADBField.FieldReference;
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

    Result :=
      TDBField.CreateDefaulDBField(
        ATableName,
        FieldName,
        FieldType);

    Result.IsPrimaryKey := AFieldString.Contains('primary key');
    Result.IsAutoIncrement := AFieldString.Contains('autoincrement');
    Result.IsNotNull := AFieldString.Contains('not null');
    Result.IsUnique := AFieldString.Contains('unique');
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
type
  TStringArray = TArray<String>;

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

  procedure _CheckCascade(
    const ASplittedArray: TStringArray;
    const AIndex: Integer;
    const AForeignKeyField: TDBField);
  begin
    if AIndex < Length(ASplittedArray) then
    begin
      if ASplittedArray[AIndex].Contains('on update cascade') then
        AForeignKeyField.HasUpdateCascade := true
      else
      if ASplittedArray[AIndex].Contains('on delete cascade') then
        AForeignKeyField.HasDeleteCascade := true;
    end;
  end;

  function _CreateDBField(
    const ATableName: String;
    const ADDLString: String): TDBField;
  begin
    Result := TDBField.CreateDBField(ATableName, ADDLString);
    Add(Result);
  end;

  function _AddLF(const ADDLString: String): String;
  var
    DDLString: String;
    i: Integer;
    LF: Char;
  begin
    Result := '';

    LF := #10;

    DDLString := ADDLString;
    for i := 1 to Length(DDLString) do
    begin
      if (DDLString[i] = '(') or
         (DDLString[i] = ',') or
         (DDLString[i] = ';')
      then
      begin
        Result := Result + DDLString[i] + LF;
      end
      else
      if (DDLString[i] = ')')
      then
      begin
        Result := Result + LF + DDLString[i];
      end
      else
        Result := Result + DDLString[i];
    end;
  end;

  procedure _ParsePrimaryKeys(
    const ASplittedArray: TStringArray;
    const AIndex: Integer);
  var
    i: Integer;
    TrimmedString: String;
    ClearString: String;
  begin
    i := AIndex;
    while i < Length(ASplittedArray) do
    begin
      TrimmedString := Trim(ASplittedArray[i]);
      if TrimmedString = ')' then
        Break;

      ClearString := TDBField.ClearString(TrimmedString);
      Self.Field[ClearString].IsPrimaryKey := true;

      Inc(i);
    end;
  end;

var
  SplittedArray: TStringArray;
  DDLString: String;
  ParsingString: String;
  TrimedString: String;
  DoBreak: Boolean;
  i, j: Integer;
  ForeignKey: String;
  TableReference: String;
  FieldReference: String;
  Reference: String;
  ForeignKeyField: TDBField;
  TableName: String;
begin
  DDLString := ADDLString;
  SplittedArray := DDLString.Split([#10]);

  if Length(SplittedArray) = 1 then
  begin
    DDLString := _AddLF(SplittedArray[0]);
    SplittedArray := DDLString.Split([#10]);
  end;

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
        _CreateDBField(TableName, TrimedString);
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

  // Если primary key составной
  i := 0;
  while i < Length(SplittedArray) do
  begin
    ParsingString := String.LowerCase(SplittedArray[i]);
    if ParsingString.Contains('primary key (') then
    begin
      Inc(i);

      _ParsePrimaryKeys(SplittedArray, i);

      Break;
    end;

    Inc(i);
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

      j := i + 1;
      _CheckCascade(SplittedArray, j, ForeignKeyField);
      j := j + 1;
      _CheckCascade(SplittedArray, j, ForeignKeyField);
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
