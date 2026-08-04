unit frmMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, StdCtrls,
  ComCtrls, ExtCtrls, ActnList, Buttons, uDatabase, Types,
  frmServerLog, uServer, uIconMap;

type

  { TmcServiumMain }

  TmcServiumMain = class(TForm)
    acActions: TActionList;
    acServerProperties: TAction;
    acExit: TAction;
    edtSearch: TEdit;
    lbWelcomFooter: TLabel;
    lbWelcomDesc: TLabel;
    lblWelcomeHeader: TLabel;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    miProperties: TMenuItem;
    mnuMain: TMainMenu;
    nbtPages: TNotebook;
    pgServer: TPage;
    pnlLeft: TPanel;
    pnlToolbar: TPanel;
    pgWelcome: TPage;
    pmList: TPopupMenu;
    btnStart: TSpeedButton;
    btnStop: TSpeedButton;
    btnKill: TSpeedButton;
    btnCreate: TSpeedButton;
    btnImport: TSpeedButton;
    btnNetworkTest: TSpeedButton;
    splSplitter: TSplitter;
    stbStatusBar: TStatusBar;
    lbxServers: TListBox;
    tdQuit: TTaskDialog;
    tmPoll: TTimer;
    tmDance: TTimer;
    procedure acServerPropertiesExecute(Sender: TObject);
    procedure edtSearchChange(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure lbxServersClick(Sender: TObject);
    procedure lbxServersDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure btnStartClick(Sender: TObject);
    procedure tmDanceTimer(Sender: TObject);
    procedure tmPollTimer(Sender: TObject);
  private
  public
    Query: IOrmServerEntries;
    Servers: TServerList;
    Logs: TframeServerLog;
    IconMap: TIconMap;
  end;

var
  mcServiumMain: TmcServiumMain;

implementation

uses uPlatform, uExamples, dlgServerProps, LCLType, uRCON, uVersions;

{$R *.lfm}

resourcestring
  serverStopped = 'Stopped';
  serverRunning = 'Running';

{ TmcServiumMain }

procedure TmcServiumMain.FormCreate(Sender: TObject);
begin
  Logs := TframeServerLog.Create(Self); // so will be freed automatically...
  Logs.Parent := pgServer;
  Logs.Align := alClient;

  Servers := TServerList.Create(true); // stateful data for servers
  IconMap := TIconMap.Create(); // icons

  InitSQLite();
  UpdateMenuKeys(mnuMain.Items);
  QueryServersAll(Query);  // stateless data from db
                 
  Query := nil;  // initialize properly
  edtSearch.OnChange := @edtSearchChange;
  edtSearch.OnChange(edtSearch);

  // now when everything is ready, start ticking
  tmDance.Enabled := true;
  tmPoll.Enabled := true;
end;

procedure TmcServiumMain.FormDestroy(Sender: TObject);
begin
  // first of all stop ticking
  tmDance.Enabled := false;
  tmPoll.Enabled := false;

  // and then..
  Servers.Free();                   
  IconMap.Free();
  lbxServers.Clear; // clear references to Query IList<>

  Query := nil;   // free the list itself

  FreeSQLite();
end;

procedure TmcServiumMain.FormResize(Sender: TObject);
begin
  pnlLeft.Constraints.MaxWidth := ClientWidth * 3 div 10;
  pnlLeft.Constraints.MinWidth := ClientWidth * 1 div 10;
end;

procedure TmcServiumMain.lbxServersClick(Sender: TObject);
begin
  case lbxServers.ItemIndex of
    -1: begin
      nbtPages.PageIndex := pgWelcome.PageIndex;
      Logs.UpdateFrame(nil);
    end
    else begin
      nbtPages.PageIndex := pgServer.PageIndex;
      Logs.UpdateFrame(
        Servers.CreateOrFind(
          lbxServers.Items.Objects[lbxServers.ItemIndex] as TOrmServerEntry,
          @(Logs.DoServerResponse),
          @(Logs.DoPlayersChange)
        )
      );
    end;
  end;
end;

procedure TmcServiumMain.lbxServersDrawItem(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
var
  Style: TTextStyle;
  Target: TRect;
const
  IconSize = 64; // change later when we have ImageList
  TextPadding = 10; // also scale these with DPI (ToDO!)
begin
  with (Control as TListBox).Canvas do begin
    if odSelected in State then begin
      Brush.Color := clHighlight;
      Font.Color := clHighlightText;
    end
    else begin
      Brush.Color := clWindow;
      Font.Color := clWindowText;
    end;
    FillRect(ARect);

    // Icon
    Target := Rect(
        ARect.Left + TextPadding,
        ARect.Top + (ARect.Height - IconSize) div 2,
        ARect.Left + TextPadding + IconSize,
        ARect.Top + (ARect.Height - IconSize) div 2 + IconSize
    );
    IconMap.DrawIcon((Control as TListBox).Canvas, Target,
       (Control as TListBox).Items.Objects[Index] as TOrmServerEntry);

    // Texts
    Style := TextStyle;
    Style.Layout := tlCenter;
    if Index <> -1 then
      with (Control as TListBox).Items.Objects[Index] as TOrmServerEntry do begin
        // Top line
        Target := Rect(
          ARect.Left + TextPadding * 2 + IconSize,
          ARect.Top + TextPadding,
          ARect.Right - TextPadding,
          ARect.Top + ARect.Height div 3
        );                     
        Font.Style := [fsBold];
        TextRect(Target, Target.Left, Target.Top, Name, Style);

        // Middle line
        Target := Rect(
          ARect.Left + TextPadding * 2 + IconSize,
          ARect.Top  + ARect.Height div 3,
          ARect.Right - TextPadding,
          ARect.Top  + 2 * ARect.Height div 3
        );                      
        Font.Style := [fsItalic];
        TextRect(Target, Target.Left, Target.Top, Description, Style);

        // Bottom line
        Target := Rect(
          ARect.Left + TextPadding * 2 + IconSize,
          ARect.Top  + 2 * ARect.Height div 3,
          ARect.Right - TextPadding,
          ARect.Bottom - TextPadding
        );                             
        Font.Style := [];
        TextRect(Target, Target.Left, Target.Top, lbxServers.Items.ValueFromIndex[Index], Style);
      end;

    if odFocused in State then
      DrawFocusRect(ARect);
  end;
end;

procedure TmcServiumMain.btnStartClick(Sender: TObject);
begin
  if Assigned(Logs.Server) then
    case (Sender as TComponent).Tag of
      1: Logs.Server.Start();
      2: Logs.Server.Stop();
      3: Logs.Server.Kill();
      else
        raise Exception.Create('Unimplemented operation.');
    end;
end;

procedure TmcServiumMain.tmDanceTimer(Sender: TObject);
var
  I: integer;
  Entry: TCustomServer;
begin
  // Update status messages in the list
  with lbxServers.Items do
    for I := 0 to Count - 1 do
      if Servers.Find(Objects[I] as TOrmServerEntry, Entry) and
         Assigned(Entry) and
         Entry.IsRunning then
        ValueFromIndex[I] := serverRunning
      else
        ValueFromIndex[I] := serverStopped;

  lbxServers.Invalidate(); // ask for repaint

  // Then buttons
  if Assigned(Logs.Server) then begin
    btnStart.Enabled := not Logs.Server.IsRunning;
    btnStop.Enabled  := not btnStart.Enabled;
    btnKill.Enabled  := btnStop.Enabled;
  end
  else begin
    btnStart.Enabled := false;  
    btnStop.Enabled := false;
    btnKill.Enabled := false;
  end;
end;

procedure TmcServiumMain.tmPollTimer(Sender: TObject);
var
  Item: TCustomServer;
begin
  // Get data from TCustomServer elements
  for Item in Servers do
    Item.Run();
end;

procedure TmcServiumMain.edtSearchChange(Sender: TObject);
var
  Server: TOrmServerEntry;
  Result: boolean;
begin
  lbxServers.Items.Clear;  
  if edtSearch.Text = '' then
    Result := QueryServersAll(Query)
  else
    Result := QueryServersByName(edtSearch.Text, Query);

  if Result then begin
    IconMap.UpdateMissing(Query); // update icons
    Servers.FindRefByUUID(Query); // assign entries to new indices
    for Server in Query do begin
      WriteLn(Server.Path);
      if (Server.Kind = 'rcon') or DirectoryExists(Server.Path) then
        lbxServers.Items.AddObject(Server.UUID + '=' + serverStopped, Server);
    end
  end
  else
    Servers.FindRefByUUID(nil); // all entries are orphan
end;

procedure TmcServiumMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if Servers.IsAnyRunning() then begin
    CanClose := false;
    tdQuit.Execute(Handle);
    case tdQuit.ModalResult of
      100: Servers.StopAll();
      101: Servers.KillAll();
      else
        exit;
    end;
  end;
end;

procedure TmcServiumMain.acServerPropertiesExecute(Sender: TObject);
var
  Server: TOrmServerEntry;
  G: TPortableNetworkGraphic;
begin
  if lbxServers.ItemIndex <> -1 then
    with TdlgServerProperties.Create(Self) do
      try
        Server := lbxServers.Items.Objects[lbxServers.ItemIndex] as TOrmServerEntry;
        Load(Server);

        if IconMap.TryGetValue(Server.UUID, G) then
          imgIcon.Picture.Assign(G)
        else
          imgIcon.Picture.Assign(nil);

        if ShowModal = mrOK then
          Save(Server);

        edtSearchChange(Self);
      finally
        Free;
      end;
end;

end.

