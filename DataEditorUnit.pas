unit DataEditorUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls
  , DataFormUnit, FMX.Layouts, FMX.Objects
  ;

const
//  DB_PATH = '..\..\DataBase\Purgaroty.db';
//  DB_PATH = 'DataBase\content.sqlite';
  SQL_TEMPLATES_PATH = '..\..\SQLTemplates\';
  CONFIG_FILE_DIR = 'Config';

type
  TMainForm = class(TForm)
    TablesScrollBox: TScrollBox;
    NavigatorLayout: TLayout;
    OpedSpeedButton: TSpeedButton;
    OpenDialog: TOpenDialog;
    OpedSpeedButtonImage: TImage;
    HearedLayout: TLayout;
    DBPathLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure OpedSpeedButtonClick(Sender: TObject);
  private
    { Private declarations }
    DataForm: TDataForm;

    function FindDataForm(const ATableName: String): TDataForm;
    procedure TableNameButtonClick(Sender: TObject);
    procedure GetTableList;
    procedure ReloadDB(const ADBPath: String);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
    DBAccessUnit
  , ConfigUnit
  , ParamsExtUnit
  , FMX.FormLayoutXMLUnit
  , CommonUnit
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

  DataForm := TDataForm.Create(Sender as TButton, Concat('DataForm_', TableName));
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
  XMLFormsList: TArray<string>;
  FormName: String;
  FormFound: Boolean;
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

    // Чистим XML от лишних настроек
    // Если такой таблицы нет в базе, то и ее настройки тоже не нужны
    XMLFormsList := TLayoutHelper.GetFormsList;
    for FormName in XMLFormsList do
    begin
      FormFound := false;
      for TableName in TableList do
      begin
        if FormName = Concat('DataForm_', TableName) then
          FormFound := true;
      end;

      if not FormFound then
        TLayoutHelper.DeleteFormLayout(FormName);
    end;
  finally
    FreeAndNil(TableList);
  end;
end;

procedure TMainForm.OpedSpeedButtonClick(Sender: TObject);
var
  FileName: String;
begin
  OpenDialog.InitialDir := ExtractFileDir(TConfig.DBPath);
  if OpenDialog.Execute then
  begin
    FileName := OpenDialog.FileName;
    TConfig.DBPath := FileName;

    // Формы уничтожаются, через кнопки создавшие их

    ClearScrollBoxContent(TablesScrollBox);

    ReloadDB(TConfig.DBPath);
  end;
end;

procedure TMainForm.ReloadDB(const ADBPath: String);
var
  DBXMLFileName: String;
begin
  TDBAccess.UnInit;
  TDBAccess.Init(TConfig.DBPath, SQL_TEMPLATES_PATH);

  DBPathLabel.Text := TConfig.DBPath;

  DBXMLFileName := Concat(CONFIG_FILE_DIR, '\', ExtractFileName(ADBPath), '.xml');
  TLayoutHelper.Init(DBXMLFileName);

  GetTableList;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  ReportMemoryLeaksOnShutdown := true;

  if not DirectoryExists(CONFIG_FILE_DIR) then
    CreateDir(CONFIG_FILE_DIR);

  TConfig.Init(Self, Concat(CONFIG_FILE_DIR, '\', 'Config.xml'));
  TConfig.LoadConfig;

  ReloadDB(TConfig.DBPath);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  TDBAccess.UnInit;

  TLayoutHelper.SaveFormLayout(Self);

  TConfig.SaveConfig;
end;

end.
