unit uRCON;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uServer, ssockets, uDatabase;


// Source: https://minecraft.wiki/w/RCON

const
  RconPayloadLogin   = 3;
  RconPayloadCommand = 2;
  RconPayloadMulti   = 0;

  RconRequestInvalid = dword(-1);

  RconSizeMaxSend       = 1460;
  RconSizeMaxReceive    = 4110;

  RconHeader            = 3 * SizeOf(dword);
  RconFooter            = SizeOf(byte) + SizeOf(char); // null termator + bPad
  RconContentMaxSend    = 1446;
  RconContentMaxReceive = 4096;

type
  {$PACKRECORDS 1}
  TRconPayload = packed record  // little-endian, swap bytes on BE platform
    dwLength: dword;
    dwClientId: dword;
    dwType: dword;
    szData: array [0..RconContentMaxReceive - 1] of AnsiChar;
    bPad: byte; // should be 0
  end;
  PRconPayload = ^TRconPayload;
  {$PACKRECORDS DEFAULT}

type

  { TRconServer }

  TRconServer = class(TCustomServer)
  private
    FClientID: dword;
    FSocket: TInetSocket;
  protected
    procedure Prepare(); override;
    function GetRunning: boolean; override;
  public
    constructor Create(AServer: TOrmServerEntry); override;
    destructor Destroy; override;

    procedure Start(); override;
    procedure Run(); override;
    procedure Kill(const AExitCode: integer = 1); override;
    procedure Send(ACommand: string); override; overload;
    procedure Send(ACommand: string; const PayloadType: dword); overload;

    property Socket: TInetSocket read FSocket;
    property ClientID: dword read FClientID;
  end;

implementation

uses Dialogs;

resourcestring
  dlgRconPasswordCaption = 'Specify RCON password';
  dlgRconPasswordPrompt  = 'Please specify the RCON password for %s:%d';

{ TRconServer }

constructor TRconServer.Create(AServer: TOrmServerEntry);
begin
  inherited Create(AServer);
  FSocket   := nil;
  FClientID := random($FFFFFFFF);
end;

destructor TRconServer.Destroy;
begin
  if Assigned(FSocket) then
    FSocket.Free;

  inherited Destroy;
end;

procedure TRconServer.Prepare();
begin
  inherited Prepare();

  Assert(not Assigned(FSocket), 'The socket is exists, maybe already connected?');

  FSocket   := TInetSocket.Create(Server.rcon_remoteHost, Server.rcon_remotePort, Server.rcon_connectTimeout);
  FSocket.IOTimeout := Server.rcon_ioTimeout;
end;

function TRconServer.GetRunning: boolean;
begin
  Result := Assigned(FSocket);
end;

procedure TRconServer.Start();
var
  APassword: string;
begin
  inherited Start();

  APassword := '';
  if InputQuery(dlgRconPasswordCaption,
      format(dlgRconPasswordPrompt,
            [Server.rcon_remoteHost, Server.rcon_remotePort]), true, APassword) then
    Send(APassword, RconPayloadLogin) // send it to the server
  else
    FreeAndNil(FSocket);
end;

procedure TRconServer.Run();
var
  Payload: PRconPayload;
  pDest: PByte;
  Tmp: integer;
  Size, TotalRead: dword;
  Data: string;
begin
  {$ifdef FPC_HAS_FEATURE_ANSISTRINGS} // assume sizeof(char) = sizeof(byte)     
  if Assigned(FSocket) then begin
    Tmp := Socket.Read(Size, sizeOf(dword));
    if Tmp < 0 then // no data available yet
      exit;
    if Tmp = 0 then begin // server is down
      FreeAndNil(FSocket);
      exit;
    end;

    if Size > RconSizeMaxReceive then // malformed packet
      exit;

    if Tmp = sizeOf(dword) then begin
      GetMem(Payload, Size + SizeOf(dword));
      try
        with Payload^ do begin
          dwLength := Size;
          FillChar(dwClientId, dwLength, #0);

          TotalRead := 0;
          pDest := PByte(@dwClientId);
          while TotalRead < dwLength do begin
            Tmp := Socket.Read(pDest[TotalRead], dwLength - TotalRead);
            if Tmp <= 0 then
              break;
            Inc(TotalRead, Tmp);
          end;

          if TotalRead <> dwLength then // malformed packet
            exit;

          if dwClientID = RconRequestInvalid then begin // Bad password, or server error...
            FreeAndNil(FSocket);
            exit;
          end;

          // Fix ending and cstr null terminator, just in case...
          FillChar(PByte(Payload)[dwLength + SizeOf(dword) - RconFooter], RconFooter, #0);
          Data := PChar(@szData[0]);
          Log.Text := Log.Text + Data;
          if Assigned(OnServerResponse) then
            OnServerResponse(Self, Data);
        end;
      finally
        FreeMem(Payload);
      end;
    end;
  end;
  {$else}
  Assert(false, 'Unimplemented operation.');
  {$endif}
end;

procedure TRconServer.Kill(const AExitCode: integer);
begin
  // this is only a disconnect command, which make remote server still running!
  if Assigned(FSocket) then
    FreeAndNil(FSocket);
end;

procedure TRconServer.Send(ACommand: string);
begin
  Send(ACommand, RconPayloadCommand);
end;

procedure TRconServer.Send(ACommand: string; const PayloadType: dword);
var
  Payload: PRconPayload;
  Size: integer;
begin
  {$ifdef FPC_HAS_FEATURE_ANSISTRINGS} // assume sizeof(char) = sizeof(byte)
  if Assigned(FSocket) then begin
    if length(ACommand) > RconContentMaxSend then // calculate with null terminator as well
      SetLength(ACommand, RconContentMaxSend); // Trim

    SetLength(ACommand, length(ACommand) + 2); // still not ASCII, but UTF-8, maybe works...
    ACommand[High(ACommand) - 1] := #0; // cstr null terminator
    ACommand[High(ACommand)] := #0;     // bPad = 0

    Size := length(ACommand) + RconHeader; // footer byte included in ACommand
    GetMem(Payload, Size);
    try
      with Payload^ do begin
        dwLength   := Size - SizeOf(dword); // length of the remainder of packet
        dwClientId := ClientID;
        dwType     := PayloadType;
        Move(ACommand[1], szData[0], length(ACommand)); // including null terminator, and bPad = 0
      end;
      try
        Socket.Write(Payload^, Size);
      except
        on E: ESocketError do begin
          FreeAndNil(FSocket);
          raise E;
        end
      end
    finally
      FreeMem(Payload);
    end;
  end;
  {$else}
  Assert(false, 'Unimplemented operation.');
  {$endif}
end;

initialization
  randomize;
  ServerClasses.Add('rcon', TRconServer);

end.

