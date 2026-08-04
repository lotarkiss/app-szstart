unit frmServerLog;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, Buttons, Menus,
  uServer;

type

  { TframeServerLog }

  TframeServerLog = class(TFrame)
    btnCommand: TButton;
    cbCommand: TComboBox;
    cbTail: TCheckBox;
    cbSendMessage: TCheckBox;
    lbCommand: TLabel;
    lbPlayerTitle: TLabel;
    lbLog: TLabel;
    lbTitle: TLabel;
    lbPlayers: TListBox;
    miKick: TMenuItem;
    miBan: TMenuItem;
    miOp: TMenuItem;
    miDeop: TMenuItem;
    mmLog: TMemo;
    pnTop: TPanel;
    btnOpen: TSpeedButton;
    pnRight: TPanel;
    pnBottom: TPanel;
    pnClient: TPanel;
    pmPlayer: TPopupMenu;
    Separator1: TMenuItem;
    spRight: TSplitter;
    tmTail: TTimer;
    procedure btnCommandClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure cbCommandKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure miDeopClick(Sender: TObject);
    procedure tmTailTimer(Sender: TObject);
  private
    FServer: TCustomServer;
  public
    procedure UpdateFrame(const AServer: TCustomServer);
    procedure DoServerResponse(Sender: TObject; const Data: string);
    procedure DoPlayersChange(Sender: TObject);

    property Server: TCustomServer read FServer write FServer;
  end;

implementation

uses Dialogs, LCLType, LCLIntf, uRcon;

resourcestring
  dlgPlayerOpText = 'Are you sure?';

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

procedure TframeServerLog.miDeopClick(Sender: TObject);
begin
  if (lbPlayers.ItemIndex <> -1) and
     (MessageDlg(dlgPlayerOpText, mtConfirmation, [mbYes, mbNo], 0, mbNo) = mrYes) then begin
    cbCommand.Text := format((Sender as TMenuItem).Hint, [lbPlayers.Items[lbPlayers.ItemIndex]]);
    btnCommand.Click;
  end;
end;

procedure TframeServerLog.tmTailTimer(Sender: TObject);
begin
  if cbTail.Checked then
    mmLog.SelStart := Length(mmLog.Lines.Text);
end;

procedure TframeServerLog.btnCommandClick(Sender: TObject);
begin
  if not cbSendMessage.Checked then
    FServer.Send(cbCommand.Text)
  else
    FServer.Send('say ' + cbCommand.Text);

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

procedure TframeServerLog.DoServerResponse(Sender: TObject; const Data: string);
begin
  if Sender = Server then begin
    mmLog.Lines.Text := mmLog.Lines.Text + Data;

    if Sender is TRconServer then
      mmLog.Lines.Text := mmLog.Lines.Text + LineEnding;
  end;
end;

procedure TframeServerLog.DoPlayersChange(Sender: TObject);
begin
  if Sender = Server then
    lbPlayers.Items.Assign(Server.Players);
end;

end.

