unit FMX.DialogUnit;

interface

uses
  System.SysUtils, System.UITypes, FMX.DialogService;

type
  TDialog = class
  public
    class procedure ShowMessage(const AText: string);
    class procedure Confirm(const AText: string; const AOnResult: TProc<Boolean>);
    class procedure Ask(const AText: string; const AButtons: TMsgDlgButtons;
      const AOnResult: TProc<TModalResult>;
      const AType: TMsgDlgType = TMsgDlgType.mtConfirmation;
      const ADefault: TMsgDlgBtn = TMsgDlgBtn.mbOK);
  end;

implementation

{ TDialog }

class procedure TDialog.ShowMessage(const AText: string);
begin
  TDialogService.ShowMessage(AText);
end;

class procedure TDialog.Confirm(const AText: string; const AOnResult: TProc<Boolean>);
begin
  TDialogService.MessageDialog(
    AText,
    TMsgDlgType.mtConfirmation,
    [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
    TMsgDlgBtn.mbNo,
    0,
    procedure(const AResult: TModalResult)
    begin
      if Assigned(AOnResult) then
        AOnResult(AResult = mrYes);
    end
  );
end;

class procedure TDialog.Ask(const AText: string; const AButtons: TMsgDlgButtons;
  const AOnResult: TProc<TModalResult>; const AType: TMsgDlgType;
  const ADefault: TMsgDlgBtn);
begin
  TDialogService.MessageDialog(
    AText,
    AType,
    AButtons,
    ADefault,
    0,
    procedure(const AResult: TModalResult)
    begin
      if Assigned(AOnResult) then
        AOnResult(AResult);
    end
  );
end;

end.
