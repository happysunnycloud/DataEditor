program DataEditor;

uses
  System.StartUpCopy,
  FMX.Forms,
  DataEditorUnit in 'DataEditorUnit.pas' {MainForm},
  DataFormUnit in 'DataFormUnit.pas' {DataForm},
  DBAccessUnit in 'DBAccessUnit.pas',
  SQLTemplatesUnit in 'C:\Desktop\DevelopmentsCollection\SQL\SQLTemplatesUnit.pas',
  ParamsExtUnit in 'C:\Desktop\DevelopmentsCollection\ParamsExtUnit.pas',
  FileToolsUnit in 'C:\Desktop\DevelopmentsCollection\FileToolsUnit.pas',
  DBExceptionContainerUnit in 'DBExceptionContainerUnit.pas',
  DBToolsUnit in 'C:\Desktop\DevelopmentsCollection\SQLite\DBToolsUnit.pas',
  DBFieldUnit in 'DBFieldUnit.pas',
  DBFieldControlUnit in 'DBFieldControlUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
