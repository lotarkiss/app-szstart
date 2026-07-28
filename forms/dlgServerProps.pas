unit dlgServerProps;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, uDatabase;

type

  { TdlgServerProperties }

  TdlgServerProperties = class(TForm)
    btnCancel: TButton;
    btnOK: TButton;
    edName: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    lbName: TLabel;
    lbDescription: TLabel;
    lbPages: TListBox;
    mmDescription: TMemo;
    pgGeneral: TPage;
    pgNotebook: TNotebook;
    pnBottom: TPanel;
    spSplitter: TSplitter;
    procedure lbPagesClick(Sender: TObject);
  public
    procedure Load(AServer: TOrmServerEntry);
    procedure Save(AServer: TOrmServerEntry);
  end;

var
  dlgServerProperties: TdlgServerProperties;

implementation

uses Math;

resourcestring
  dlgPropsCaption = '%s properties';

{$R *.lfm}

{ TdlgServerProperties }

procedure TdlgServerProperties.lbPagesClick(Sender: TObject);
begin
  if lbPages.ItemIndex = -1 then
    pgNotebook.PageIndex := -1
  else
    pgNotebook.PageIndex := (lbPages.Items.Objects[lbPages.ItemIndex] as TPage).PageIndex;
end;

procedure TdlgServerProperties.Load(AServer: TOrmServerEntry);
var
  I: integer;
begin
  // Dialog caption
  Caption := format(dlgPropsCaption, [AServer.Name]);

  // Load general, and server specific pages into lbPages
  lbPages.Clear;
  for I := 0 to pgNotebook.PageCount - 1 do
    if (pgNotebook.Page[I].HelpKeyword = '') or
       (pgNotebook.Page[I].HelpKeyword = AServer.Kind) then
      lbPages.Items.AddObject(pgNotebook.Page[I].Hint, pgNotebook.Page[I]);
  lbPages.ItemIndex := Min(0, lbPages.Count - 1);
  lbPagesClick(lbPages); // navigate to the first page

  // General
  edName.Text := AServer.Name;
  mmDescription.Text := AServer.Description;
end;

procedure TdlgServerProperties.Save(AServer: TOrmServerEntry);
begin
  // General
  AServer.Name := edName.Text;
  AServer.Description := mmDescription.Text;

  Server.Orm.Update(AServer);
end;

end.

