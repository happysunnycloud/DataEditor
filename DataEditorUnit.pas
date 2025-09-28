unit DataEditorUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls
  , DataFormUnit
  ;

const
//  DB_PATH = '..\..\DataBase\Purgaroty.db';
  DB_PATH = 'C:\Desktop\TelegramBots\theme-tg-bot-content\content.sqlite';
  SQL_TEMPLATES_PATH = '..\..\SQLTemplates\';

type
  TMainForm = class(TForm)
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    DataForm: TDataForm;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
    DBAccessUnit
  ;

procedure TMainForm.Button1Click(Sender: TObject);
begin
  DataForm.SetTableName('types');
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TMainForm.FormCreate(Sender: TObject);

begin
  ReportMemoryLeaksOnShutdown := true;

  TDBAccess.Init(DB_PATH, SQL_TEMPLATES_PATH);

  DataForm := TDataForm.Create(Self);
//  DataForm.SetTableName('types');
  DataForm.SetTableName('contents');
  DataForm.Show;

  Self.SendToBack;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  TDBAccess.UnInit;
end;

end.
