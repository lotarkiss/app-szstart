unit uServerClass;

interface

uses SysUtils, Classes, SQLDB, Generics.Collections;

type
  TServerPath = (spPwd, spLog, spIcon, spProps, spEula);

const
  DefServerPath: array [TServerPath] of string =
    (
      '',                   //spPwd
      'logs/latest.log',    //spLog
      'server-icon.png',    //spIcon
      'server.properties',  //spProps
      'eula.txt'            //spEula
    );

type

  { TCustomServer }

  TCustomServer = class abstract(TPersistent)
  private
    FArgs: string;
    FDesc: string;
    FId: string;
    FIsProt: boolean;
    FKind: string;
    FLogs: TStrings;
    FName: string;
    FPath: string;
    procedure SetPath(AValue: string);
  protected
    LogFile: TextFile;
    Paths: array [TServerPath] of string;
  public
    constructor Create(Query: TSQLQuery); overload; virtual; reintroduce;
    constructor Create(const AId, AKind: string); overload; reintroduce; deprecated;
    procedure AssignTo(Dest: TPersistent); override;
    destructor Destroy; override;

    procedure Update;

    property Id: string read FId;    
    property Kind: string read FKind;            
    property Path: string read FPath write SetPath;
    property Name: string read FName write FName;
    property Description: string read FDesc write FDesc;
    property IsProtected: boolean read FIsProt write FIsProt;
    property Arguments: string read FArgs write FArgs;
    property Logs: TStrings read FLogs;
  end;

  TServerClass = class of TCustomServer;

  { TServerManager }

  TServerManager = class(specialize TObjectList<TCustomServer>)
  public
    procedure QueryServers(Query: TSQLQuery);
    function FindServerById(const AId: string): TCustomServer;
  end;

var
  ServerKinds: specialize TDictionary<string, TServerClass>;

implementation

uses uDatabase;

{ TCustomServer }

procedure TCustomServer.SetPath(AValue: string);
var
  PathKind: TServerPath;
begin
  if FPath <> '' then
    FPath := IncludeTrailingPathDelimiter(AValue)
  else
    FPath := '';

  for PathKind in TServerPath do
    Paths[PathKind] := FPath + DefServerPath[PathKind];

  {$I-}
  CloseFile(LogFile);
  AssignFile(LogFile, Paths[spLog]);
  Reset(LogFile);
  {$I+}
  Logs.Clear;

  Update;
end;

constructor TCustomServer.Create(Query: TSQLQuery);
begin
  FLogs   := TStringList.Create;

  FId     := Query.FieldByName('id').AsString;
  FKind   := Query.FieldByName('kind').AsString;
  FName   := Query.FieldByName('name').AsString;
  FDesc   := Query.FieldByName('desc').AsString;
  FIsProt := Query.FieldByName('protected').AsInteger <> 0;  
  FArgs   := Query.FieldByName('args').AsString;
                                                   
  SetPath(Query.FieldByName('path').AsString);
end;

constructor TCustomServer.Create(const AId, AKind: string);
begin
  FLogs   := TStringList.Create;
  FId     := AId;
  FKind   := AKind;

  SetPath('');
end;

procedure TCustomServer.AssignTo(Dest: TPersistent);
var
  Target: TCustomServer;
begin
  if Assigned(Dest) and (Dest is TCustomServer) then begin
    Target         := Dest as TCustomServer;
    Target.FId     := FId;
    Target.FKind   := FKind;
    Target.FName   := FName;
    Target.FDesc   := FDesc;
    Target.FIsProt := FIsProt;
    Target.FArgs   := FArgs;

    Target.SetPath(FPath);
  end
  else
    inherited AssignTo(Dest);
end;

destructor TCustomServer.Destroy;
begin
  {$I-}
  CloseFile(LogFile);
  {$I+}

  FLogs.Free;
  inherited Destroy;
end;

procedure TCustomServer.Update;
var
  Line: string;
begin
  if not DirectoryExists(Paths[spPwd]) then
    exit;

  {$I-}
  while not Eof(LogFile) do begin
    ReadLn(LogFile, Line);
    Logs.Add(Line);
  end;
  {$I+}
end;

{ TServerManager }

procedure TServerManager.QueryServers(Query: TSQLQuery);
var
  KindName: string;
  KindClass: TServerClass;
begin
  Clear;
  OwnsObjects := true;

  uDatabase.QueryServersAll(Query);
  with Query do
    try
      while not Eof do begin
        KindName := FieldByName('kind').AsString;
        if ServerKinds.TryGetValue(KindName, KindClass) then
          Add(KindClass.Create(Query));

        Next;
      end;
    finally
      Close;
    end;
end;

function TServerManager.FindServerById(const AId: string): TCustomServer;
var
  I: integer;
begin
  for I := 0 to Count - 1 do
    if Assigned(Items[I]) and (Items[I].Id = AId) then begin
      Result := Items[I];
      exit;
    end;
end;

initialization
  ServerKinds := specialize TDictionary<string, TServerClass>.Create;

finalization
  ServerKinds.Free;

end.
