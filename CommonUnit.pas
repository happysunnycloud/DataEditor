unit CommonUnit;

interface

uses
    FMX.Layouts
  ;

procedure ClearScrollBoxContent(const AScrollBox: TScrollBox);

implementation

uses
    System.SysUtils
  , FMX.Controls
  , FMX.Memo
  ;

procedure ClearScrollBoxContent(const AScrollBox: TScrollBox);
var
  i: Integer;
  Control: TControl;
begin
  AScrollBox.BeginUpdate;
  AScrollBox.ShowScrollBars := false;
  try
    i := AScrollBox.Content.ControlsCount;
    while i > 0 do
    begin
      Dec(i);

      Control := AScrollBox.Content.Controls[i];

      if Control is TMemo then
        TMemo(Control).ShowScrollBars := false;

      FreeAndNil(Control);
    end;

    AScrollBox.Content.Controls.Clear;
  finally
    AScrollBox.EndUpdate;
    AScrollBox.RecalcSize;
    AScrollBox.ShowScrollBars := true;
  end;
end;


end.
