unit DBAccessUnit;

interface

uses
    System.SyncObjs
  , DBAccessClassUnit
  , ParamsExtUnit
//  , SQLTemplatesUnit
  ;


type
  TDBAccess = class(TDBAccessClass)
  strict private
  public
    class function GetDDLForTable(
      const AInParams: TParamsExt;
      const AOutParams: TParamsExt): TDBAResultCode;

    class function SelectFromTable(
      const AInParams: TParamsExt;
      const AOutParams: TParamsExt): TDBAResultCode;
    class function GetTableList(
      const AInParams: TParamsExt;
      const AOutParams: TParamsExt): TDBAResultCode;
  end;

implementation

uses
    System.SysUtils
  , DBToolsUnit
  , Data.DB
  , DBExceptionContainerUnit
  , DBRowUnit
  , System.Classes
  ;

class function TDBAccess.GetDDLForTable(
  const AInParams: TParamsExt;
  const AOutParams: TParamsExt): TDBAResultCode;
const
  METHOD = 'TDBAccess.GetDDLForTable';
var
  DBTools: TDBTools;
  SQLTemplateIdent: String;
  SQLTemplate: String;
  QueryResult: TDBQuery;
  TableName: String;
  DDLString: String;
  Field: TField;
  FieldName: String;
begin
  try
    SQLTemplateIdent := 'get_ddl_for_table';
    SQLTemplate := SQLTemplates.GetTemplate(SQLTemplateIdent);
    if Length(Trim(SQLTemplate)) = 0 then
      raise Exception.Create(Format('SQL template "%s" not found or empty', [SQLTemplateIdent]));

    DBTools := TDBTools.Create(DBFileName);

    try
      TableName := AInParams.AsStringByIdent['table_name'];

      DBTools.CreateQuery;
      DBTools.Query.ClearQuery;
      DBTools.Query.AddQuery(SQLTemplate);
      DBTools.Query.AddParameterAsString(':table_name', TableName);
      QueryResult := DBTools.OpenQuery;

      DDLString := QueryResult.FindField('sql').AsString;
      for Field in QueryResult.Fields do
      begin
        FieldName := Field.FieldName;
      end;

      DBTools.CloseQuery;
    finally
      DBTools.FreeQuery;
      FreeAndNil(DBTools);
    end;
    AOutParams.Clear;
    AOutParams.Add(DDLString, 'DDLString');
  except
    on e: Exception do
    begin
      raise TDBExceptionContainer.CreateExceptionContainer(e, METHOD);
    end;
  end;

  Result := rcOk;
end;

class function TDBAccess.SelectFromTable(
  const AInParams: TParamsExt;
  const AOutParams: TParamsExt): TDBAResultCode;

  function _GenFieldList(const ADBRow: TDBRow): String;
  var
    DBField: TDBField;
  begin
    Result := '';

    for DBField in ADBRow do
      Result := Concat(Result, DBField.FieldName, ', ', #10);


    Result := Result.Remove(Result.Length - 3);
  end;

const
  METHOD = 'TDBAccess.SelectFromTable';
var
  DBTools: TDBTools;
  SQLTemplateIdent: String;
  SQLTemplate: String;
  QueryResult: TDBQuery;
  TableName: String;
  Field: TField;
  DBRow: TDBRow;
  DBRowList: TDBRowList;
  DBField: TDBField;
  DBFieldTmp: TDBField;
  FiledList: String;
  WhereSection: String;
begin
  try
    SQLTemplateIdent := 'select_from_table';
    SQLTemplate := SQLTemplates.GetTemplate(SQLTemplateIdent);
    if Length(Trim(SQLTemplate)) = 0 then
      raise Exception.
        Create(Format('SQL template "%s" not found or empty', [SQLTemplateIdent]));

    DBTools := TDBTools.Create(DBFileName);

    try
      DBRowList := TDBRowList(AInParams.AsPointerByIdent['DBRowList']);
      if not Assigned(DBRowList) then
        raise Exception.Create('DBRowList is nil');

      FiledList := _GenFieldList(DBRowList.DDLRowPattern);
      TableName := AInParams.AsStringByIdent['table_name'];
      WhereSection := AInParams.IfAsStringByIdent('where', '');

      DBTools.CreateQuery;
      DBTools.Query.ClearQuery;
      DBTools.Query.AddQuery(SQLTemplate);
      DBTools.Query.AddParameterAsString(':table_name', TableName, false);
      DBTools.Query.AddParameterAsString(':field_list', FiledList, false);
      DBTools.Query.AddParameterAsString(':where', WhereSection, false);

      QueryResult := DBTools.OpenQuery;
      while not QueryResult.Eof do
      begin
        DBRow := TDBRow.Create;
        DBRowList.Add(DBRow);

        for Field in QueryResult.Fields do
        begin
          DBField := TDBField.Create;
          DBField.TableName := TableName;
          DBField.FieldName := Field.FieldName;
          DBField.FieldValue := Field.AsString;
          DBFieldTmp := DBRowList.DDLRowPattern.Field[Field.FieldName];
          DBField.FieldType := DBFieldTmp.FieldType;

          DBRow.Add(DBField);
        end;

        QueryResult.Next;
      end;
      DBTools.CloseQuery;
    finally
      DBTools.FreeQuery;
      FreeAndNil(DBTools);
    end;
    AOutParams.Clear;
  except
    on e: Exception do
    begin
      raise TDBExceptionContainer.CreateExceptionContainer(e, METHOD);
    end;
  end;

  Result := rcOk;
end;

class function TDBAccess.GetTableList(
  const AInParams: TParamsExt;
  const AOutParams: TParamsExt): TDBAResultCode;

  function _GenFieldList(const ADBRow: TDBRow): String;
  var
    DBField: TDBField;
  begin
    Result := '';

    for DBField in ADBRow do
      Result := Concat(Result, DBField.FieldName, ', ', #10);


    Result := Result.Remove(Result.Length - 3);
  end;

const
  METHOD = 'TDBAccess.GetTableList';
var
  DBTools: TDBTools;
  SQLTemplateIdent: String;
  SQLTemplate: String;
  QueryResult: TDBQuery;
  TabledList: TStringList;
  TableName: String;
begin
  try
    SQLTemplateIdent := 'get_table_list';
    SQLTemplate := SQLTemplates.GetTemplate(SQLTemplateIdent);
    if Length(Trim(SQLTemplate)) = 0 then
      raise Exception.
        Create(Format('SQL template "%s" not found or empty', [SQLTemplateIdent]));

    DBTools := TDBTools.Create(DBFileName);
    try
      TabledList := TStringList(AInParams.AsPointerByIdent['TableList']);
      if not Assigned(TabledList) then
        raise Exception.Create('TabledList is nil');

      DBTools.CreateQuery;
      DBTools.Query.ClearQuery;
      DBTools.Query.AddQuery(SQLTemplate);

      QueryResult := DBTools.OpenQuery;
      while not QueryResult.Eof do
      begin
        TableName := QueryResult.FindField('tbl_name').AsString;
        TabledList.Add(TableName);

        QueryResult.Next;
      end;
      DBTools.CloseQuery;
    finally
      DBTools.FreeQuery;
      FreeAndNil(DBTools);
    end;
    AOutParams.Clear;
  except
    on e: Exception do
    begin
      raise TDBExceptionContainer.CreateExceptionContainer(e, METHOD);
    end;
  end;

  Result := rcOk;
end;


end.

