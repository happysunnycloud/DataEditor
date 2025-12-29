unit DataFormUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Memo.Types, System.Rtti,
  FMX.Grid.Style, FMX.Grid, FMX.ScrollBox, FMX.Memo, FMX.Objects, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Dialogs
  , DBRowUnit
  , DBFieldControlUnit, System.ImageList, FMX.ImgList
  ;

type
  TAcceptedProcRef = reference to procedure;

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
    DeleteSpeedButton: TSpeedButton;
    DeleteSpeedButtonImage: TImage;
    VerticalSplitter: TSplitter;
    HorizontalSplitter: TSplitter;
    AcceptSpeedButton: TSpeedButton;
    CancelSpeedButton: TSpeedButton;
    AcceptSpeedButtonImage: TImage;
    CancelSpeedButtonImage: TImage;
    AcceptLayout: TLayout;
    procedure DataStringGridCellClick(const Column: TColumn;
      const Row: Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure RefreshSpeedButtonClick(Sender: TObject);
    procedure UpdateSpeedButtonClick(Sender: TObject);
    procedure DuplicateSpeedButtonClick(Sender: TObject);
    procedure AddSpeedButtonClick(Sender: TObject);
    procedure DeleteSpeedButtonClick(Sender: TObject);
    procedure AcceptSpeedButtonClick(Sender: TObject);
    procedure CancelSpeedButtonClick(Sender: TObject);
  private
    { Private declarations }
    FDBFieldControlRegistry: TDBFieldControlRegistry;
    FDBRowList: TDBRowList;
    FCurrentRowIndex: Integer;
    FAcceptedProc: TAcceptedProcRef;

    procedure ClearContent;
    function InsertIntoTable(
      const ATableName: String;
      const AFieldList: String;
      const AValueList: String): Boolean;
    procedure CollectFieldList(
      var AFieldList: String;
      var AValueList: String;
      const ACollectValues: Boolean);

    function CollectPrimaryKeys: String;
    function FormatDBFieldString(
      const ADBField: TDBField;
      const AText: String;
      const ASplitter: String): String;

    function CheckFields: Boolean;

    function DecDataStringGridRowIndex: Integer;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent; AName: String); reintroduce;

    procedure SetTableName(const ATableName: String);
    procedure RefreshContent(
      const ATableName: String;
      const AWhereSection: String = '');
    procedure FillDBFieldControls(const ARowIndex: Integer);
    procedure DoInsert;
    property DBRowList: TDBRowList read FDBRowList write FDBRowList;
  end;

implementation

{$R *.fmx}

uses
    FMX.DialogService
  , DBAccessUnit
  , ParamsExtUnit
  , DataConnectorUnit
  , DBExceptionContainerUnit
  , FMX.DialogUnit
  , FMX.FormLayoutXMLUnit
  , CommonUnit
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

procedure TDataForm.CancelSpeedButtonClick(Sender: TObject);
begin
  FAcceptedProc := nil;

  AcceptLayout.Visible := false;
end;

procedure TDataForm.ClearContent;
//var
//  i: Integer;
//  Control: TControl;
begin
  ClearScrollBoxContent(DBFieldsScrollBox);
//  DBFieldsScrollBox.BeginUpdate;
//  DBFieldsScrollBox.ShowScrollBars := false;
//  try
//    i := DBFieldsScrollBox.Content.ControlsCount;
//    while i > 0 do
//    begin
//      Dec(i);
//
//      Control := DBFieldsScrollBox.Content.Controls[i];
//
//      if Control is TMemo then
//        TMemo(Control).ShowScrollBars := false;
//
//      FreeAndNil(Control);
//    end;
//
//    DBFieldsScrollBox.Content.Controls.Clear;
//  finally
//    DBFieldsScrollBox.EndUpdate;
//    DBFieldsScrollBox.RecalcSize;
//    DBFieldsScrollBox.ShowScrollBars := true;
//  end;
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
  if FDBRowList.Count = 0 then
    Exit;

  if (ARowIndex < 0) or (ARowIndex > FDBRowList.Count - 1) then
    Exit;

  DBRow := FDBRowList[ARowIndex];

  for DBField in DBRow do
  begin
    DBFieldControl := FDBFieldControlRegistry.FindControlByField(DBField);
    DBFieldControl.Memo.Text := DBField.FieldValue;
  end;
end;

procedure TDataForm.DoInsert;
var
  FieldListText: String;
  ValueListText: String;
  NotNullCheking: Boolean;
begin
  NotNullCheking := true;
  FDBFieldControlRegistry.ForwardEnumerator(
    procedure (const AObject: TDBFieldControl; var ABreak: Boolean)
    begin
      if AObject.DBField.IsNotNull then
        if AObject.Memo.Text.Length = 0 then
        begin
          NotNullCheking := false;

          ABreak := true;
        end;
    end
  );

  if not NotNullCheking then
  begin
    TDialog.ShowMessage('Fields with the "not null" attribute must be filled in');

    Exit;
  end;

  CollectFieldList(FieldListText, ValueListText, true);
  if InsertIntoTable(Caption, FieldListText, ValueListText) then
  begin
    RefreshContent(Caption);

    DataStringGrid.Row := FCurrentRowIndex;
    FillDBFieldControls(FCurrentRowIndex);

    CancelSpeedButtonClick(nil);
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
      procedure (const AObject: TDBFieldControl; var ABreak: Boolean)
      begin
        AObject.Align := TAlignLayout.Top;
      end
    );
    DBFieldsScrollBox.EndUpdate;
  end;

  RefreshContent(ATableName);
end;

procedure TDataForm.DeleteSpeedButtonClick(Sender: TObject);
var
  ForeignKeyTableObjList: TForeignKeyTableObjList;
  ForeignKeyTableObj: TForeignKeyTableObj;
  ForeignKey: TForeignKey;
  References: String;
  IdFieldText: String;
  WhereSection: String;
  ParamsIn: TParamsExt;
  IsCanceled: Boolean;
  HasCascadDelete: Boolean;
begin
  // --- Находим кто смотрит на эту форму ---

  References := '';
  ForeignKeyTableObjList := TForeignKeyTableObjList.Create;
  try
    TDataConnector.GetForeignKeys(Caption, ForeignKeyTableObjList);

    HasCascadDelete := false;
    for ForeignKeyTableObj in ForeignKeyTableObjList do
    begin
      for ForeignKey in ForeignKeyTableObj.ForeignKeyObjList do
      begin
        if ForeignKey.HasDeleteCascade then
          HasCascadDelete := true;
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

  IsCanceled := false;
  if References.Length > 0 then
  begin
    if HasCascadDelete then
    begin
      References :=
        Concat(
          'Please note!', #10, #10,
          'This table has child records:', #10,
          References, #10,
          'Cascade delete will be applied');

      TDialog.Confirm(References,
        procedure(Confirmed: Boolean)
        begin
          if not Confirmed then
          begin
            IsCanceled := true
          end;
        end);
    end
    else
    begin
      References :=
        Concat(
          'Please note!', #10, #10,
          'This table has child records:', #10,
          References, #10,
          'Please delete the child records first and then repeat the action.');

      TDialog.ShowMessage(References);
    end;
  end;

  if IsCanceled then
    Exit;

  IdFieldText := CollectPrimaryKeys;
  WhereSection := Format('%s', [IdFieldText]);

  ParamsIn := TParamsExt.Create;
  try
    ParamsIn.Add(Caption, 'table_name');
    ParamsIn.Add(WhereSection, 'where_section');

    try
      TDBAccess.DBAParamsFunc(TDBAccess.DeleteFromTable, ParamsIn, nil);
    except
      on e: TDBExceptionContainer do
      begin
//        if e.Kind.ToString = 'ekUKViolated' then
//          ShowMessage(Concat('Violation of uniqueness', ' -> ', e.Message))
//        else
        if e.Kind.ToString = 'ekFKViolated' then
          ShowMessage(Concat('Violation of foreign key', ' -> ', e.Message));
      end;
    end;
  finally
    FreeAndNil(ParamsIn);
  end;

  RefreshContent(Caption);

  DataStringGrid.Row := DecDataStringGridRowIndex;
  FillDBFieldControls(FCurrentRowIndex);
end;

function TDataForm.InsertIntoTable(
  const ATableName: String;
  const AFieldList: String;
  const AValueList: String): Boolean;
var
  ParamsIn: TParamsExt;
begin
  Result := false;

  ParamsIn := TParamsExt.Create;
  try
    ParamsIn.Add(ATableName, 'table_name');
    ParamsIn.Add(AFieldList, 'filed_list');
    ParamsIn.Add(AValueList, 'value_list');
    try
      TDBAccess.DBAParamsFunc(TDBAccess.InsertIntoTable, ParamsIn, nil);

      Result := true;
    except
      on e: TDBExceptionContainer do
      begin
        if e.Kind.ToString = 'ekUKViolated' then
          ShowMessage(Concat('Violation of uniqueness', ' -> ', e.Message))
        else
        if e.Kind.ToString = 'ekFKViolated' then
          ShowMessage(Concat('Violation of foreign key', ' -> ', e.Message));
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
      procedure (const AObject: TDBFieldControl; var ABreak: Boolean)
      var
        DBField: TDBField;
      begin
        DBField := AObject.DBField;
        MemoText := AObject.Memo.Text;
        if DBField.IsAutoIncrement then
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

          if DBField.FieldType = FIELD_TYPE_TEXT then
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

function TDataForm.CollectPrimaryKeys: String;
var
  PrimaryKeys: String;
begin
  Result := '';

  FDBFieldControlRegistry.ForwardEnumerator(
    procedure (const AObject: TDBFieldControl; var ABreak: Boolean)
    var
      DBField: TDBField;
      MemoText: String;
    begin
      DBField := AObject.DBField;
      MemoText := AObject.Memo.Text;
      if DBField.IsPrimaryKey then
      begin
        if PrimaryKeys.Length = 0 then
          PrimaryKeys :=
            FormatDBFieldString(DBField, MemoText, '')
        else
          PrimaryKeys :=
            Concat(PrimaryKeys, ' and ', FormatDBFieldString(DBField, MemoText, ''));
      end;
    end
  );

  Result := PrimaryKeys;
end;

function TDataForm.CheckFields: Boolean;
var
  IsNotNull: Boolean;
  IsForeignKey: Boolean;
  NotNullWarning: String;
  NullFields: String;
  ForeignKeysWarning: String;
  EmptyForeignKeys: String;
begin
  Result := false;

  NullFields := '';
  NotNullWarning :=
    'Fields marked with the NOT NULL attribute cannot be empty';

  EmptyForeignKeys := '';
  ForeignKeysWarning :=
    'The fields are foreign keys and must be populated' + #10 +
    'Otherwise, the relationship between the tables for this record will be broken';

  FDBFieldControlRegistry.ForwardEnumerator(
    procedure (const AObject: TDBFieldControl; var ABreak: Boolean)
    var
      DBField: TDBField;
    begin
      DBField := AObject.DBField;

      IsNotNull := DBField.IsNotNull;
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

  Result := true;
end;

function TDataForm.DecDataStringGridRowIndex: Integer;
begin
  if DataStringGrid.RowCount = 0 then
    FCurrentRowIndex := -1
  else
    Dec(FCurrentRowIndex);
  Result := FCurrentRowIndex;
end;

function TDataForm.FormatDBFieldString(
  const ADBField: TDBField;
  const AText: String;
  const ASplitter: String): String;
var
  Text: String;
begin
  Text := AText;
  if ADBField.FieldType = FIELD_TYPE_TEXT then
    Text := QuotedStr(Text);

  Result := Format('%s = %s%s', [ADBField.FieldName, Text, ASplitter]);
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

procedure TDataForm.AcceptSpeedButtonClick(Sender: TObject);
begin
  if Assigned(FAcceptedProc) then
    FAcceptedProc;
end;

procedure TDataForm.AddSpeedButtonClick(Sender: TObject);
begin
  // Установим дефолтные значения по паттерну
  FDBFieldControlRegistry.ForwardEnumerator(
    procedure (const AObject: TDBFieldControl; var ABreak: Boolean)
    var
      DBField: TDBField;
    begin
      DBField := FDBRowList.DDLRowPattern.Field[AObject.DBField.FieldName];
      AObject.Memo.Text := DBField.FieldValue;
    end
  );

  FAcceptedProc := DoInsert;

  AcceptLayout.Visible := true;
end;

procedure TDataForm.UpdateSpeedButtonClick(Sender: TObject);
var
  FieldList: TStringList;
  FieldString: String;
  MemoText: String;
  FieldListText: String;
  WhereSection: String;
  IdFieldText: String;
  ParamsIn: TParamsExt;
begin
  if not CheckFields then
    Exit;

  IdFieldText := CollectPrimaryKeys;

  FieldList := TStringList.Create;
  try
    try
      FDBFieldControlRegistry.ForwardEnumerator(
        procedure (const AObject: TDBFieldControl; var ABreak: Boolean)
        var
          DBField: TDBField;
        begin
          DBField := AObject.DBField;
          MemoText := AObject.Memo.Text;

          FieldString := FormatDBFieldString(DBField, MemoText, ', ');
          FieldList.Add(FieldString);
        end
      );

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
        if ForeignKeyDBField.FieldType = FIELD_TYPE_TEXT then
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

    for ForeignKeyTableObj in ForeignKeyTableObjList do
    begin
      WhereSection := 'where ';

      for ForeignKey in ForeignKeyTableObj.ForeignKeyObjList do
      begin
        ForeignKeyDBField := DBRow.Field[ForeignKey.FieldName];
        FieldValue := ForeignKeyDBField.FieldValue;
        if ForeignKeyDBField.FieldType = FIELD_TYPE_TEXT then
          FieldValue := QuotedStr(FieldValue);

        WhereSection := WhereSection +
          Format('%s = %s and ', [ForeignKey.FieldReference, FieldValue]);
      end;

      WhereSection := Trim(WhereSection);
      WhereSection := Copy(WhereSection, 1, Length(WhereSection) - Length('and'));

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

constructor TDataForm.Create(AOwner: TComponent; AName: String);
begin
  inherited Create(AOwner);

  FDBFieldControlRegistry := nil;
  FDBRowList := nil;
  FCurrentRowIndex := -1;
  FAcceptedProc := nil;

  Name := AName;
end;

procedure TDataForm.FormCreate(Sender: TObject);
begin
  TLayoutHelper.LoadFormLayout(Self);

  FDBRowList := TDBRowList.Create;
  FDBFieldControlRegistry := TDBFieldControlRegistry.Create;

  AcceptLayout.Visible := false;
end;

procedure TDataForm.FormDestroy(Sender: TObject);
begin
  TLayoutHelper.SaveFormLayout(Self);

  FreeAndNil(FDBRowList);
  FreeAndNil(FDBFieldControlRegistry);
end;

end.

