unit DBFieldUnit;

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
    FFieldName: String;
    FFieldType: String;
    FFieldValue: String;
  public
    constructor Create;

    property FieldName: String read FFieldName write FFieldName;
    property FieldType: String read FFieldType write FFieldType;
    property FieldValue: String read FFieldValue write FFieldValue;

    class function ClearString(const ADirtString: String): String;
    class function CreateDBField(const AFieldString: String): TDBField;
  end;

  // Переименовать в TDBRow
  // TDBFieldList -> TDBRow
  TDBRow = class(TList<TDBField>)
  strict private
    function ContainsExcludingDDLString(
      const ADDLString: String): Boolean;
    procedure GetDDLStringList(const ADDLString: String);

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
  public
    constructor Create(const ADDLTable: String = '');
    destructor Destroy; override;

    property Row[const AIndex: Integer]: TDBRow read GetRow;
    property DDLRowPattern: TDBRow read FDDLRowPattern;

    procedure Add(const ADBRow: TDBRow);
  end;

implementation

uses
    System.SysUtils
  ;

{ TDBField }

constructor TDBField.Create;
begin
  FFieldName := '';
  FFieldType := '';
  FFieldValue := '';
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

class function TDBField.CreateDBField(const AFieldString: String): TDBField;
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
    Result.FieldName := FieldName;
    Result.FieldType := FieldType;
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

procedure TDBRow.GetDDLStringList(const ADDLString: String);
var
  SplittedArray: TArray<String>;
  DDLString: String;
  ParsingString: String;
  TrimedString: String;
  DBField: TDBField;
  DoBreak: Boolean;
begin
  DDLString := ADDLString;
  SplittedArray := DDLString.Split([#10]);

  DoBreak := false;
  for DDLString in SplittedArray do
  begin
    ParsingString := String.LowerCase(DDLString);
    if not ContainsExcludingDDLString(ParsingString) then
    begin
      TrimedString := Trim(ParsingString);
      if TrimedString.Length > 0 then
      begin
        DBField := TDBField.CreateDBField(TrimedString);
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

  GetDDLStringList(ADDLString);
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

  FDDLRowPattern := TDBRow.Create(ADDLTable);
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
