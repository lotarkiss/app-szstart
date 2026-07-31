unit uDatabase;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  mormot.core.base,
  mormot.core.os,
  mormot.core.collections,
  mormot.orm.core,
  mormot.orm.sqlite3,
  mormot.rest.sqlite3,
  mormot.db.raw.sqlite3.static;

type


  // Schema

  { TOrmServerEntry }

  TOrmServerEntry = class(TOrm)
  private
    FArguments: RawUtf8;
    FDescription: RawUtf8;
    FJavaArgs: RawUtf8;
    FJavaJar: RawUtf8;
    FJavaJre: RawUtf8;
    FJavaXms: Integer;
    FJavaXmx: Integer;
    FKind: RawUtf8;
    FName: RawUtf8;
    FPath: RawUtf8;
    FProtected: boolean;
    FRconHost: RawUtf8;
    FRconPort: word;
    FRconUser: RawUtf8;
  published
    property Kind: RawUtf8 read FKind write FKind;
    property Path: RawUtf8 read FPath write FPath;
    property Name: RawUtf8 read FName write FName;
    property Description: RawUtf8 read FDescription write FDescription;
    property Protected: boolean read FProtected write FProtected;
    property Arguments: RawUtf8 read FArguments write FArguments;

    // Kind = 'java'
    property java_jrePath: RawUtf8 read FJavaJre write FJavaJre;
    property java_jarName: RawUtf8 read FJavaJar write FJavaJar;
    property java_jvmXMS: Integer read FJavaXms write FJavaXms;
    property java_jvmXMX: Integer read FJavaXmx write FJavaXmx;
    property java_jvmArgs: RawUtf8 read FJavaArgs write FJavaArgs;

    // Kind = 'bedrock'
    // - empty -

    // Kind = 'rcon'
    property rcon_remoteHost: RawUtf8 read FRconHost write FRconHost;
    property rcon_remotePort: word read FRconPort write FRconPort;
    property rcon_remoteUser: RawUtf8 read FRconUser write FRconUser;
    // ... just do not store password currently ...
  end;

  IOrmServerEntries = specialize IList<TOrmServerEntry>;

procedure InitSQLite(const DbName: string = 'sqlite.db');
procedure FreeSQLite();

function QueryServersByName(AFilter: string = ''; var Query): boolean;
function QueryServersAll(var Query): boolean;

var
  Model: TOrmModel;
  Server: TRestServerDB;

implementation

uses uPlatform, uExamples;

procedure InitSQLite(const DbName: string);
var
  DbPath: string;
  DryRun: boolean;
begin
  Model := TOrmModel.Create([TOrmServerEntry]);

  DbPath := GetAppDataPath(true) + DbName;
  DryRun := not FileExists(DbPath);

  Server := TRestServerDB.Create(Model, DbPath);
  Server.Server.CreateMissingTables();

  if DryRun then
    InitExamples();
end;

procedure FreeSQLite();
begin
  Server.Free;
  Model.Free;
end;

function QueryServersByName(AFilter: string; var Query): boolean;
begin
  AFilter := '%' + AFilter + '%';
  Result  := Server.Orm.RetrieveIList(TOrmServerEntry, Query, 'name LIKE ?', [AFilter]);
end;

function QueryServersAll(var Query): boolean;
begin
  Result := Server.Orm.RetrieveIList(TOrmServerEntry, Query);
end;

end.

