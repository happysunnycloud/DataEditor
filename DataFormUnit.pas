unit DataFormUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.Rtti,
  FMX.Grid.Style, FMX.Layouts, FMX.Controls.Presentation, FMX.ScrollBox,
  FMX.Grid, FMX.Memo.Types, FMX.Memo
  , DBFieldUnit, FMX.StdCtrls
  ;

type
  TDataForm = class(TForm)
    DBFieldsLayout: TLayout;
    DBFieldsScrollBox: TScrollBox;
    DataGridLayout: TLayout;
    SQLLayout: TLayout;
    DDLMemo: TMemo;
    DataStringGrid: TStringGrid;
    Panel1: TPanel;
    Label1: TLabel;
    LeftLayout: TLayout;
    procedure FormDestroy(Sender: TObject);
    procedure DataStringGridCellClick(const Column: TColumn;
      const Row: Integer);
  private
    { Private declarations }
    FDBRowList: TDBRowList;
  public
    { Public declarations }

    constructor Create(AOwner: TComponent; const ATableName: String); reintroduce;
  end;

var
  DataForm: TDataForm;

implementation

{$R *.fmx}

uses
    DBAccessUnit
  , ParamsExtUnit
  , DBFieldControlUnit
  ;

{ TDataForm }

constructor TDataForm.Create(AOwner: TComponent; const ATableName: String);
  procedure _AddCol(const ADataStringGrid: TStringGrid; const AHeader: String);
  var
    Col: TColumn;
  begin
    Col := TStringColumn.Create(DataStringGrid);
    Col.Header := AHeader;
    DataStringGrid.AddObject(Col);
  end;

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
  DDLString: String;
  DBField: TDBField;
  DBFieldControl: TDBFieldControl;
  DBRow: TDBRow;
  Col, Row: Integer;
begin
  inherited Create(AOwner);

  Caption := ATableName;

  ParamsIn := TParamsExt.Create;
  ParamsOut := TParamsExt.Create;
  try
    ParamsIn.Add(ATableName, 'table_name');
    try
      TDBAccess.DBAParamsFunc(TDBAccess.GetDDLForTable, ParamsIn, ParamsOut);
      DDLString := ParamsOut.AsStringByIdent['DDLString'];
      DDLMemo.Text := DDLString;
    except
      on e: Exception do
        raise Exception.Create(e.Message);
    end;
  finally
    FreeAndNil(ParamsOut);
    FreeAndNil(ParamsIn);
  end;

//  DataStringGrid.RowCount := 1;

  FDBRowList := TDBRowList.Create(DDLString);
  for DBField in FDBRowList.DDLRowPattern do
  begin
    DBFieldControl := TDBFieldControl.Create(DBFieldsScrollBox, DBField);
    DBFieldControl.Align := TAlignLayout.Top;

    _AddCol(DataStringGrid, DBField.FieldName);
  end;

  // -----
  ParamsIn := TParamsExt.Create;
  ParamsOut := TParamsExt.Create;
  try
    ParamsIn.Add(ATableName, 'table_name');
    ParamsIn.Add(FDBRowList, 'DBRowList');
    try
      TDBAccess.DBAParamsFunc(TDBAccess.SelectFromTable, ParamsIn, ParamsOut);
    except
      on e: Exception do
        raise Exception.Create(e.Message);
    end;
  finally
    FreeAndNil(ParamsOut);
    FreeAndNil(ParamsIn);
  end;

  DataStringGrid.RowCount := 0;

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

procedure TDataForm.DataStringGridCellClick(const Column: TColumn;
  const Row: Integer);
var
  DBRow: TDBRow;
begin
  DBRow := FDBRowList[Row];
  DDLMemo.Text := DBRow[Column.Index].FieldValue;

end;

procedure TDataForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FDBRowList);
end;

end.
