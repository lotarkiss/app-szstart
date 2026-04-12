unit uDatabase;

interface

uses SysUtils, Classes, SQLite3Conn, SQLDB;

procedure InitSQLite(Connection: TSQLite3Connection; const DbName: string = 'sqlite.db');

procedure QueryServers(Query: TSQLQuery; const Filter: string = '');

implementation

uses uPlatform;

procedure QueryServers(Query: TSQLQuery; const Filter: string = '');
const
  SqlQuery: string =
    'SELECT * FROM servers s ' + LineEnding +
    'LEFT JOIN java_opts j ON j.server_id = s.id ' + LineEnding +
    'LEFT JOIN bedrock_opts b ON b.server_id = s.id ' + LineEnding +
    'LEFT JOIN rcon_opts r ON r.server_id = s.id' + LineEnding +
    'WHERE (:name IS NULL OR s.name LIKE ''%'' || :name || ''%'');';
begin
  with Query do begin
    Close;
    SQL.Text := SqlQuery;
    if Filter <> '' then
      ParamByName('name').AsString := Filter
    else
      ParamByName('name').Clear;

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