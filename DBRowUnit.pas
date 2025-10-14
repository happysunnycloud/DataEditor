unit DBRowUnit;

interface

uses
    System.Generics.Collections
  , System.Classes
  ;

const
  NULL_ID = -1;
  FIELD_TYPE_TEXT = 'text';
  FIELD_TYPE_INTEGER = 'integer';
  PRIMARY_KEY = 'primary key';
  FOREIGN_KEY = 'foreign key';

  ExcludingDDLString: array[0..3] of string =
    ('create', PRIMARY_KEY, FOREIGN_KEY, 'references');
  ExcludingChars: array[0..2] of Char = (',', '(', ')');

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
    FDefault: String;
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
    property Default: String read FDefault write FDefault;

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
  , StringToolsUnit
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
  FDefault := ADBField.Default;
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

  function _ParseDefault(const AParsingString: String): String;
  var
    ParsingString: String;
  begin
    ParsingString :=
      StringReplace(AParsingString, 'default', '', [rfReplaceAll, rfIgnoreCase]);

    Result := ParsingString;
  end;

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

    Result.IsPrimaryKey := AFieldString.Contains(PRIMARY_KEY);
    Result.IsAutoIncrement := AFieldString.Contains('autoincrement');
    Result.IsNotNull := AFieldString.Contains('not null');
    Result.IsUnique := AFieldString.Contains('unique');

    if AFieldString.Contains('default') then
      Result.Default := _ParseDefault(ParsingString);
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
    if DDLString.StartsWith(ExcludingString) then
    begin
      Result := true;

      Break;
    end;
  end;
end;

function SplitDDLString(const ADDLString: String): TArray<String>;

  procedure _ReadToTheComma(
    const AString: String;
    out AOutString: String;
    out AOffsetIndex: Integer);
  var
    i: Integer;
    BrackerCount: Integer;
    c: Char;
  begin
    AOutString := '';
    AOffsetIndex := 1;
    BrackerCount := 0;
    i := 1;
    while i < Length(AString) do
    begin
      c := AString[i];
      if c = '(' then
        Inc(BrackerCount);
      if c = ')' then
        Dec(BrackerCount);

      if c = ',' then
        if BrackerCount = 0 then
          Break;

      AOutString := Concat(AOutString, c);
      AOffsetIndex := i + 1;

      Inc(i);
    end;
  end;

var
  DDLString: String;
  Position: Integer;
  Offset: Integer;
  SplittedString: String;
begin
  SetLength(Result, 0);

  Position := Pos('(', ADDLString);
  DDLString := ADDLString;
  DDLString := Copy(DDLString, Position + 1, Length(DDLString));

  while DDLString.Length > 0 do
  begin
    _ReadToTheComma(DDLString, SplittedString, Offset);

    SetLength(Result, Length(Result) + 1);
    Result[Length(Result) - 1] := Trim(SplittedString);

    DDLString := Copy(DDLString, Offset + 1, DDLString.Length);
  end;
end;

procedure TDBRow.ParseDDLString(const ADDLString: String);
type
  TStringArray = TArray<String>;

  function _ParseTableName(const ASource: String): String;
  var
    SplittedArray: TArray<String>;
  begin
    SplittedArray := ASource.Split([' ']);

    Result := SplittedArray[2];
  end;

  function _CreateDBField(
    const ATableName: String;
    const ADDLString: String): TDBField;
  begin
    Result := TDBField.CreateDBField(ATableName, ADDLString);
    Add(Result);
  end;

  procedure _ParsePrimaryKeys(
    const ADDLString: String);
  var
    DDLString: String;
    SplittedArray: TArray<String>;
    FieldName: String;
    i: Integer;
    ClearString: String;
    PositionFrom: Integer;
    PositionTo: Integer;
  begin
    DDLString := Trim(ADDLString);
    ClearString := TStringTools.ExtractFromBrackets(DDLString);
    SplittedArray := ClearString.Split([',']);

    i := 0;
    while i < Length(SplittedArray) do
    begin
      FieldName := Trim(SplittedArray[i]);
      Self.Field[FieldName].IsPrimaryKey := true;

      Inc(i);
    end;
  end;

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

  procedure _ParseForeignKey(const ADDLString: String);
  var
    Position: Integer;
    DDLString: String;
    FieldName: String;
    ForeignKeyField: TDBField;
    Reference: String;
    TableReference: String;
    FieldReference: String;
  begin
    Position := Pos('(', ADDLString);
    DDLString := Copy(ADDLString, Position + 1, Length(ADDLString));

    Position := Pos(')', DDLString);
    FieldName := Trim(Copy(DDLString, 1, Position - 1));

    ForeignKeyField := Field[FieldName];
    ForeignKeyField.IsForeignKey := true;

    Reference := Trim(Copy(DDLString, Position + 1, Length(DDLString)));
    _ParseReference(Reference, TableReference, FieldReference);

    ForeignKeyField.TableReference := TableReference;
    ForeignKeyField.FieldReference := FieldReference;

    if ADDLString.Contains('on update cascade') then
      ForeignKeyField.HasUpdateCascade := true;
    if ADDLString.Contains('on delete cascade') then
      ForeignKeyField.HasDeleteCascade := true;
  end;

  function _AddCommaIfAbsent(
    const ADDLString: String;
    const AOffset: Integer): String;
  var
    Position: Integer;
  begin
    Result := ADDLString;
    Position := Pos(FOREIGN_KEY, String.LowerCase(Result), AOffset);

    if Position > 0 then
    begin
      if ADDLString[Position - 1] <> ',' then
        Result := Result.Insert(Position - 1, ',');

      Result := _AddCommaIfAbsent(Result, Position + Length(FOREIGN_KEY));
    end
    else
      Exit;
  end;

  function _ClearSpace(const ADDLString: String): String;
  var
    i: Integer;
    IsSpaceFound: Boolean;
    c: Char;
  begin
    IsSpaceFound := false;
    for i := 1 to Length(ADDLString) do
    begin
      c := ADDLString[i];

      if (c = ' ') and IsSpaceFound then
        Continue;

      if c = ' ' then
        IsSpaceFound := true
      else
        IsSpaceFound := false;

      Result := Concat(Result, c);
    end;
  end;

var
  SplittedArray: TStringArray;
  DDLString: String;
  ParsingString: String;
  TrimedString: String;
  i: Integer;
  TableName: String;
begin
  DDLString := ADDLString;
  DDLString := _ClearSpace(DDLString);
  DDLString := StringReplace(DDLString, #10, '', [rfReplaceAll, rfIgnoreCase]);
  DDLString := StringReplace(DDLString, #13, '', [rfReplaceAll, rfIgnoreCase]);
  DDLString := StringReplace(DDLString, #9, '', [rfReplaceAll, rfIgnoreCase]);
  DDLString := StringReplace(DDLString, ', ', ',', [rfReplaceAll, rfIgnoreCase]);
  DDLString := _AddCommaIfAbsent(DDLString, 1);

  SplittedArray := SplitDDLString(DDLString);

  TableName := _ParseTableName(DDLString);

  i := 0;
  while i < Length(SplittedArray) do
  begin
    DDLString := SplittedArray[i];
    ParsingString := String.LowerCase(DDLString);

    if ContainsExcludingDDLString(ParsingString) then
      Break;

    TrimedString := Trim(ParsingString);
    if TrimedString.Length > 0 then
    begin
      _CreateDBField(TableName, TrimedString);
    end;

    Inc(i);
  end;

  i := 0;
  while i < Length(SplittedArray) do
  begin
    ParsingString := String.LowerCase(SplittedArray[i]);
    if ParsingString.StartsWith(PRIMARY_KEY) then
      _ParsePrimaryKeys(ParsingString);

    Inc(i);
  end;

  i := 0;
  while i < Length(SplittedArray) do
  begin
    ParsingString := String.LowerCase(SplittedArray[i]);
    if ParsingString.Contains(FOREIGN_KEY) then
      _ParseForeignKey(ParsingString);

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
