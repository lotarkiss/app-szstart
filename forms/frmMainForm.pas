unit frmMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, StdCtrls,
  ComCtrls, ExtCtrls, ActnList, StdActns, uDatabase, Types;

type

  { TmcServiumMain }

  TmcServiumMain = class(TForm)
    acActions: TActionList;
    acServerProperties: TAction;
    acExit: TAction;
    edtSearch: TEdit;
    lblWelcomeText: TLabel;
    lblWelcomeHeader: TLabel;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    mnuMain: TMainMenu;
    nbtPages: TNotebook;
    pnlLeft: TPanel;
    pnlToolbar: TPanel;
    pgWelcome: TPage;
    pmList: TPopupMenu;
    splSplitter: TSplitter;
    stbStatusBar: TStatusBar;
    lbxServers: TListBox;
    procedure acServerPropertiesExecute(Sender: TObject);
    procedure edtSearchChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lbxServersDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
  private
  public
    Servers: IOrmServerEntries;
    IconColor: TColor;
  end;

var
  mcServiumMain: TmcServiumMain;

implementation

{$R *.lfm}

uses uPlatform, uExamples, dlgServerProps, LCLType;

{ TmcServiumMain }

procedure TmcServiumMain.FormCreate(Sender: TObject);
begin
  InitSQLite();
  UpdateMenuKeys(mnuMain.Items);
  QueryServersAll(Servers);
                 
  Servers := nil;  // initialize properly
  edtSearch.OnChange := @edtSearchChange;
  edtSearch.OnChange(edtSearch);

  IconColor := random($FFFFFF + 1); // for debugging
end;

procedure TmcServiumMain.FormDestroy(Sender: TObject);
begin
  lbxServers.Clear; // clear references to Servers IList<>
  Servers := nil;   // free the list itself

  FreeSQLite();
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
    Brush.Color := IconColor;
    Target := Rect(
        ARect.Left + TextPadding,
        ARect.Top + (ARect.Height - IconSize) div 2,
        ARect.Left + TextPadding + IconSize,
        ARect.Top + (ARect.Height - IconSize) div 2 + IconSize
    );
    FillRect(Target);

    // Texts
    Style := TextStyle;
    Style.Layout := tlCenter;
    if Index <> -1 then
      with (Control as TListBox).Items.Objects[Index] as TOrmServerEntry do begin
        // Top line
        Target := Rect(
          ARect.Left + TextPadding * 2 + IconSize,
          ARect.Top,
          ARect.Right - TextPadding,
          ARect.Top + ARect.Height div 2
        );
        TextRect(Target, Target.Left, Target.Top, Name, Style);

        // Bottom line
        Target := Rect(
          ARect.Left + TextPadding * 2 + IconSize,
          ARect.Top  + ARect.Height div 2,
          ARect.Right - TextPadding,
          ARect.Bottom
        );
        TextRect(Target, Target.Left, Target.Top, Description, Style);
      end;

    if odFocused in State then
      DrawFocusRect(ARect);
  end;
end;

procedure TmcServiumMain.edtSearchChange(Sender: TObject);
var
  Server: TOrmServerEntry;
  Result: boolean;
begin
  lbxServers.Items.Clear;  
  if edtSearch.Text = '' then
    Result := QueryServersAll(Servers)
  else
    Result := QueryServersByName(edtSearch.Text, Servers);

  if Result then
    for Server in Servers do begin
      WriteLn(Server.Path);
      if DirectoryExists(Server.Path) then
        lbxServers.Items.AddObject(Server.Name, Server);
    end;
end;

procedure TmcServiumMain.acServerPropertiesExecute(Sender: TObject);
var
  Server: TOrmServerEntry;
begin
  if lbxServers.ItemIndex <> -1 then
    with TdlgServerProperties.Create(Self) do
      try
        Server := lbxServers.Items.Objects[lbxServers.ItemIndex] as TOrmServerEntry;
        Load(Server);

        if ShowModal = mrOK then
          Save(Server);

        edtSearchChange(Self);
      finally
        Free;
      end;
end;

end.

