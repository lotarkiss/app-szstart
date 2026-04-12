unit frmMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, StdCtrls,
  ComCtrls, ExtCtrls, SQLite3Conn, SQLDB, uServerClass;

type

  { TszStartMain }

  TszStartMain = class(TForm)
    edtSearch: TEdit;
    lblWelcomeText: TLabel;
    lblWelcomeHeader: TLabel;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    mnuMain: TMainMenu;
    dbcSQLite: TSQLite3Connection;
    dbtTransact: TSQLTransaction;
    nbtPages: TNotebook;
    pnlLeft: TPanel;
    pnlToolbar: TPanel;
    pgWelcome: TPage;
    splSplitter: TSplitter;
    dbqQuery: TSQLQuery;
    stbStatusBar: TStatusBar;
    lbxServers: TListBox;
    procedure actExitExecute(Sender: TObject);
    procedure edtSearchChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private

  public
    Servers: TServerManager;
  end;

var
  szStartMain: TszStartMain;

implementation

{$R *.lfm}

uses uPlatform, uDatabase;

{ TszStartMain }

procedure TszStartMain.FormCreate(Sender: TObject);
begin
   Servers := TServerManager.Create;

   InitSQLite(dbcSQLite);
   UpdateMenuKeys(mnuMain.Items);
   Servers.QueryServers(dbqQuery);

   edtSearch.OnChange := @edtSearchChange;
   edtSearch.OnChange(edtSearch);
end;

procedure TszStartMain.FormDestroy(Sender: TObject);
begin
  Servers.Free;
end;

procedure TszStartMain.actExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TszStartMain.edtSearchChange(Sender: TObject);
var
  AId: string;
begin
  lbxServers.Items.Clear;  
  uDatabase.QueryServersByName(dbqQuery, edtSearch.Text);
  with dbqQuery do
    try
      while not Eof do begin
        AId := FieldByName('name').AsString;
        lbxServers.Items.AddObject(AId, Servers.FindServerById(AId));

        Next;
      end;
    finally
      Close;
    end;
end;

end.

