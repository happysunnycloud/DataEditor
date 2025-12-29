unit DBAccessClassUnit;

interface

uses
    System.SyncObjs
  , DBToolsUnit
  , SQLTemplatesUnit
  , ParamsExtUnit
  ;

const
  NULL_ID = 0;
  TIME_OUT_SECONDS = 40;
  NULL_DATETIME = 0;

type
  TDBAResultCode = (rcFault = -1, rcOk = 0, rcFolderIsNotEmpty = 1); //DBA = D - data, B - base,  A - access
  TInOutParamsFuncRef = function(const AInParams: TParamsExt; const AOutParams: TParamsExt): TDBAResultCode of object;

  TDBAccessClass = class
  strict private
    class var FCriticalSection: TCriticalSection;
    class var FDBFileName: String;
    class var FSQLTemplates: TSQLTemplates;
  protected
    class property SQLTemplates: TSQLTemplates read FSQLTemplates;
    class property DBFileName: String read FDBFileName;
  public
    class function DBAParamsFunc(
      const AParamsFuncRef: TInOutParamsFuncRef;
      const AInParams: TParamsExt;
      const AOutParams: TParamsExt): TDBAResultCode;

    class procedure Init(const ADBFileName: String; const ATemplatesDir: String);
    class procedure UnInit;
  end;

implementation

uses
    System.SysUtils
  , System.Generics.Collections
  , FireDAC.Stan.Error
  , FireDAC.Phys.SQLiteWrapper
  , DBExceptionContainerUnit
  ;

class function TDBAccessClass.DBAParamsFunc(
  const AParamsFuncRef: TInOutParamsFuncRef;
  const AInParams: TParamsExt;
  const AOutParams: TParamsExt): TDBAResultCode;
const
  METHOD = 'TDBAccess.DBAParamsFunc';
var
  ParamsFuncRef: TInOutParamsFuncRef absolute AParamsFuncRef;
  InParams: TParamsExt;
  OutParams: TParamsExt;

  FDCommandExceptionKind: TFDCommandExceptionKind;
  DoExit: Boolean;
  TimeOutCount: Byte;
  MessageString: String;
begin
  FCriticalSection.Enter;
  try
    Result := rcFault;

    InParams := TParamsExt.Create;
    OutParams := TParamsExt.Create;
    try
      InParams.CopyFrom(AInParams);

      TimeOutCount := TIME_OUT_SECONDS;

      DoExit := false;
      while not DoExit do
      begin
        try
          Result := ParamsFuncRef(InParams, OutParams);

          if Assigned(AOutParams) then
          begin
            AOutParams.Clear;
            AOutParams.CopyFrom(OutParams);
          end;

          DoExit := true;
        except
          on e: TDBExceptionContainer do
          begin
            MessageString :=
              Concat(METHOD, ': ', e._MethodName, ': ', e.ExceptionClass.ClassName, ': ', e.Message);
            if e.ExceptionClass = ESQLiteNativeException then
            begin
              FDCommandExceptionKind := e.Kind;
              MessageString := Concat(MessageString, ': ', FDCommandExceptionKind.ToString);
              if FDCommandExceptionKind = ekRecordLocked then
              begin
                Dec(TimeOutCount);

                if TimeOutCount = 0 then
                begin
                  raise Exception.Create(MessageString);
                end;

                Sleep(1000);
              end;
            end;
            raise;
            //raise Exception.Create(MessageString);
          end;
          on e: Exception do
          begin
            MessageString := Concat(METHOD, ': ', e.ClassName, ': ', e.Message);
            raise Exception.Create(MessageString);
          end
          else
          begin
            MessageString := Concat(METHOD, ': ', 'Unknown exception');
            raise Exception.Create(MessageString);
          end;
        end;
      end;
    finally
      FreeAndNil(InParams);
      FreeAndNil(OutParams);
    end;
  finally
    FCriticalSection.Leave;
  end;
end;

class procedure TDBAccessClass.Init(const ADBFileName: String; const ATemplatesDir: String);
begin
  FCriticalSection := TCriticalSection.Create;

  FDBFileName := ADBFileName;

  FSQLTemplates := TSQLTemplates.Create(ATemplatesDir);
end;

class procedure TDBAccessClass.UnInit;
begin
  FreeAndNil(FCriticalSection);
  FreeAndNil(FSQLTemplates);
end;


end.

