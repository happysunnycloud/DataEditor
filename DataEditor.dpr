program DataEditor;

uses
  System.StartUpCopy,
  FMX.Forms,
  DataEditorUnit in 'DataEditorUnit.pas' {MainForm},
  DataFormUnit in 'DataFormUnit.pas' {DataForm},
  DBAccessUnit in 'DBAccessUnit.pas',
  SQLTemplatesUnit in '..\DevelopmentsCollection\SQL\SQLTemplatesUnit.pas',
  ParamsExtUnit in '..\DevelopmentsCollection\ParamsExtUnit.pas',
  FileToolsUnit in '..\DevelopmentsCollection\FileToolsUnit.pas',
  DBExceptionContainerUnit in 'DBExceptionContainerUnit.pas',
  DBToolsUnit in '..\DevelopmentsCollection\SQLite\DBToolsUnit.pas',
  DBFieldUnit in 'DBFieldUnit.pas',
  DBFieldControlUnit in 'DBFieldControlUnit.pas',
  ObjectRegistryUnit in '..\DevelopmentsCollection\ObjectRegistryUnit.pas',
  DebugUnit in '..\DevelopmentsCollection\DebugUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
