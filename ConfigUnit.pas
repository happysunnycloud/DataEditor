unit ConfigUnit;

interface

uses
    FMX.Forms
  ;

type
  TConfig = class
  strict private
    class var FFileName: String;
    class var FForm: TForm;
//    class var FMainFormTop: Integer;
//    class var FMainFormLeft: Integer;
//    class var FMainFormWidth: Integer;
//    class var FMainFormHeight: Integer;
    class var FDBPath: String;
  public
    class procedure Init(const AForm: TForm; const AFileName: String);
    class procedure SaveConfig;
    class procedure LoadConfig;

    class property DBPath: String read FDBPath write FDBPath;
  end;

implementation

uses
    System.SysUtils
  , System.IOUtils
  , Xml.XMLDoc
  , Xml.XMLIntf
  ;

class procedure TConfig.Init(const AForm: TForm; const AFileName: String);
begin
  FForm := AForm;
  FFileName := AFileName;
end;

class procedure TConfig.SaveConfig;
var
  XmlDoc: IXMLDocument;
  RootNode, MainFormNode, DBNode: IXMLNode;
  FileName: string;
begin
  FileName := FFileName;
  XmlDoc := TXMLDocument.Create(nil);
  XmlDoc.Options := [doNodeAutoIndent];
  XmlDoc.Active := True;
  XmlDoc.Version := '1.0';
  XmlDoc.Encoding := 'utf-8';

  if FileExists(FileName) then
    XmlDoc.LoadFromFile(FileName);

  if not Assigned(XmlDoc.DocumentElement) then
    XmlDoc.AddChild('Config');

  RootNode := XmlDoc.DocumentElement;

  MainFormNode := RootNode.ChildNodes.FindNode('MainForm');
  if not Assigned(MainFormNode) then
    MainFormNode := RootNode.AddChild('MainForm');

  MainFormNode.Attributes['Top'] := FForm.Top;
  MainFormNode.Attributes['Left'] := FForm.Left;
  MainFormNode.Attributes['Width'] := FForm.Width;
  MainFormNode.Attributes['Height'] := FForm.Height;

  DBNode := RootNode.ChildNodes.FindNode('DB');
  if not Assigned(DBNode) then
    DBNode := RootNode.AddChild('DB');

  DBNode.Attributes['Path'] := FDBPath;

  XmlDoc.SaveToFile(FileName);
end;

class procedure TConfig.LoadConfig;
var
  XmlDoc: IXMLDocument;
  RootNode, MainFormNode, DBNode: IXMLNode;
begin
  if not FileExists(FFileName) then
    Exit;

  XmlDoc := TXMLDocument.Create(nil);
  XmlDoc.LoadFromFile(FFileName);
  XmlDoc.Active := True;
  RootNode := XmlDoc.DocumentElement;
  if not Assigned(RootNode) then
    Exit;

  MainFormNode := RootNode.ChildNodes.FindNode('MainForm');
  if not Assigned(MainFormNode) then
    Exit;

  FForm.Left := StrToIntDef(MainFormNode.Attributes['Left'], FForm.Left);
  FForm.Top := StrToIntDef(MainFormNode.Attributes['Top'], FForm.Top);
  FForm.Width := StrToIntDef(MainFormNode.Attributes['Width'], FForm.Width);
  FForm.Height := StrToIntDef(MainFormNode.Attributes['Height'], FForm.Height);

  DBNode := RootNode.ChildNodes.FindNode('DB');
  if not Assigned(DBNode) then
    Exit;

  FDBPath := DBNode.Attributes['Path'];
end;

end.
