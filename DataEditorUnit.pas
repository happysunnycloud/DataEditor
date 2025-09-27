unit DataEditorUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls;

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
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
    DBAccessUnit
  , DataFormUnit
  ;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  DataForm: TDataForm;
begin
  ReportMemoryLeaksOnShutdown := true;

  TDBAccess.Init(DB_PATH, SQL_TEMPLATES_PATH);

  DataForm := TDataForm.Create(Self, 'contents');
  DataForm.Show;

  Self.SendToBack;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  TDBAccess.UnInit;
end;

end.
