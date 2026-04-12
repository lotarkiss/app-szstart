unit uDatabase;

interface

uses SysUtils, Classes, SQLite3Conn, SQLDB;

procedure InitSQLite(Connection: TSQLite3Connection; const DbName: string = 'sqlite.db');

procedure QueryServersByName(Query: TSQLQuery; const AFilter: string = '');
procedure QueryServersAll(Query: TSQLQuery);

implementation

uses uPlatform, Dialogs;

procedure QueryServersByName(Query: TSQLQuery; const AFilter: string = '');
const
  SqlQuery1: string = 
    'SELECT id, name FROM servers';
  SqlQuery2: string =
    'WHERE name LIKE ''%'' || :name || ''%''';
begin
  with Query do begin
    Close;
    if AFilter <> '' then begin
      SQL.Text := SqlQuery1 + ' ' + SqlQuery2 ;
      ParamByName('name').AsString := AFilter;
    end
    else
      SQL.Text := SqlQuery1;

    Open;
  end;
end;

procedure QueryServersAll(Query: TSQLQuery);
const
  SqlQuery: string =
    'SELECT * FROM servers s ' + LineEnding +
    'LEFT JOIN java_opts j ON j.server_id = s.id ' + LineEnding +
    'LEFT JOIN bedrock_opts b ON b.server_id = s.id ' + LineEnding +
    'LEFT JOIN rcon_opts r ON r.server_id = s.id;';
begin
  with Query do begin
    Close;
    SQL.Text := SqlQuery;
    Params.Clear;
    Open;
  end;
end;

procedure InitSQLite(Connection: TSQLite3Connection; const DbName: string = 'sqlite.db');
var
  Stmt: string;
  Stream: TStream;
begin
  with Connection do begin
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
    end
    else
      Open;
  end;
end;

end.
