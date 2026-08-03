unit uServer;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uDatabase, Generics.Collections;

type

  // to avoid reloading full memo every time...
  TServerResponseEvent = procedure (Sender: TObject; const Data: string) of object;

  { TCustomServer }

  TCustomServer = class abstract
  private
    FLog: TStrings;
    FServer: TOrmServerEntry;
    FServerResponse: TServerResponseEvent;
    FUUID: string;
  protected
    procedure Prepare(); virtual;     
    function GetRunning: boolean; virtual; abstract;
  public
    constructor Create(AServer: TOrmServerEntry); virtual; reintroduce;

    procedure Start(); virtual;
    procedure Run(); virtual; abstract;
    procedure Stop(); virtual;
    procedure Kill(const AExitCode: integer = 1); virtual; abstract;
    procedure Send(ACommand: string); virtual; abstract;

    procedure FindRefByUUID(const List: IOrmServerEntries);

    destructor Destroy; override;

    property UUID: string read FUUID;
    property Server: TOrmServerEntry read FServer;
    property Log: TStrings read FLog;
    property IsRunning: boolean read GetRunning;
    property OnServerResponse: TServerResponseEvent read FServerResponse write FServerResponse;
  end;

  { TServerList }

  TServerList = class(specialize TObjectList<TCustomServer>)
  public
    procedure FindRefByUUID(const List: IOrmServerEntries);

    function Find(const Server: TOrmServerEntry; out Entry: TCustomServer): boolean;
    function CreateOrFind(const Server: TOrmServerEntry; Event: TServerResponseEvent = nil): TCustomServer;
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
  //WriteLn('TCustomServer.Create');
  FServer  := AServer;
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

procedure TCustomServer.FindRefByUUID(const List: IOrmServerEntries);
var
  Entry: TOrmServerEntry;
begin
  FServer := nil;    
  if Assigned(List) then
    for Entry in List do
      if Entry.UUID = FUUID then
        FServer := Entry;
end;

destructor TCustomServer.Destroy;
begin              
  //WriteLn('TCustomServer.Free');
  FLog.Free;
  inherited Destroy;
end;

{ TServerList }

procedure TServerList.FindRefByUUID(const List: IOrmServerEntries);
var
  I: integer;
begin
  for I := 0 to Count - 1 do
    Items[I].FindRefByUUID(List);
end;

function TServerList.Find(const Server: TOrmServerEntry; out
  Entry: TCustomServer): boolean;
var
  I: integer;
begin
  Entry  := nil;
  Result := false;
  for I := 0 to Count - 1 do
    if Server.UUID = Items[I].UUID then begin
      //WriteLn(Server.UUID, ' is ServerList[', I, ']');
      Entry  := Items[I];
      Result := true;
      break;
    end;
end;

function TServerList.CreateOrFind(const Server: TOrmServerEntry;
  Event: TServerResponseEvent): TCustomServer;
var
  C: TServerClass;
begin
  Result := nil;

  // Find
  if Find(Server, Result) then
    exit; // found, exit...

  // Create
  if ServerClasses.TryGetValue(Server.Kind, C) then begin
    Result := Items[Add(C.Create(Server))];
    Result.OnServerResponse := Event;
  end;
end;

initialization
  ServerClasses := TServerClasses.Create();

finalization
  ServerClasses.Free;

end.

