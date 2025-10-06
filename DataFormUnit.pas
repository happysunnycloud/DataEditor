unit DataFormUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.Rtti,
  FMX.Grid.Style, FMX.Layouts, FMX.Controls.Presentation, FMX.ScrollBox,
  FMX.Grid, FMX.Memo.Types, FMX.Memo, FMX.StdCtrls
  , DBRowUnit
  , DBFieldControlUnit
  ;

type
  TDataForm = class(TForm)
    DBFieldsLayout: TLayout;
    DBFieldsScrollBox: TScrollBox;
    DataGridLayout: TLayout;
    SQLLayout: TLayout;
    DDLMemo: TMemo;
    DataStringGrid: TStringGrid;
    FieldsPanel: TPanel;
    Label1: TLabel;
    LeftLayout: TLayout;
    procedure DataStringGridCellClick(const Column: TColumn;
      const Row: Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    FDBFieldControlRegistry: TDBFieldControlRegistry;
    FDBRowList: TDBRowList;

    procedure ClearContent;
  public
    { Public declarations }
    procedure SetTableName(const ATableName: String);
    procedure RefreshContent(
      const ATableName: String;
      const AWhereSection: String = '');

    property DBRowList: TDBRowList read FDBRowList write FDBRowList;
  end;

implementation

{$R *.fmx}

uses
    DBAccessUnit
  , ParamsExtUnit
  , DataConnectorUnit
  ;


function FindDataForm(const ATableName: String): TDataForm;
var
  DataForm: TDataForm;
  Form: TCommonCustomForm;
  i: Integer;
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
      Exit(DataForm);
  end;

  raise Exception.CreateFmt('DataForm "%s" not found', [ATableName]);
end;

{ TDataForm }

procedure TDataForm.ClearContent;
var
  i: Integer;
  Control: TControl;
begin
  DBFieldsScrollBox.BeginUpdate;
  DBFieldsScrollBox.ShowScrollBars := false;
  try
    i := DBFieldsScrollBox.Content.ControlsCount;
    while i > 0 do
    begin
      Dec(i);

      Control := DBFieldsScrollBox.Content.Controls[i];
      FreeAndNil(Control);
    end;

    DBFieldsScrollBox.Content.Controls.Clear;
  finally
    DBFieldsScrollBox.EndUpdate;
    DBFieldsScrollBox.RecalcSize;
    DBFieldsScrollBox.ShowScrollBars := true;
  end;
end;

procedure TDataForm.RefreshContent(
  const ATableName: String;
  const AWhereSection: String = '');

  function _GetColByHeader(
    const ADataStringGrid: TStringGrid; const AFiledName: String): Integer;
  var
    i: Integer;
  begin
    Result := 0;

    i := ADataStringGrid.ColumnCount;
    while i > 0 do
    begin
      Dec(i);

      if ADataStringGrid.Columns[i].Header = AFiledName then
        Exit(i);
    end;
  end;

var
  ParamsIn: TParamsExt;
  ParamsOut: TParamsExt;
  DBRow: TDBRow;
  DBField: TDBField;
  Col, Row: Integer;
begin
  DBRowList.Clear;

  DataStringGrid.BeginUpdate;
  try
    DataStringGrid.RowCount := 0;
  finally
    DataStringGrid.EndUpdate;
  end;

  ParamsIn := TParamsExt.Create;
  ParamsOut := TParamsExt.Create;
  try
    ParamsIn.Add(ATableName, 'table_name');
    ParamsIn.Add(FDBRowList, 'DBRowList');
    ParamsIn.Add(AWhereSection, 'where');

    TDBAccess.DBAParamsFunc(TDBAccess.SelectFromTable, ParamsIn, ParamsOut);
  finally
    FreeAndNil(ParamsOut);
    FreeAndNil(ParamsIn);
  end;

//  DataStringGrid.RowCount := 0;

  for DBRow in FDBRowList do
  begin
    DataStringGrid.RowCount := DataStringGrid.RowCount + 1;
    Row := DataStringGrid.RowCount - 1;
    for DBField in DBRow do
    begin
      Col := _GetColByHeader(DataStringGrid, DBField.FieldName);

      DataStringGrid.Cells[Col, Row] := DBField.FieldValue;
    end;
  end;
end;

procedure TDataForm.SetTableName(const ATableName: String);

  procedure _AddCol(const ADataStringGrid: TStringGrid; const AHeader: String);
  var
    Col: TColumn;
  begin
    Col := TStringColumn.Create(DataStringGrid);
    Col.Header := AHeader;
    DataStringGrid.AddObject(Col);
  end;

var
  ParamsIn: TParamsExt;
  ParamsOut: TParamsExt;
  DDLString: String;
  DBField: TDBField;
  DBFieldControl: TDBFieldControl;
begin
  ClearContent;

  if Assigned(FDBRowList) then
    FreeAndNil(FDBRowList);

  FDBRowList := TDBRowList.Create;

  Caption := ATableName;

  ParamsIn := TParamsExt.Create;
  ParamsOut := TParamsExt.Create;
  try
    ParamsIn.Add(ATableName, 'table_name');

    TDBAccess.DBAParamsFunc(TDBAccess.GetDDLForTable, ParamsIn, ParamsOut);
    DDLString := ParamsOut.AsStringByIdent['DDLString'];
    FDBRowList.SetDDLRowPattern(DDLString);
    DDLMemo.Text := DDLString;
  finally
    FreeAndNil(ParamsOut);
    FreeAndNil(ParamsIn);
  end;

  DBFieldsScrollBox.BeginUpdate;
  try
    for DBField in FDBRowList.DDLRowPattern do
    begin
      DBFieldControl := TDBFieldControl.Create(
        FDBFieldControlRegistry,
        DBFieldsScrollBox, DBField);
      DBFieldControl.Align := TAlignLayout.Bottom;

      _AddCol(DataStringGrid, DBField.FieldName);
    end;
  finally
    FDBFieldControlRegistry.ForwardEnumerator(
      procedure (const AObject: TDBFieldControl)
      begin
        AObject.Align := TAlignLayout.Top;
      end
    );
    DBFieldsScrollBox.EndUpdate;
  end;

  RefreshContent(ATableName);
end;

procedure TDataForm.DataStringGridCellClick(const Column: TColumn;
  const Row: Integer);
var
  DBRow: TDBRow;
  DBField: TDBField;
  DBFieldControl: TDBFieldControl;
  WhereSection: String;
  ForeignKeyDBField: TDBField;
  FieldValue: String;
//  ForeignKeyTableArray: TForeignKeyTableArray;
//  ForeignKeyTable: TForeignKeyTable;
//  ForeignKey: TForeignKey;
  TableName: String;

  ForeignKeyTableObjList: TForeignKeyTableObjList;
  ForeignKeyTableObj: TForeignKeyTableObj;
  ForeignKeyObj: TForeignKeyObj;
begin
  DBRow := FDBRowList[Row];

  for DBField in DBRow do
  begin
    DBFieldControl := FDBFieldControlRegistry.FindControlByField(DBField);
    DBFieldControl.Memo.Text := DBField.FieldValue;
  end;

  // --- Находим кто смотрит на эту форму ---

  ForeignKeyTableObjList := TForeignKeyTableObjList.Create;
  try
    TDataConnector.GetForeignKeys(Caption, ForeignKeyTableObjList);

    for ForeignKeyTableObj in ForeignKeyTableObjList do
    begin
      WhereSection := 'where ';
      for ForeignKeyObj in ForeignKeyTableObj.ForeignKeyObjList do
      begin
        ForeignKeyDBField := DBRow.Field[ForeignKeyObj.FieldReference];
        FieldValue := ForeignKeyDBField.FieldValue;
        if ForeignKeyDBField.FieldType = 'text' then
          FieldValue := QuotedStr(FieldValue);

        WhereSection := WhereSection +
          Format('%s = %s and ', [ForeignKeyObj.FieldName, FieldValue]);
      end;

      WhereSection := Trim(WhereSection);
      WhereSection := Copy(WhereSection, 1, Length(WhereSection) - Length('and'));

      TableName := ForeignKeyTableObj.TableName;
      FindDataForm(TableName).RefreshContent(TableName, WhereSection);
    end;
  finally
    FreeAndNil(ForeignKeyTableObjList);
  end;

  // --- Находим на кого смотрит эта форма ---

  ForeignKeyTableObjList := TForeignKeyTableObjList.Create;
  try
    for DBField in FDBRowList.DDLRowPattern do
    begin
      if DBField.IsForeignKey then
      begin
        // Собираем таблицы с внешними ключами
        ForeignKeyTableObj :=
          ForeignKeyTableObjList.ForeignKeyTableObj[DBField.TableReference];
        if not Assigned(ForeignKeyTableObj) then
        begin
          ForeignKeyTableObj := TForeignKeyTableObj.Create(DBField.TableReference);
          ForeignKeyTableObjList.Add(ForeignKeyTableObj);
        end;
//        ForeignKeyDBField := DBRow.Field[DBField.FieldName];
        ForeignKeyObj := TForeignKeyObj.Create(
          '',
          DBField.FieldName,
          '',
          DBField.FieldReference
        );
        ForeignKeyTableObj.ForeignKeyObjList.Add(ForeignKeyObj);
      end;
    end;

    DDLMemo.Text := '';
    for ForeignKeyTableObj in ForeignKeyTableObjList do
    begin
      WhereSection := 'where ';
      DDLMemo.Lines.Add(ForeignKeyTableObj.TableName);

      for ForeignKeyObj in ForeignKeyTableObj.ForeignKeyObjList do
      begin
        ForeignKeyDBField := DBRow.Field[ForeignKeyObj.FieldName];
        FieldValue := ForeignKeyDBField.FieldValue;
        if ForeignKeyDBField.FieldType = 'text' then
          FieldValue := QuotedStr(FieldValue);

        WhereSection := WhereSection +
          Format('%s = %s and ', [ForeignKeyObj.FieldReference, FieldValue]);
      end;

      WhereSection := Trim(WhereSection);
      WhereSection := Copy(WhereSection, 1, Length(WhereSection) - Length('and'));

      DDLMemo.Lines.Add(WhereSection);

      TableName := ForeignKeyTableObj.TableName;
      FindDataForm(TableName).RefreshContent(TableName, WhereSection);
    end;
  finally
    FreeAndNil(ForeignKeyTableObjList);
  end;
end;

procedure TDataForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TDataForm.FormCreate(Sender: TObject);
begin
  FDBRowList := TDBRowList.Create;
  FDBFieldControlRegistry := TDBFieldControlRegistry.Create;
end;

procedure TDataForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FDBRowList);
  FreeAndNil(FDBFieldControlRegistry);
end;

end.
