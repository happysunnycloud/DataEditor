unit DataFormUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.Rtti,
  FMX.Grid.Style, FMX.Layouts, FMX.Controls.Presentation, FMX.ScrollBox,
  FMX.Grid, FMX.Memo.Types, FMX.Memo, FMX.StdCtrls
  , DBRowUnit
  , DBFieldControlUnit, System.ImageList, FMX.ImgList, FMX.Objects
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
    NavigationLayout: TLayout;
    RefreshSpeedButton: TSpeedButton;
    RefreshSpeedButtonImage: TImage;
    UpdateSpeedButton: TSpeedButton;
    UpdateSpeedButtonImage: TImage;
    FunctionsLayout: TLayout;
    DuplicateSpeedButton: TSpeedButton;
    AddSpeedButton: TSpeedButton;
    DuplicateSpeedButtonImage: TImage;
    AddSpeedButtonImage: TImage;
    SpeedButton1: TSpeedButton;
    procedure DataStringGridCellClick(const Column: TColumn;
      const Row: Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure RefreshSpeedButtonClick(Sender: TObject);
    procedure UpdateSpeedButtonClick(Sender: TObject);
    procedure DuplicateSpeedButtonClick(Sender: TObject);
    procedure AddSpeedButtonClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
  private
    { Private declarations }
    FDBFieldControlRegistry: TDBFieldControlRegistry;
    FDBRowList: TDBRowList;
    FCurrentRowIndex: Integer;

    procedure ClearContent;
    procedure InsertIntoTable(
      const ATableName: String;
      const AFieldList: String;
      const AValueList: String);
    procedure CollectFieldList(
      var AFieldList: String;
      var AValueList: String;
      const ACollectValues: Boolean);
  public
    { Public declarations }
    procedure SetTableName(const ATableName: String);
    procedure RefreshContent(
      const ATableName: String;
      const AWhereSection: String = '');
    procedure FillDBFieldControls(const ARowIndex: Integer);

    property DBRowList: TDBRowList read FDBRowList write FDBRowList;
  end;

implementation

{$R *.fmx}

uses
    DBAccessUnit
  , ParamsExtUnit
  , DataConnectorUnit
  , DBExceptionContainerUnit
  , DebugUnit
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

procedure TDataForm.FillDBFieldControls(const ARowIndex: Integer);
var
  DBRow: TDBRow;
  DBField: TDBField;
  DBFieldControl: TDBFieldControl;
begin
  DBRow := FDBRowList[ARowIndex];

  for DBField in DBRow do
  begin
    DBFieldControl := FDBFieldControlRegistry.FindControlByField(DBField);
    DBFieldControl.Memo.Text := DBField.FieldValue;
  end;
end;

procedure TDataForm.RefreshSpeedButtonClick(Sender: TObject);
begin
  RefreshContent(Caption);
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

procedure TDataForm.SpeedButton1Click(Sender: TObject);
var
  DBRow: TDBRow;
  DBField: TDBField;
  DBFieldControl: TDBFieldControl;
  ForeignKeyDBField: TDBField;
  FieldValue: String;
  TableName: String;
  ForeignKeyTableObjList: TForeignKeyTableObjList;
  ForeignKeyTableObj: TForeignKeyTableObj;
  ForeignKey: TForeignKey;
  References: String;
  ParamsIn: TParamsExt;
begin
  DBRow := FDBRowList[FCurrentRowIndex];

  // --- Находим кто смотрит на эту форму ---

  References := '';
  ForeignKeyTableObjList := TForeignKeyTableObjList.Create;
  try
    TDataConnector.GetForeignKeys(Caption, ForeignKeyTableObjList);

    for ForeignKeyTableObj in ForeignKeyTableObjList do
    begin
      for ForeignKey in ForeignKeyTableObj.ForeignKeyObjList do
      begin
        if ForeignKey.HasDeleteCascade then
          References :=
            Concat(
              References,
              ForeignKeyTableObj.TableName,
              '.',
              ForeignKey.FieldReference,
              #10);
      end;
    end;
  finally
    FreeAndNil(ForeignKeyTableObjList);
  end;

  if References.Length > 0 then
  begin
    References :=
      Concat(
        'Внимание!', #10, #10,
        'На эту таблицу есть ссылки с каскадным удалением:', #10,
        References, #10,
        'Связанные записи так же бьудут удалены', #10,
        'Породолжить?');

    if MessageDlg(References, TMsgDlgType.mtConfirmation,
      [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], 0) = mrYes
    then
    begin
      ParamsIn := TParamsExt.Create;
      try
        ParamsIn.Add(Caption, 'table_name');
        DBRow.Field['id'];
      finally
        FreeAndNil(ParamsIn);
      end;
      DDLMemo.Text := References;
    end;
  end;
end;

procedure TDataForm.InsertIntoTable(
  const ATableName: String;
  const AFieldList: String;
  const AValueList: String);
var
  ParamsIn: TParamsExt;
begin
  ParamsIn := TParamsExt.Create;
  try
    ParamsIn.Add(ATableName, 'table_name');
    ParamsIn.Add(AFieldList, 'filed_list');
    ParamsIn.Add(AValueList, 'value_list');

    try
      TDBAccess.DBAParamsFunc(TDBAccess.InsertIntoTable, ParamsIn, nil);
    except
      on e: TDBExceptionContainer do
      begin
        if e.Kind.ToString = 'ekUKViolated' then
          ShowMessage(Concat('Violation of uniqueness', ' -> ', e.Message));
      end;
    end;
  finally
    FreeAndNil(ParamsIn);
  end;
end;

procedure TDataForm.CollectFieldList(
  var AFieldList: String;
  var AValueList: String;
  const ACollectValues: Boolean);
var
  IsNotNull: Boolean;
  IsForeignKey: Boolean;
  NotNullWarning: String;
  NullFields: String;
  ForeignKeysWarning: String;
  EmptyForeignKeys: String;
  FieldList: TStringList;
  ValueList: TStringList;
  FieldString: String;
  ValueString: String;
  MemoText: String;
  FieldListText: String;
  ValueListText: String;
  FieldValue: String;
begin
  AFieldList := '';
  AValueList := '';

  NullFields := '';
  NotNullWarning :=
    'Fields marked with the NOT NULL attribute cannot be empty';

  EmptyForeignKeys := '';
  ForeignKeysWarning :=
    'The fields are foreign keys and must be populated' + #10 +
    'Otherwise, the relationship between the tables for this record will be broken';

  FieldList := TStringList.Create;
  ValueList := TStringList.Create;
  try
    FDBFieldControlRegistry.ForwardEnumerator(
      procedure (const AObject: TDBFieldControl)
      var
        DBField: TDBField;
      begin
        DBField := AObject.DBField;
        MemoText := AObject.Memo.Text;
        if DBField.IsAutoIncrement or
           DBField.IsUnique
        then
        begin
          Exit;
        end
        else
        begin
          FieldString := Format('%s,', [DBField.FieldName]);
          FieldList.Add(FieldString);

          FieldValue := '';
          if ACollectValues then
            FieldValue := MemoText;

          if DBField.FieldType = 'text' then
            ValueString :=
              Format('%s,', [QuotedStr(FieldValue)])
          else
            ValueString :=
              Format('%s,', [FieldValue]);

          ValueList.Add(ValueString);

          IsNotNull := DBField.IsForeignKey;
          IsForeignKey := DBField.IsForeignKey;
          if IsNotNull then
            if AObject.Memo.Text.IsEmpty then
            begin
              NullFields := NullFields + #10 + DBField.FieldName;
            end;
          if IsForeignKey then
            if AObject.Memo.Text.IsEmpty then
            begin
              EmptyForeignKeys := EmptyForeignKeys + #10 + DBField.FieldName;
            end;
        end;
      end
    );

    if not NullFields.IsEmpty then
    begin
      ShowMessage(NotNullWarning + #10 + NullFields);

      Exit;
    end;

    if not EmptyForeignKeys.IsEmpty then
    begin
      ShowMessage(ForeignKeysWarning + #10 + EmptyForeignKeys);

      Exit;
    end;

    FieldListText := Trim(FieldList.Text);
    FieldListText := Copy(FieldListText, 1, Length(FieldListText) - 1);

    ValueListText := Trim(ValueList.Text);
    ValueListText := Copy(ValueListText, 1, Length(ValueListText) - 1);

    AFieldList := FieldListText;
    AValueList := ValueListText;
  finally
    FreeAndNil(ValueList);
    FreeAndNil(FieldList);
  end;
end;

procedure TDataForm.DuplicateSpeedButtonClick(Sender: TObject);
var
  FieldListText: String;
  ValueListText: String;
begin
  CollectFieldList(FieldListText, ValueListText, true);
  InsertIntoTable(Caption, FieldListText, ValueListText);

  RefreshContent(Caption);

  DataStringGrid.Row := FCurrentRowIndex;
  FillDBFieldControls(FCurrentRowIndex);
end;

procedure TDataForm.AddSpeedButtonClick(Sender: TObject);
var
  FieldListText: String;
  ValueListText: String;
begin
  CollectFieldList(FieldListText, ValueListText, false);
  InsertIntoTable(Caption, FieldListText, ValueListText);

  RefreshContent(Caption);

  DataStringGrid.Row := FCurrentRowIndex;
  FillDBFieldControls(FCurrentRowIndex);
end;

procedure TDataForm.UpdateSpeedButtonClick(Sender: TObject);
var
  IsNotNull: Boolean;
  IsForeignKey: Boolean;
  NotNullWarning: String;
  NullFields: String;
  ForeignKeysWarning: String;
  EmptyForeignKeys: String;
  FieldList: TStringList;
  FieldString: String;
  MemoText: String;
  FieldListText: String;
  WhereSection: String;
  IdFieldText: String;
  ParamsIn: TParamsExt;
begin
  NullFields := '';
  NotNullWarning :=
    'Fields marked with the NOT NULL attribute cannot be empty';

  EmptyForeignKeys := '';
  ForeignKeysWarning :=
    'The fields are foreign keys and must be populated' + #10 +
    'Otherwise, the relationship between the tables for this record will be broken';

  FieldList := TStringList.Create;
  try
    FDBFieldControlRegistry.ForwardEnumerator(
      procedure (const AObject: TDBFieldControl)
      var
        DBField: TDBField;
      begin
        DBField := AObject.DBField;
        MemoText := AObject.Memo.Text;
        if DBField.IsPrimaryKey then
        begin
          IdFieldText :=
            Format('%s = %s', [DBField.FieldName, MemoText])
        end
        else
        begin
          if DBField.FieldType = 'text' then
            FieldString :=
              Format('%s = %s,', [DBField.FieldName, QuotedStr(MemoText)])
          else
            FieldString :=
              Format('%s = %s,', [DBField.FieldName, MemoText]);

          FieldList.Add(FieldString);

          IsNotNull := DBField.IsForeignKey;
          IsForeignKey := DBField.IsForeignKey;
          if IsNotNull then
            if AObject.Memo.Text.IsEmpty then
            begin
              NullFields := NullFields + #10 + DBField.FieldName;
            end;
          if IsForeignKey then
            if AObject.Memo.Text.IsEmpty then
            begin
              EmptyForeignKeys := EmptyForeignKeys + #10 + DBField.FieldName;
            end;
        end;
      end
    );

    if not NullFields.IsEmpty then
    begin
      ShowMessage(NotNullWarning + #10 + NullFields);

      Exit;
    end;

    if not EmptyForeignKeys.IsEmpty then
    begin
      ShowMessage(ForeignKeysWarning + #10 + EmptyForeignKeys);

      Exit;
    end;

    FieldListText := Trim(FieldList.Text);
    FieldListText := Copy(FieldListText, 1, Length(FieldListText) - 1);

    WhereSection := Format('%s', [IdFieldText]);

    ParamsIn := TParamsExt.Create;
    try
      ParamsIn.Add(Caption, 'table_name');
      ParamsIn.Add(FieldListText, 'filed_list');
      ParamsIn.Add(WhereSection, 'where_section');

      try
        TDBAccess.DBAParamsFunc(TDBAccess.UpdateTable, ParamsIn, nil);
      except
        on e: TDBExceptionContainer do
        begin
          if e.Kind.ToString = 'ekUKViolated' then
            ShowMessage(Concat('Violation of uniqueness', ' -> ', e.Message));
        end;
      end;
    finally
      FreeAndNil(ParamsIn);
    end;
  finally
    FreeAndNil(FieldList);
  end;

  RefreshContent(Caption);

  DataStringGrid.Row := FCurrentRowIndex;
  FillDBFieldControls(FCurrentRowIndex);
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
  TableName: String;
  ForeignKeyTableObjList: TForeignKeyTableObjList;
  ForeignKeyTableObj: TForeignKeyTableObj;
  ForeignKey: TForeignKey;
begin
  FCurrentRowIndex := Row;

  DBRow := FDBRowList[FCurrentRowIndex];

  FillDBFieldControls(FCurrentRowIndex);

  // --- Находим кто смотрит на эту форму ---

  ForeignKeyTableObjList := TForeignKeyTableObjList.Create;
  try
    TDataConnector.GetForeignKeys(Caption, ForeignKeyTableObjList);

    for ForeignKeyTableObj in ForeignKeyTableObjList do
    begin
      WhereSection := 'where ';
      for ForeignKey in ForeignKeyTableObj.ForeignKeyObjList do
      begin
        ForeignKeyDBField := DBRow.Field[ForeignKey.FieldReference];
        FieldValue := ForeignKeyDBField.FieldValue;
        if ForeignKeyDBField.FieldType = 'text' then
          FieldValue := QuotedStr(FieldValue);

        WhereSection := WhereSection +
          Format('%s = %s and ', [ForeignKey.FieldName, FieldValue]);
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
        ForeignKey := TForeignKey.Create;
        ForeignKey.CopyFrom(DBField);
        ForeignKeyTableObj.ForeignKeyObjList.Add(ForeignKey);
      end;
    end;

    DDLMemo.Text := '';
    for ForeignKeyTableObj in ForeignKeyTableObjList do
    begin
      WhereSection := 'where ';
      DDLMemo.Lines.Add(ForeignKeyTableObj.TableName);

      for ForeignKey in ForeignKeyTableObj.ForeignKeyObjList do
      begin
        ForeignKeyDBField := DBRow.Field[ForeignKey.FieldName];
        FieldValue := ForeignKeyDBField.FieldValue;
        if ForeignKeyDBField.FieldType = 'text' then
          FieldValue := QuotedStr(FieldValue);

        WhereSection := WhereSection +
          Format('%s = %s and ', [ForeignKey.FieldReference, FieldValue]);
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
