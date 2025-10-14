unit FMX.FormLayoutXMLUnit;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Xml.XMLDoc, Xml.XMLIntf, System.IOUtils,
  FMX.Forms, FMX.Types, FMX.Controls, FMX.Edit, FMX.Memo, FMX.StdCtrls, FMX.ListBox;

type
  TPositionInfo = record
    Top: Single;
    Left: Single;
    Width: Single;
    Height: Single;
  end;

  TLayoutHelper = class
  strict private
    class var FFileName: String;
//    class procedure OnApplicationIdle(Sender: TObject; var Done: Boolean);
    class function GetLayoutFile: string;
    class procedure SaveControlState(AParent: TFmxObject; ANode: IXMLNode);
    class procedure LoadControlState(AParent: TFmxObject; ANode: IXMLNode);
    class function FindChildByName(AParent: TFmxObject; const AName: string): TFmxObject;
  public
//    class procedure InitAuto;
    class procedure SaveFormLayout(AForm: TForm);
    class procedure LoadFormLayout(AForm: TForm);
    class procedure DeleteFormLayout(const AFormName: string);
    class function GetFormsList: TArray<string>;
//    class procedure SaveAllForms;
//    class procedure LoadAllForms;
    class procedure Init(const AFileName: String);
  end;

implementation

uses
    System.UITypes
  ;

var
  FInitialized: Boolean = False;

{ TLayoutHelper }

class function TLayoutHelper.GetLayoutFile: string;
begin
  Result := FFileName; //TPath.Combine(TPath.GetDocumentsPath, FFileName);
end;

//class procedure TLayoutHelper.OnApplicationIdle(Sender: TObject; var Done: Boolean);
//begin
//  TLayoutHelper.LoadAllForms;
//  Application.OnIdle := nil; //      ,
//end;

//class procedure TLayoutHelper.InitAuto;
//begin
//  if FInitialized then
//    Exit;
//
//  FInitialized := True;
//
//  Application.OnIdle := OnApplicationIdle;
//end;

class procedure TLayoutHelper.SaveControlState(AParent: TFmxObject; ANode: IXMLNode);
var
  Obj: TFmxObject;
  ChildNode: IXMLNode;
  Control: TControl;
  AnchorsStr: string;
begin
  if not Assigned(AParent) then
    Exit;

  for Obj in AParent.Children do
  begin
    if not (Obj is TControl) then
      Continue;

    Control := TControl(Obj);
    if Control.Name = '' then
      Continue;

    ChildNode := ANode.AddChild('Control');
    ChildNode.Attributes['Name'] := Control.Name;
    ChildNode.Attributes['Class'] := Control.ClassName;
    ChildNode.Attributes['X'] := FloatToStr(Control.Position.X);
    ChildNode.Attributes['Y'] := FloatToStr(Control.Position.Y);
    ChildNode.Attributes['Width'] := FloatToStr(Control.Width);
    ChildNode.Attributes['Height'] := FloatToStr(Control.Height);
    ChildNode.Attributes['Align'] := Ord(Control.Align);

    AnchorsStr := '';
    if TAnchorKind.akLeft in Control.Anchors then AnchorsStr := AnchorsStr + 'L';
    if TAnchorKind.akTop in Control.Anchors then AnchorsStr := AnchorsStr + 'T';
    if TAnchorKind.akRight in Control.Anchors then AnchorsStr := AnchorsStr + 'R';
    if TAnchorKind.akBottom in Control.Anchors then AnchorsStr := AnchorsStr + 'B';
    ChildNode.Attributes['Anchors'] := AnchorsStr;
    if Obj.ChildrenCount > 0 then
      SaveControlState(Obj, ChildNode);
  end;
end;

class procedure TLayoutHelper.LoadControlState(AParent: TFmxObject; ANode: IXMLNode);
var
  I: Integer;
  ChildNode: IXMLNode;
  Obj: TFmxObject;
  Name: string;
  Control: TControl;
  AnchorsStr: string;
  Anchors: TAnchors;
begin
  if (not Assigned(AParent)) or (not Assigned(ANode)) then
    Exit;
  for I := 0 to ANode.ChildNodes.Count - 1 do
  begin
    ChildNode := ANode.ChildNodes[I];
    if ChildNode.NodeName <> 'Control' then
      Continue;
    Name := ChildNode.Attributes['Name'];
    Obj := FindChildByName(AParent, Name);

    if not Assigned(Obj) then
      Continue;

    if Obj is TControl then
    begin
      Control := TControl(Obj);
      if ChildNode.HasAttribute('X') then
        Control.Position.X := StrToFloatDef(ChildNode.Attributes['X'], Control.Position.X);
      if ChildNode.HasAttribute('Y') then
        Control.Position.Y := StrToFloatDef(ChildNode.Attributes['Y'], Control.Position.Y);
      if ChildNode.HasAttribute('Width') then
        Control.Width := StrToFloatDef(ChildNode.Attributes['Width'], Control.Width);
      if ChildNode.HasAttribute('Height') then
        Control.Height := StrToFloatDef(ChildNode.Attributes['Height'], Control.Height);
      if ChildNode.HasAttribute('Align') then
        Control.Align := TAlignLayout(StrToIntDef(ChildNode.Attributes['Align'], Ord(Control.Align)));
      if ChildNode.HasAttribute('Anchors') then
      begin
        AnchorsStr := ChildNode.Attributes['Anchors'];
        Anchors := Control.Anchors;
        Control.Anchors := [];
        if Pos('L', AnchorsStr) > 0 then Include(Anchors, TAnchorKind.akLeft);
        if Pos('T', AnchorsStr) > 0 then Include(Anchors, TAnchorKind.akTop);
        if Pos('R', AnchorsStr) > 0 then Include(Anchors, TAnchorKind.akRight);
        if Pos('B', AnchorsStr) > 0 then Include(Anchors, TAnchorKind.akBottom);
        Control.Anchors := Anchors;
      end;
    end;
    if ChildNode.HasChildNodes then
      LoadControlState(Obj, ChildNode);
  end;
end;

class procedure TLayoutHelper.SaveFormLayout(AForm: TForm);
var
  XmlDoc: IXMLDocument;
  RootNode, FormNode, ControlsNode: IXMLNode;
  FileName: string;
  I: Integer;
  Found: Boolean;
begin
  if not Assigned(AForm) then
    Exit;

  FileName := GetLayoutFile;
  XmlDoc := TXMLDocument.Create(nil);
  XmlDoc.Options := [doNodeAutoIndent];
  XmlDoc.Active := True;
  XmlDoc.Version := '1.0';
  XmlDoc.Encoding := 'utf-8';

  if FileExists(FileName) then
    XmlDoc.LoadFromFile(FileName);

  if not Assigned(XmlDoc.DocumentElement) then
    XmlDoc.AddChild('Layout');

  RootNode := XmlDoc.DocumentElement;

  Found := False;
  for I := 0 to RootNode.ChildNodes.Count - 1 do
  begin
    if RootNode.ChildNodes[I].Attributes['Name'] = AForm.Name then
    begin
      FormNode := RootNode.ChildNodes[I];
      Found := True;
      Break;
    end;
  end;

  if not Found then
    FormNode := RootNode.AddChild('Form');

  FormNode.Attributes['Name'] := AForm.Name;
  FormNode.Attributes['Top'] := AForm.Top;
  FormNode.Attributes['Left'] := AForm.Left;
  FormNode.Attributes['Width'] := AForm.Width;
  FormNode.Attributes['Height'] := AForm.Height;

  for I := FormNode.ChildNodes.Count - 1 downto 0 do
    FormNode.ChildNodes.Delete(I);

  ControlsNode := FormNode.AddChild('Controls');
  SaveControlState(AForm, ControlsNode);

  XmlDoc.SaveToFile(FileName);
end;

class procedure TLayoutHelper.LoadFormLayout(AForm: TForm);
var
  XmlDoc: IXMLDocument;
  RootNode, FormNode, ControlsNode: IXMLNode;
  I: Integer;
begin
  if (not Assigned(AForm)) or (not FileExists(GetLayoutFile)) then
    Exit;

  XmlDoc := TXMLDocument.Create(nil);
  XmlDoc.LoadFromFile(GetLayoutFile);
  XmlDoc.Active := True;
  RootNode := XmlDoc.DocumentElement;
  if not Assigned(RootNode) then
    Exit;

  for I := 0 to RootNode.ChildNodes.Count - 1 do
  begin
    FormNode := RootNode.ChildNodes[I];
    if (FormNode.NodeName = 'Form') and
       (FormNode.Attributes['Name'] = AForm.Name) then
    begin
      AForm.Left := StrToIntDef(FormNode.Attributes['Left'], AForm.Left);
      AForm.Top := StrToIntDef(FormNode.Attributes['Top'], AForm.Top);
      AForm.Width := StrToIntDef(FormNode.Attributes['Width'], AForm.Width);
      AForm.Height := StrToIntDef(FormNode.Attributes['Height'], AForm.Height);

      ControlsNode := FormNode.ChildNodes.FindNode('Controls');
      if ControlsNode <> nil then
        LoadControlState(AForm, ControlsNode);
      Exit;
    end;
  end;
end;

class procedure TLayoutHelper.DeleteFormLayout(const AFormName: string);
var
  XmlDoc: IXMLDocument;
  RootNode, FormNode: IXMLNode;
  I: Integer;
  FileName: string;
begin
  FileName := GetLayoutFile;
  if not FileExists(FileName) then
    Exit;

  XmlDoc := TXMLDocument.Create(nil);
  XmlDoc.LoadFromFile(FileName);
  XmlDoc.Active := True;

  RootNode := XmlDoc.DocumentElement;
  if not Assigned(RootNode) then
    Exit;

  //
  for I := RootNode.ChildNodes.Count - 1 downto 0 do
  begin
    FormNode := RootNode.ChildNodes[I];
    if (FormNode.NodeName = 'Form') and
       (FormNode.Attributes['Name'] = AFormName) then
    begin
      RootNode.ChildNodes.Delete(I);
      Break;
    end;
  end;

  XmlDoc.SaveToFile(FileName);
end;

class procedure TLayoutHelper.Init(const AFileName: String);
begin
  FFileName := AFileName;
end;

class function TLayoutHelper.FindChildByName(AParent: TFmxObject; const AName: string): TFmxObject;
var
  I: Integer;
  Child, Found: TFmxObject;
begin
  Result := nil;
  if not Assigned(AParent) or (AName = '') then
    Exit;
  // Сначала проверяем сам объект
  if SameText(AParent.Name, AName) then
  begin
    Result := AParent;
    Exit;
  end;
  // Перебираем дочерние элементы
  for I := 0 to AParent.ChildrenCount - 1 do
  begin
    Child := AParent.Children[I];
    if SameText(Child.Name, AName) then
    begin
      Result := Child;
      Exit;
    end;
    // Рекурсивный спуск
    Found := FindChildByName(Child, AName);
    if Assigned(Found) then
    begin
      Result := Found;
      Exit;
    end;
  end;
end;

class function TLayoutHelper.GetFormsList: TArray<string>;
var
  XmlDoc: IXMLDocument;
  RootNode, FormNode: IXMLNode;
  I: Integer;
  FileName: string;
  FormNames: TList<string>;
begin
  Result := [];
  FileName := GetLayoutFile;
  if not FileExists(FileName) then
    Exit;
  XmlDoc := TXMLDocument.Create(nil);
  XmlDoc.LoadFromFile(FileName);
  XmlDoc.Active := True;
  RootNode := XmlDoc.DocumentElement;
  if not Assigned(RootNode) then
    Exit;
  FormNames := TList<string>.Create;
  try
    for I := 0 to RootNode.ChildNodes.Count - 1 do
    begin
      FormNode := RootNode.ChildNodes[I];
      if (FormNode.NodeName = 'Form') and FormNode.HasAttribute('Name') then
        FormNames.Add(FormNode.Attributes['Name']);
    end;
    Result := FormNames.ToArray;
  finally
    FormNames.Free;
  end;
end;

//class procedure TLayoutHelper.SaveAllForms;
//var
//  I: Integer;
//  Form: TForm;
//begin
//  for I := 0 to Screen.FormCount - 1 do
//  begin
//    Form := TForm(Screen.Forms[I]);
//    SaveFormLayout(Form);
//  end;
//end;
//
//class procedure TLayoutHelper.LoadAllForms;
//var
//  I: Integer;
//  Form: TForm;
//begin
//  for I := 0 to Screen.FormCount - 1 do
//  begin
//    Form := TForm(Screen.Forms[I]);
//    LoadFormLayout(Form);
//  end;
//end;

//initialization
//  TLayoutHelper.InitAuto;


end.

