unit frmServerLog;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, Buttons, uServer;

type

  { TframeServerLog }

  TframeServerLog = class(TFrame)
    btnCommand: TButton;
    cbCommand: TComboBox;
    lbCommand: TLabel;
    lbPlayerTitle: TLabel;
    lbLog: TLabel;
    lbTitle: TLabel;
    lbPlayers: TListBox;
    mmLog: TMemo;
    pnTop: TPanel;
    btnOpen: TSpeedButton;
    pnRight: TPanel;
    pnBottom: TPanel;
    pnClient: TPanel;
    spRight: TSplitter;
    procedure btnCommandClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure cbCommandKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState
      );
  private
    FServer: TCustomServer;
  public
    procedure UpdateFrame(const AServer: TCustomServer);

    property Server: TCustomServer read FServer write FServer;
  end;

implementation

uses LCLType, LCLIntf;

{$R *.lfm}

{ TframeServerLog }

procedure TframeServerLog.btnOpenClick(Sender: TObject);
begin
  OpenDocument((Sender as TSpeedButton).Hint);
end;

procedure TframeServerLog.cbCommandKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
    btnCommandClick(btnCommand);
end;

procedure TframeServerLog.btnCommandClick(Sender: TObject);
begin
  FServer.Send(cbCommand.Text);

  cbCommand.Text := '';
  cbCommand.SetFocus();
end;

procedure TframeServerLog.UpdateFrame(const AServer: TCustomServer);
begin
  FServer := AServer;

  if Assigned(FServer) then begin
    if Assigned(FServer.Server) then begin
      lbTitle.Caption := FServer.Server.Name;
      btnOpen.Hint := ExcludeTrailingPathDelimiter(FServer.Server.Path);
    end
    else begin
      lbTitle.Caption := FServer.UUID;
      btnOpen.Hint := '';
    end;

    mmLog.Lines.Assign(FServer.Log);
  end
  else begin
    lbTitle.Caption := '';     
    btnOpen.Hint := '';
    mmLog.Clear;
  end;
end;

end.

