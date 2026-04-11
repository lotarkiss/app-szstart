unit frmMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ActnList;

type

  { TszStartMain }

  TszStartMain = class(TForm)
    aclActions: TActionList;
    actExit: TAction;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    mnuMain: TMainMenu;
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  szStartMain: TszStartMain;

implementation

{$R *.lfm}

{ TszStartMain }

procedure TszStartMain.FormCreate(Sender: TObject);
var
  I: integer;
begin
  for I := 0 to aclActions.ActionCount - 1 do
    if aclActions[I] is TAction then
      with aclActions[I] as TAction do
        case SecondaryShortCuts.Count of
          1: ShortCut := SecondaryShortCuts.ShortCuts[0];
          2: ShortCut := SecondaryShortCuts.ShortCuts[{$IFDEF DARWIN} 1 {$ELSE} 0 {$ENDIF}];
        end;
end;

end.

