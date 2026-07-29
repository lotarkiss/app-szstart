unit dlgServerProps;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, uDatabase;

type

  { TdlgServerProperties }

  TdlgServerProperties = class(TForm)
    btnCancel: TButton;
    btnOK: TButton;
    cbLevelName: TComboBox;
    cbLevelType: TComboBox;
    edLevelSeed: TEdit;
    edName: TEdit;
    gbLevel: TGroupBox;
    gbEntry: TGroupBox;
    lbInfoSeedType: TLabel;
    lbPlaceholder1: TLabel;
    lbLevelName: TLabel;
    lbLevelSeed: TLabel;
    lbLevelType: TLabel;
    lbName: TLabel;
    lbDescription: TLabel;
    lbPages: TListBox;
    mmDescription: TMemo;
    pgWorld: TPage;
    pgGeneral: TPage;
    pgNotebook: TNotebook;
    pnBottom: TPanel;
    spSplitter: TSplitter;
    procedure lbPagesClick(Sender: TObject);
  public
    procedure Load(AServer: TOrmServerEntry);
    procedure Save(AServer: TOrmServerEntry);
  end;

var
  dlgServerProperties: TdlgServerProperties;

implementation

uses Math, uMinecraft;

resourcestring
  dlgPropsCaption = '%s properties';

{$R *.lfm}

{ TdlgServerProperties }

procedure TdlgServerProperties.lbPagesClick(Sender: TObject);
begin
  if lbPages.ItemIndex = -1 then
    pgNotebook.PageIndex := -1
  else
    pgNotebook.PageIndex := (lbPages.Items.Objects[lbPages.ItemIndex] as TPage).PageIndex;
end;

procedure TdlgServerProperties.Load(AServer: TOrmServerEntry);
var
  I: integer;
  Kind, Path: string;
  Props: TServerProperties;
begin
  // Dialog caption
  Caption := format(dlgPropsCaption, [AServer.Name]);

  // Load general, and server specific pages into lbPages
  lbPages.Clear;
  for I := 0 to pgNotebook.PageCount - 1 do
    for Kind in pgNotebook.Page[I].HelpKeyword.Split(['|']) do
      if (Kind = '*') or (Kind = AServer.Kind) then
        lbPages.Items.AddObject(pgNotebook.Page[I].Hint, pgNotebook.Page[I]);
  lbPages.ItemIndex := Min(0, lbPages.Count - 1);
  lbPagesClick(lbPages); // navigate to the first page

  // General
  edName.Text := AServer.Name;
  mmDescription.Text := AServer.Description;

  // Props
  if AServer.Kind = 'bedrock' then
    Props := TServerProperties.Create(spDefaultsBedrock)
  else if AServer.Kind = 'java' then
    Props := TServerProperties.Create(spDefaultsJava)
  else                                            
    Props := TServerProperties.Create('');

  with Props do
    try
      Path := IncludeTrailingPathDelimiter(AServer.Path) + spPathProperties;
      if FileExists(Path) then
        LoadFromFile(Path);

      cbLevelType.Text := ReadString('level-type');
      edLevelSeed.Text := ReadString('level-seed');
      cbLevelName.Text := ReadString('level-name');
    finally
      Free;
    end;
end;

procedure TdlgServerProperties.Save(AServer: TOrmServerEntry);
var
  Path: string;
  Props: TServerProperties;
begin
  // General
  AServer.Name := edName.Text;
  AServer.Description := mmDescription.Text;

  // Db
  Server.Orm.Update(AServer);

  // Props
  if AServer.Kind = 'bedrock' then
    Props := TServerProperties.Create(spDefaultsBedrock)
  else if AServer.Kind = 'java' then
    Props := TServerProperties.Create(spDefaultsJava)
  else
    Props := TServerProperties.Create('');

  with Props do
    try
      WriteString('level-type', cbLevelType.Text);
      WriteString('level-seed', edLevelSeed.Text);
      WriteString('level-name', cbLevelName.Text);

      Optimize();

      ForceDirectories(AServer.Path);
      Path := IncludeTrailingPathDelimiter(AServer.Path) + spPathProperties;
      SaveToFile(Path);
    finally
      Free;
    end;
end;

end.

