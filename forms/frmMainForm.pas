unit frmMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, StdCtrls,
  ComCtrls, ExtCtrls, uDatabase;

type

  { TszStartMain }

  TszStartMain = class(TForm)
    edtSearch: TEdit;
    lblWelcomeText: TLabel;
    lblWelcomeHeader: TLabel;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    mnuMain: TMainMenu;
    nbtPages: TNotebook;
    pnlLeft: TPanel;
    pnlToolbar: TPanel;
    pgWelcome: TPage;
    splSplitter: TSplitter;
    stbStatusBar: TStatusBar;
    lbxServers: TListBox;
    procedure actExitExecute(Sender: TObject);
    procedure edtSearchChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
  public
    Servers: IOrmServerEntries;
  end;

var
  szStartMain: TszStartMain;

implementation

{$R *.lfm}

uses uPlatform, uExamples;

{ TszStartMain }

procedure TszStartMain.FormCreate(Sender: TObject);
begin
  InitSQLite();
  UpdateMenuKeys(mnuMain.Items);
  QueryServersAll(Servers);
                 
  Servers := nil;  // initialize properly
  edtSearch.OnChange := @edtSearchChange;
  edtSearch.OnChange(edtSearch);
end;

procedure TszStartMain.FormDestroy(Sender: TObject);
begin
  lbxServers.Clear; // clear references to Servers IList<>
  Servers := nil;   // free the list itself

  FreeSQLite();
end;

procedure TszStartMain.actExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TszStartMain.edtSearchChange(Sender: TObject);
var
  Server: TOrmServerEntry;
  Result: boolean;
begin
  lbxServers.Items.Clear;  
  if edtSearch.Text = '' then
    Result := QueryServersAll(Servers)
  else
    Result := QueryServersByName(edtSearch.Text, Servers);

  if Result then
    for Server in Servers do
      lbxServers.Items.AddObject(Server.Name, Server);
end;

end.

