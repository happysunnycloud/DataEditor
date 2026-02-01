program DataEditor;

uses
  System.StartUpCopy,
  FMX.Forms,
  DataEditorUnit in 'DataEditorUnit.pas' {MainForm},
  DataFormUnit in 'DataFormUnit.pas' {DataForm},
  DBAccessUnit in 'DBAccessUnit.pas',
  ParamsExtUnit in '..\DevelopmentsCollection\ParamsExt\ParamsExtUnit.pas',
  ParamsExtFileUnit in '..\DevelopmentsCollection\ParamsExt\ParamsExtFileUnit.pas',
  FileToolsUnit in '..\DevelopmentsCollection\FileToolsUnit.pas',
  DBToolsUnit in '..\DevelopmentsCollection\SQLite\DBToolsUnit.pas',
  DBFieldControlUnit in 'DBFieldControlUnit.pas',
  ObjectRegistryUnit in '..\DevelopmentsCollection\ObjectRegistryUnit.pas',
  DebugUnit in '..\DevelopmentsCollection\DebugUnit.pas',
  DBRowUnit in 'DBRowUnit.pas',
  DataConnectorUnit in 'DataConnectorUnit.pas',
  FMX.DialogUnit in 'FMX.DialogUnit.pas',
  FMX.FormLayoutXMLUnit in 'FMX.FormLayoutXMLUnit.pas',
  ConfigUnit in 'ConfigUnit.pas',
  CommonUnit in 'CommonUnit.pas',
  StringToolsUnit in '..\DevelopmentsCollection\StringToolsUnit.pas',
  SQLTemplatesUnit in '..\DevelopmentsCollection\SQL\SQLTemplatesUnit.pas',
  FilePackerUnit in '..\DevelopmentsCollection\FilePacker\FilePackerUnit.pas',
  TextExtractorUnit in '..\DevelopmentsCollection\FilePacker\TextExtractorUnit.pas',
  DBExceptionContainerUnit in '..\DevelopmentsCollection\SQL\DBExceptionContainerUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
