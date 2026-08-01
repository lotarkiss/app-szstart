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

{ TProcessServer }

constructor TProcessServer.Create(AServer: TOrmServerEntry);
begin
  inherited Create(AServer);
  FProcess := nil;
end;

procedure TProcessServer.Run();
var
  S: TStringStream;
begin
  if Assigned(FProcess) and (FProcess.Active) then begin
    S := TStringStream.Create;
    try
      S.LoadFromStream(FProcess.Output);
      Log.Text := Log.Text + S.DataString;
    finally
      S.Free;
    end;
  end;
end;

procedure TProcessServer.Kill(const AExitCode: integer);
begin
  if Assigned(FProcess) then begin
    if FProcess.Active then
      FProcess.Terminate(AExitCode);

    FreeAndNil(FProcess);
  end;
end;

procedure TProcessServer.Send(ACommand: string);
begin
  if Assigned(FProcess) and (FProcess.Active) then begin
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
  Assert(not Assigned(FProcess), 'The process is exists, maybe already running?');

  FProcess := TProcess.Create(nil);
  FProcess.Options := [poUsePipes, poWaitOnExit, poStderrToOutPut];
end;

procedure TProcessServer.Start();
begin
  inherited Start();
  FProcess.Execute;
end;

{ TJavaServer }

procedure TJavaServer.Prepare;
begin
  inherited Prepare();
  Process.Executable := Server.java_jrePath;
  Process.Parameters.Add(format('-Xms%dM', [Server.java_jvmXMS]));
  Process.Parameters.Add(format('-Xmx%dM', [Server.java_jvmXMX]));
  CommandToList(Server.java_jvmArgs, Process.Parameters);

  Process.Parameters.Add('-jar');
  Process.Parameters.Add(Server.java_jarName);                           
  CommandToList(Server.Arguments, Process.Parameters);
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

