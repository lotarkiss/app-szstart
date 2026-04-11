unit frmMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ActnList,
  StdCtrls;

type

  { TszStartMain }

  TszStartMain = class(TForm)
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    mnuMain: TMainMenu;
    procedure actExitExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  szStartMain: TszStartMain;

implementation

{$R *.lfm}

{ TszStartMain }

procedure UpdateMenuKeys(const AMenu: TMenuItem);
var
  I: integer;
begin
  {$IFDEF DARWIN}
  AMenu.ShortCut := AMenu.ShortCutKey2;
  {$ENDIF}
  AMenu.ShortCutKey2 := 0;

  for I := 0 to AMenu.Count - 1 do
    UpdateMenuKeys(AMenu.Items[I]);
end;

procedure TszStartMain.FormCreate(Sender: TObject);
begin
   UpdateMenuKeys(mnuMain.Items);
end;

procedure TszStartMain.actExitExecute(Sender: TObject);
begin
  Close;
end;

end.

