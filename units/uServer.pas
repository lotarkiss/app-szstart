unit uServer;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uDatabase;

type

  { TCustomServer }

  TCustomServer = class abstract
  private
    FLog: TStrings;
    FName: string;
    FServer: TOrmServerEntry;
  public
    constructor Create(AServer: TOrmServerEntry); virtual; reintroduce;

    procedure Start(); virtual; abstract;
    procedure Run(); virtual; abstract;
    procedure Stop(); virtual;
    procedure Kill(const AExitCode: integer = 1); virtual; abstract;
    procedure Send(ACommand: string); virtual; abstract;

    destructor Destroy; override;

    property Name: string read FName;
    property Server: TOrmServerEntry read FServer;
    property Log: TStrings read FLog;
  end;

implementation

{ TCustomServer }

constructor TCustomServer.Create(AServer: TOrmServerEntry);
begin
  inherited Create;
  Server   := AServer;
  FName    := AServer.Name;
  FLog     := TStringList.Create;
end;

procedure TCustomServer.Stop();
begin
  Send('stop');
end;

destructor TCustomServer.Destroy;
begin
  FLog.Free;
  inherited Destroy;
end;

end.

