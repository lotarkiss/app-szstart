unit uServer;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uDatabase, Generics.Collections;

type

  { TCustomServer }

  TCustomServer = class abstract
  private
    FLog: TStrings;
    FName: string;
    FServer: TOrmServerEntry;
    FUUID: string;
  protected
    procedure Prepare(); virtual;
  public
    constructor Create(AServer: TOrmServerEntry); virtual; reintroduce;

    procedure Start(); virtual;
    procedure Run(); virtual; abstract;
    procedure Stop(); virtual;
    procedure Kill(const AExitCode: integer = 1); virtual; abstract;
    procedure Send(ACommand: string); virtual; abstract;

    procedure RefreshByUUID(const List: IOrmServerEntries);

    destructor Destroy; override;

    property UUID: string read FUUID;
    property Server: TOrmServerEntry read FServer;
    property Log: TStrings read FLog;
  end;

  { TServerList }

  TServerList = class(specialize TObjectList<TCustomServer>)
  public
    procedure RefreshByUUID(const List: IOrmServerEntries);
    function CreateOrFind(const Server: TOrmServerEntry): TCustomServer;
  end;
              
  TServerClass   = class of TCustomServer;
  TServerClasses = specialize TDictionary<string, TServerClass>;

var
  ServerClasses: TServerClasses;

implementation

{ TCustomServer }

constructor TCustomServer.Create(AServer: TOrmServerEntry);
begin
  inherited Create;          
  WriteLn('TCustomServer.Create');
  FServer   := AServer;
  FUUID    := AServer.UUID;
  FLog     := TStringList.Create;
end;

procedure TCustomServer.Prepare();
begin
  Assert(Assigned(Server), 'The server entry is currently unavailable.');
end;

procedure TCustomServer.Start();
begin
  Prepare();
end;

procedure TCustomServer.Stop();
begin
  Send('stop');
end;

procedure TCustomServer.RefreshByUUID(const List: IOrmServerEntries);
var
  Entry: TOrmServerEntry;
begin
  FServer := nil;
  for Entry in List do
    if Entry.UUID = FUUID then
      FServer := Entry;
end;

destructor TCustomServer.Destroy;
begin              
  WriteLn('TCustomServer.Free');
  FLog.Free;
  inherited Destroy;
end;

{ TServerList }

procedure TServerList.RefreshByUUID(const List: IOrmServerEntries);
var
  I: integer;
begin
  for I := 0 to Count - 1 do
    Items[I].RefreshByUUID(List);
end;

function TServerList.CreateOrFind(const Server: TOrmServerEntry): TCustomServer;
var
  I: integer;
  C: TServerClass;
begin
  Result := nil;
  // Find
  for I := 0 to Count - 1 do
    if Server.UUID = Items[I].UUID then begin
      Result := Items[I];
      exit; // found, exit...
    end;

  // Create
  if ServerClasses.TryGetValue(Server.Kind, C) then
    Result := Items[Add(C.Create(Server))];
end;

initialization
  ServerClasses := TServerClasses.Create();

finalization
  ServerClasses.Free;

end.

