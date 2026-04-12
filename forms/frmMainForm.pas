unit frmMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, StdCtrls,
  ComCtrls, ExtCtrls, SQLite3Conn, SQLDB;

type

  { TszStartMain }

  TszStartMain = class(TForm)
    lblWelcomeText: TLabel;
    lblWelcomeHeader: TLabel;
    lbxServers: TListBox;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    mnuMain: TMainMenu;
    dbcSQLite: TSQLite3Connection;
    dbtTransact: TSQLTransaction;
    nbtPages: TNotebook;
    pnlToolbar: TPanel;
    pgWelcome: TPage;
    splSplitter: TSplitter;
    dbqQuery: TSQLQuery;
    stbStatusBar: TStatusBar;
    procedure actExitExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public
  end;

var
  szStartMain: TszStartMain;

implementation

{$R *.lfm}

uses uPlatform, uDatabase;

{ TszStartMain }

procedure TszStartMain.FormCreate(Sender: TObject);
begin                            
   InitSQLite(dbcSQLite);
   UpdateMenuKeys(mnuMain.Items);

   QueryServers(dbqQuery);
   with dbqQuery do begin
     while not Eof do begin
       lbxServers.Items.Add(FieldByName('id').AsString);
       Next;
     end;
     Close;
   end;
end;

procedure TszStartMain.actExitExecute(Sender: TObject);
begin
  Close;
end;

end.

