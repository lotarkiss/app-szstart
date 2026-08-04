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
    FPlayers: TStrings;
    FPlayersChange: TNotifyEvent;
    FServer: TOrmServerEntry;
    FServerResponse: TServerResponseEvent;
    FUUID: string;
  protected
    procedure Prepare(); virtual;     
    function GetRunning: boolean; virtual; abstract;
    procedure InternalResponse(const Data: string); virtual;
  public
    constructor Create(AServer: TOrmServerEntry); virtual; reintroduce;

    procedure Start(); virtual;
    procedure Run(); virtual; abstract;
    procedure Stop(); virtual;
    procedure Kill(const AExitCode: integer = 1); virtual; abstract;
    procedure Send(ACommand: string); virtual; abstract;

    procedure FindRefByUUID(const List: IOrmServerEntries);

    destructor Destroy; override;

    property Players: TStrings read FPlayers;
    property UUID: string read FUUID;
    property Server: TOrmServerEntry read FServer;
    property Log: TStrings read FLog;
    property IsRunning: boolean read GetRunning;
    property OnServerResponse: TServerResponseEvent read FServerResponse write FServerResponse;
    property OnPlayersChange: TNotifyEvent read FPlayersChange write FPlayersChange;
  end;

  { TServerList }

  TServerList = class(specialize TObjectList<TCustomServer>)
  public
    procedure FindRefByUUID(const List: IOrmServerEntries);

    function Find(const Server: TOrmServerEntry; out Entry: TCustomServer): boolean;
    function CreateOrFind(const Server: TOrmServerEntry;
      ResponseEvent: TServerResponseEvent = nil;
      PlayersEvents: TNotifyEvent = nil): TCustomServer;

    function IsAnyRunning(): boolean;
    procedure StopAll();
    procedure KillAll(const AExitCode: integer = 1);
  end;
              
  TServerClass   = class of TCustomServer;
  TServerClasses = specialize TDictionary<string, TServerClass>;

var
  ServerClasses: TServerClasses;

implementation

uses RegExpr;

{ TCustomServer }

constructor TCustomServer.Create(AServer: TOrmServerEntry);
begin
  inherited Create;          
  //WriteLn('TCustomServer.Create');
  FServer  := AServer;
  FUUID    := AServer.UUID;
  FLog     := TStringList.Create;
  FPlayers := TStringList.Create;
end;

procedure TCustomServer.Prepare();
begin
  Assert(Assigned(Server), 'The server entry is currently unavailable.');
end;

procedure TCustomServer.InternalResponse(const Data: string);
const
  regExJoin  = '(?:\]:\s+([A-Za-z0-9_.]+)\s+joined|Player connected:\s*([^,\n]+))';
  regExLeave = '(?:\]:\s+([A-Za-z0-9_.]+)\s+left|Player disconnected:\s*([^,\n]+))';
var
  I, J: integer;
begin
  if Trim(Data) = '' then
    exit;

  // Player connected
  with TRegExpr.Create(regExJoin) do
    try
      ModifierI := true; // case sensitive
      if Exec(Data) then
        for I := 1 to 2 do
          if Match[I] <> '' then begin
            Players.Add(Match[I]);

            if Assigned(FPlayersChange) then
              FPlayersChange(Self);
          end;
    finally
      Free;
    end;

  // Player disconnected
  with TRegExpr.Create(regExLeave) do
    try
      ModifierI := true; // case sensitive
      if Exec(Data) then
        for I := 1 to 2 do
           if Match[I] <> '' then begin
             J := Players.IndexOf(Match[I]);
             if J <> -1 then begin
               Players.Delete(J);

               if Assigned(FPlayersChange) then
                 FPlayersChange(Self);
             end;
           end;
    finally
      Free;
    end;

  if Assigned(FServerResponse) then
    FServerResponse(Self, Data);
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
  FPlayers.Free;
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

function TServerList.IsAnyRunning(): boolean;
var
  S: TCustomServer;
begin
  Result := false;
  for S in Self do
    if S.IsRunning then
      exit(true);
end;

procedure TServerList.StopAll();
var
  S: TCustomServer;
begin
  for S in Self do
    if S.IsRunning then
      S.Stop();
end;

procedure TServerList.KillAll(const AExitCode: integer);
var
  S: TCustomServer;
begin
  for S in Self do
    if S.IsRunning then
      S.Kill(AExitCode);
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
  ResponseEvent: TServerResponseEvent; PlayersEvents: TNotifyEvent
  ): TCustomServer;
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
    Result.OnServerResponse := ResponseEvent;
    Result.OnPlayersChange  := PlayersEvents;
  end;
end;

initialization
  ServerClasses := TServerClasses.Create();

finalization
  ServerClasses.Free;

end.

