unit frmMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ActnList,
  StdCtrls, SQLite3Conn, SQLDB, uPlatform;

type

  { TszStartMain }

  TszStartMain = class(TForm)
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    mnuMain: TMainMenu;
    dbcSQLite: TSQLite3Connection;
    dbtTransact: TSQLTransaction;
    procedure actExitExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public
    procedure InitSQLite(const DbName: string = 'sqlite.db');
  end;

var
  szStartMain: TszStartMain;

implementation

{$R *.lfm}

{ TszStartMain }

procedure TszStartMain.FormCreate(Sender: TObject);
begin                            
   InitSQLite();
   UpdateMenuKeys(mnuMain.Items);
end;

procedure TszStartMain.InitSQLite(const DbName: string);
var
  Stmt: string;
  Stream: TStream;
begin
  with dbcSQLite do begin
    Close();
    DatabaseName := GetAppDataPath(true) + DbName;

    if not FileExists(DatabaseName) then begin
      Open;
      Transaction.Active := true;

      with TStringList.Create do
        try
          Stream := TResourceStream.Create(hInstance, 'INITDB-SQLITE', RT_RCDATA);
          try
            LoadFromStream(Stream, TEncoding.UTF8);
          finally
            Stream.Free;
          end;

          for Stmt in Text.Split(';') do
            if Trim(Stmt) <> '' then
              ExecuteDirect(Stmt);
        finally
          Free;
        end;

      Transaction.Commit;
    end;
  end;
end;

procedure TszStartMain.actExitExecute(Sender: TObject);
begin
  Close;
end;

end.

