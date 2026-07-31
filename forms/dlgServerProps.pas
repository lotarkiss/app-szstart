unit dlgServerProps;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, ValEdit, Spin, Buttons, uDatabase, uJRE;

type

  { TdlgServerProperties }

  TdlgServerProperties = class(TForm)
    btnOK: TBitBtn;
    btnCancel: TBitBtn;
    btnMove: TButton;
    btnOpen: TButton;
    btnVeClear: TButton;
    btnVeAdd: TButton;
    btnVeDelete: TButton;
    btnJava: TButton;
    bvIcon1: TBevel;
    cbEula: TCheckBox;
    cbHardcore: TCheckBox;
    cbLevelName: TComboBox;
    cbLevelType: TComboBox;
    cbOnlineMode: TCheckBox;
    cbGameMode: TComboBox;
    cbDifficulty: TComboBox;
    cbForceGMode: TCheckBox;
    cbSpawnAnimals: TCheckBox;
    cbGenStruct: TCheckBox;
    cbSpawnMonsters: TCheckBox;
    cbSpawnNPCs: TCheckBox;
    cbAllowNether: TCheckBox;
    edGenSettings: TEdit;
    edJava: TEdit;
    edLevelSeed: TEdit;
    edName: TEdit;
    gbJavaOnly2: TGroupBox;
    gbLevel: TGroupBox;
    gbEntry: TGroupBox;
    gbAdvanced: TGroupBox;
    gbJava: TGroupBox;
    gbServer: TGroupBox;
    gbGameplay: TGroupBox;
    gbNetwork: TGroupBox;
    gbJavaOnly1: TGroupBox;
    lbGenSettings: TLabel;
    lbSpawnProt: TLabel;
    lbGameMode: TLabel;
    lbDifficulty: TLabel;
    lbMaxPlayers: TLabel;
    lbEula1: TLabel;
    lbEula2: TLabel;
    lbEula3: TLabel;
    lbMotd: TLabel;
    lbPathTitle: TLabel;
    lbPath: TLabel;
    lbViewDistance: TLabel;
    lbXms: TLabel;
    lbXmx: TLabel;
    lbJREVersion: TLabel;
    lbJVM: TLabel;
    lbInfoSeedType: TLabel;
    lbJava: TLabel;
    lbPlaceholder1: TLabel;
    lbLevelName: TLabel;
    lbLevelSeed: TLabel;
    lbLevelType: TLabel;
    lbName: TLabel;
    lbDescription: TLabel;
    lbPages: TListBox;
    mmJVM: TMemo;
    mmDescription: TMemo;
    mmMotd: TMemo;
    pnSpawnProt: TPanel;
    pgNetwork: TPage;
    pgGameplay: TPage;
    pgServer: TPage;
    pnJavaXm: TPanel;
    pnJava: TPanel;
    pgJava: TPage;
    pnAdvanced: TPanel;
    pgAdvanced: TPage;
    pgWorld: TPage;
    pgGeneral: TPage;
    pgNotebook: TNotebook;
    pnBottom: TPanel;
    seViewDistance: TSpinEdit;
    seXms: TSpinEdit;
    seXmx: TSpinEdit;
    seMaxPlayers: TSpinEdit;
    seSpawnProt: TSpinEdit;
    spSplitter: TSplitter;
    veAdvanced: TValueListEditor;
    procedure btnOpenClick(Sender: TObject);
    procedure btnVeAddClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure lbPagesClick(Sender: TObject);
  public
    procedure Load(AServer: TOrmServerEntry);
    procedure Save(AServer: TOrmServerEntry);
  end;

var
  dlgServerProperties: TdlgServerProperties;

implementation

uses Math, uMinecraft, LclIntf;

resourcestring
  dlgPropsCaption = '%s properties';
  veDefaultKeyFormat = 'key%d';      
  veDefaultValFormat = 'value%d';

  dlgVeAddKeyCaption = 'Add custom key';
  dlgVeAddKeyNameLbl = 'Enter the name of the &custom key:';
  dlgVeAddKeyValLbl  = 'Enter the &value of the custom key:';

  dlgVeDelKeyText    = 'Are you sure?';

const
  urlMojangLicense   = 'https://aka.ms/MinecraftEULA';
  keyMotd: array [boolean] of string = ('server-name', 'motd');

{$R *.lfm}

{ TdlgServerProperties }

procedure TdlgServerProperties.lbPagesClick(Sender: TObject);
begin
  if lbPages.ItemIndex = -1 then
    pgNotebook.PageIndex := -1
  else
    pgNotebook.PageIndex := (lbPages.Items.Objects[lbPages.ItemIndex] as TPage).PageIndex;
end;

procedure TdlgServerProperties.btnVeAddClick(Sender: TObject);
var
  Result: array of string;
begin
  SetLength(Result, 2);
  Result[0] := format(veDefaultKeyFormat, [veAdvanced.Strings.Count]);
  Result[1] := format(veDefaultValFormat, [veAdvanced.Strings.Count]);
  case (Sender as TComponent).Tag of
    1: if InputQuery(
            dlgVeAddKeyCaption,
            [
              dlgVeAddKeyNameLbl,
              dlgVeAddKeyValLbl
            ],
            Result) and (Result[0] <> '') then
         veAdvanced.Strings.Add(Result[0] + '=' + Result[1]);
    2: if (veAdvanced.Row <> -1) and
          (MessageDlg(dlgVeDelKeyText,
            mtConfirmation, [mbYes, mbNo], 0, mbNo) = mrYes) then
         veAdvanced.DeleteRow(veAdvanced.Row);
    3: if MessageDlg(dlgVeDelKeyText,
            mtConfirmation, [mbYes, mbNo], 0, mbNo) = mrYes then
         veAdvanced.Clear;
    else
      raise Exception.Create('Operation not implemented');
  end;
end;

procedure TdlgServerProperties.FormResize(Sender: TObject);
begin
  lbPages.Constraints.MaxWidth := ClientWidth * 3 div 10;
  lbPages.Constraints.MinWidth := ClientWidth * 1 div 10;
end;

procedure TdlgServerProperties.btnOpenClick(Sender: TObject);
begin
  case (Sender as TComponent).Tag of
    1: OpenDocument(ExcludeTrailingPathDelimiter(lbPath.Caption));
    2: OpenURL(urlMojangLicense);
    else
      raise Exception.Create('Operation not implemented');
  end;
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
  lbPath.Caption := AServer.Path;

  // Java
  edJava.Text := AServer.java_jrePath;
  lbJREVersion.Caption := GetJavaVersion(AServer.java_jrePath);
  seXms.Value := AServer.java_jvmXMS;
  seXmx.Value := AServer.java_jvmXMX;
  mmJVM.Lines.Text := AServer.java_jvmArgs;

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

      // Server
      mmMotd.Text          := ReadString(keyMotd[AServer.Kind = 'java'], true);
      cbOnlineMode.Checked := ReadBoolean('online-mode', true);
      seMaxPlayers.Value   := ReadInteger('max-players', true);

      // Gameplay
      cbGameMode.Text      := ReadString('gamemode', true);
      cbDifficulty.Text    := ReadString('difficulty', true);
      cbForceGMode.Checked := ReadBoolean('force-gamemode', true);
      gbJavaOnly1.Visible := AServer.Kind = 'java';
      cbHardcore.Enabled  := gbJavaOnly1.Visible;
      if gbJavaOnly1.Visible then begin
        cbSpawnAnimals.Checked  := ReadBoolean('spawn-animals', true);
        cbSpawnMonsters.Checked := ReadBoolean('spawn-monsters', true);
        cbSpawnNPCs.Checked     := ReadBoolean('spawn-npcs', true);
        seSpawnProt.Value       := ReadInteger('spawn-protection', true);
        cbHardcore.Checked      := ReadBoolean('hardcore', true);   
        cbAllowNether.Checked   := ReadBoolean('allow-nether', true);
      end;

      // World
      cbLevelType.Text := ReadString('level-type', true);
      edLevelSeed.Text := ReadString('level-seed', true);
      cbLevelName.Text := ReadString('level-name', true);
      gbJavaOnly2.Visible := gbJavaOnly1.Visible;
      if gbJavaOnly2.Visible then begin
        edGenSettings.Text  := ReadString('generator-settings', true);
        cbGenStruct.Checked := ReadBoolean('generate-structures', true);
      end;

      // Network
      seViewDistance.Value := ReadInteger('view-distance', true);

      veAdvanced.Strings.Clear();
      veAdvanced.Strings.AddStrings(Props);
    finally
      Free;
    end;

  with TServerProperties.Create('') do
    try
      Path := IncludeTrailingPathDelimiter(AServer.Path) + spPathEula;
      if FileExists(Path) then
        LoadFromFile(Path);

      // Server & Gameplay
      cbEula.Checked := ReadBoolean('eula', true);
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
  AServer.Path := lbPath.Caption;

  // Java
  AServer.java_jrePath := edJava.Text;
  AServer.java_jvmXMS  := seXms.Value;
  AServer.java_jvmXMX  := seXmx.Value;
  AServer.java_jvmArgs := mmJVM.Lines.Text;

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
      AddStrings(veAdvanced.Strings);

      // General
      WriteString(keyMotd[AServer.Kind = 'java'], mmMotd.Text);
      WriteBoolean('online-mode', cbOnlineMode.Checked);
      WriteInteger('max-players', seMaxPlayers.Value);

      // Gameplay
      WriteString('gamemode', cbGameMode.Text);
      WriteString('difficulty', cbDifficulty.Text);
      WriteBoolean('force-gamemode', cbForceGMode.Checked);
      if gbJavaOnly1.Visible then begin
        WriteBoolean('spawn-animals', cbSpawnAnimals.Checked);
        WriteBoolean('spawn-monsters', cbSpawnMonsters.Checked);
        WriteBoolean('spawn-npcs', cbSpawnNPCs.Checked);
        WriteInteger('spawn-protection', seSpawnProt.Value);
        WriteBoolean('hardcore', cbHardcore.Checked);
        WriteBoolean('allow-nether', cbAllowNether.Checked);
      end;

      // World
      WriteString('level-type', cbLevelType.Text);
      WriteString('level-seed', edLevelSeed.Text);
      WriteString('level-name', cbLevelName.Text);
      if gbJavaOnly2.Visible then begin
        WriteString('generator-settings', edGenSettings.Text);
        WriteBoolean('generate-structures', cbGenStruct.Checked);
      end;

      // Network
      WriteInteger('view-distance', seViewDistance.Value);

      Optimize();

      ForceDirectories(AServer.Path);
      Path := IncludeTrailingPathDelimiter(AServer.Path) + spPathProperties;
      SaveToFile(Path);
    finally
      Free;
    end;

  with TServerProperties.Create('') do
    try
      Path := IncludeTrailingPathDelimiter(AServer.Path) + spPathEula;
      if FileExists(Path) then
        LoadFromFile(Path);

      // Server & Gameplay
      WriteBoolean('eula', cbEula.Checked);
    finally
      Free;
    end;
end;

end.

