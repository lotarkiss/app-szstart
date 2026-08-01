unit uProcess;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uDatabase, Process, uServer;

type

  { TProcessServer }

  TProcessServer = class abstract(TCustomServer)
  private
    FProcess: TProcess;
  protected
    procedure Prepare(); override;
    function GetRunning: boolean; override;
  public
    constructor Create(AServer: TOrmServerEntry); override;
    destructor Destroy; override;

    procedure Start(); override;
    procedure Run(); override;
    procedure Kill(const AExitCode: integer = 1); override;
    procedure Send(ACommand: string); override;

    property Process: TProcess read FProcess;
  end;

  { TJavaServer }

  TJavaServer = class(TProcessServer)
  public     
    procedure Prepare(); override;
  end;

  { TBedrockServer }

  TBedrockServer = class(TProcessServer)
  public
    procedure Prepare(); override;
  end;

implementation

uses Math;

{ TProcessServer }

constructor TProcessServer.Create(AServer: TOrmServerEntry);
begin
  inherited Create(AServer);
  FProcess := nil;
end;

procedure TProcessServer.Run();
const
  BufSize = 2048;
var
  Buffer: string;
  BytesRead: integer;
begin
  {$ifdef FPC_HAS_FEATURE_ANSISTRINGS}
  if Assigned(FProcess) and (FProcess.Running) then begin

    SetLength(Buffer, BufSize + 1);
    BytesRead := FProcess.Output.Read(Buffer[1], Min(BufSize, FProcess.Output.NumBytesAvailable));
    SetLength(Buffer, BytesRead); //assume sizeof(char) = 1
    Log.Text := Log.Text + buffer;
    if Assigned(OnServerResponse) then
      OnServerResponse(Self, Buffer);
  end;
  {$endif}
end;

procedure TProcessServer.Kill(const AExitCode: integer);
begin
  if Assigned(FProcess) then begin
    if FProcess.Running then
      FProcess.Terminate(AExitCode);

    FreeAndNil(FProcess);
  end;
end;

procedure TProcessServer.Send(ACommand: string);
begin
  if Assigned(FProcess) and (FProcess.Running) then begin
    ACommand := ACommand + LineEnding;
    FProcess.Input.Write(ACommand[1], length(ACommand) * SizeOf(char));
  end;
end;

destructor TProcessServer.Destroy;
begin
  if Assigned(FProcess) then
    FProcess.Free;

  inherited Destroy;
end;

procedure TProcessServer.Prepare();
begin
  inherited Prepare();

  // check for dead process
  if Assigned(FProcess) and (not FProcess.Running) then
    FreeAndNil(FProcess);

  // now that we cleaned up...
  Assert(not Assigned(FProcess), 'The process is exists, maybe already running?');

  FProcess := TProcess.Create(nil);
  FProcess.Options := [poUsePipes, poStderrToOutPut];
  FProcess.CurrentDirectory := Server.Path;
end;

function TProcessServer.GetRunning: boolean;
begin
  Result := Assigned(FProcess) and (FProcess.Running);
end;

procedure TProcessServer.Start();
begin
  inherited Start();
  try
    FProcess.Execute;
    WriteLn('The show has begun ', FProcess.Running);
  except
    on E: Exception do begin
      FreeAndNil(FProcess);
      raise E;
    end;
  end;
end;

{ TJavaServer }

procedure TJavaServer.Prepare;
var
  S: string;
begin
  inherited Prepare();
  Process.Executable := Server.java_jrePath;
  Process.Parameters.Add(format('-Xms%dM', [Server.java_jvmXMS]));
  Process.Parameters.Add(format('-Xmx%dM', [Server.java_jvmXMX]));
  CommandToList(Server.java_jvmArgs, Process.Parameters);

  Process.Parameters.Add('-jar');
  Process.Parameters.Add(Server.java_jarName);                           
  CommandToList(Server.Arguments, Process.Parameters);

  Write(Process.Executable, ' ');
  for S in Process.Parameters do
    Write(S, ' ');
end;

{ TBedrockServer }

procedure TBedrockServer.Prepare();
begin
  inherited Prepare();
  Process.Executable := Server.bedrock_serverPath;
  CommandToList(Server.Arguments, Process.Parameters);
end;

initialization
  ServerClasses.Add('java', TJavaServer);
  ServerClasses.Add('bedrock', TBedrockServer);

end.

