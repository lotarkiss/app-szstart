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
    procedure btnOpenClick(Sender: TObject);
  private
  public              
    procedure UpdateFrame(const Server: TCustomServer);
  end;

implementation

uses LCLIntf;

{$R *.lfm}

{ TframeServerLog }

procedure TframeServerLog.btnOpenClick(Sender: TObject);
begin
  OpenDocument((Sender as TSpeedButton).Hint);
end;

procedure TframeServerLog.UpdateFrame(const Server: TCustomServer);
begin
  if Assigned(Server.Server) then begin
    lbTitle.Caption := Server.Server.Name;
    btnOpen.Hint := ExcludeTrailingPathDelimiter(Server.Server.Path);
  end
  else begin    
    lbTitle.Caption := Server.UUID;
    btnOpen.Hint := '';
  end;
  mmLog.Lines.Assign(Server.Log);
end;

end.

