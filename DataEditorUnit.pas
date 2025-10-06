unit DataEditorUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls
  , DataFormUnit, FMX.Layouts
  ;

const
//  DB_PATH = '..\..\DataBase\Purgaroty.db';
  DB_PATH = 'C:\Desktop\TelegramBots\theme-tg-bot-content\content.sqlite';
  SQL_TEMPLATES_PATH = '..\..\SQLTemplates\';

type
  TMainForm = class(TForm)
    TablesScrollBox: TScrollBox;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    DataForm: TDataForm;

    function FindDataForm(const ATableName: String): TDataForm;
    procedure TableNameButtonClick(Sender: TObject);
    procedure GetTableList;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
    DBAccessUnit
  , ParamsExtUnit
  ;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TMainForm.TableNameButtonClick(Sender: TObject);
var
  TableName: String;
begin
  TableName := TButton(Sender).Text;
  if Assigned(FindDataForm(TableName)) then
  begin
    ShowMessage(Format('A DataForm named "%s" was found.', [TableName]));

    Exit;
  end;

  DataForm := TDataForm.Create(Self);
  DataForm.SetTableName(TableName);
  DataForm.Show;
end;

function TMainForm.FindDataForm(const ATableName: String): TDataForm;
var
  Form: TForm;
  DataForm: TDataForm;
  i: Integer;
begin
  Result := nil;

  i := Screen.FormCount;
  while i > 0 do
  begin
    Dec(i);

    Form := Screen.Forms[i] as TForm;
    if Form is TDataForm then
    begin
      DataForm := TDataForm(Form);
      if DataForm.Caption = ATableName then
        Exit(DataForm);
    end;
  end;
end;

procedure TMainForm.GetTableList;
var
  TableList: TStringList;
  ParamsIn: TParamsExt;
  ParamsOut: TParamsExt;
  TableName: String;
  TableNameButton: TButton;
begin
  TableList := TStringList.Create;
  try
    ParamsIn := TParamsExt.Create;
    ParamsOut := TParamsExt.Create;
    try
      ParamsIn.Add(TableList, 'TableList');
      TDBAccess.DBAParamsFunc(TDBAccess.GetTableList, ParamsIn, ParamsOut);

      for TableName in TableList do
      begin
        TableNameButton := TButton.Create(TablesScrollBox);
        TableNameButton.Parent := TablesScrollBox;
        TableNameButton.Align := TAlignLayout.Top;
        TableNameButton.Text := TableName;
        TableNameButton.Height := 30;
        TableNameButton.OnClick := TableNameButtonClick;
        TableNameButton.OnClick(TableNameButton);
      end;
    finally
      FreeAndNil(ParamsOut);
      FreeAndNil(ParamsIn);
    end;
  finally
    FreeAndNil(TableList);
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  ReportMemoryLeaksOnShutdown := true;

  TDBAccess.Init(DB_PATH, SQL_TEMPLATES_PATH);

  GetTableList;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  TDBAccess.UnInit;
end;

end.
