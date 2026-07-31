unit dlgServerProps;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, ValEdit, uDatabase, uJRE;

type

  { TdlgServerProperties }

  TdlgServerProperties = class(TForm)
    btnCancel: TButton;
    btnOK: TButton;
    btnVeClear: TButton;
    btnVeAdd: TButton;
    btnVeDelete: TButton;
    cbLevelName: TComboBox;
    cbLevelType: TComboBox;
    edLevelSeed: TEdit;
    edName: TEdit;
    gbLevel: TGroupBox;
    gbEntry: TGroupBox;
    gbAdvanced: TGroupBox;
    lbInfoSeedType: TLabel;
    lbPlaceholder1: TLabel;
    lbLevelName: TLabel;
    lbLevelSeed: TLabel;
    lbLevelType: TLabel;
    lbName: TLabel;
    lbDescription: TLabel;
    lbPages: TListBox;
    mmDescription: TMemo;
    pnAdvanced: TPanel;
    pgAdvanced: TPage;
    pgWorld: TPage;
    pgGeneral: TPage;
    pgNotebook: TNotebook;
    pnBottom: TPanel;
    spSplitter: TSplitter;
    veAdvanced: TValueListEditor;
    procedure btnVeAddClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lbPagesClick(Sender: TObject);
    procedure pnBottomClick(Sender: TObject);
  public                                     
    JreBinaries: TJavaBinaries;
    procedure Load(AServer: TOrmServerEntry);
    procedure Save(AServer: TOrmServerEntry);
  end;

var
  dlgServerProperties: TdlgServerProperties;

implementation

uses Math, uMinecraft;

resourcestring
  dlgPropsCaption = '%s properties';
  veDefaultKeyFormat = 'key%d';      
  veDefaultValFormat = 'value%d';

  dlgVeAddKeyCaption = 'Add custom key';
  dlgVeAddKeyNameLbl = 'Enter the name of the &custom key:';
  dlgVeAddKeyValLbl  = 'Enter the &value of the custom key:';

  dlgVeDelKeyText    = 'Are you sure?';

{$R *.lfm}

{ TdlgServerProperties }

procedure TdlgServerProperties.lbPagesClick(Sender: TObject);
begin
  if lbPages.ItemIndex = -1 then
    pgNotebook.PageIndex := -1
  else
    pgNotebook.PageIndex := (lbPages.Items.Objects[lbPages.ItemIndex] as TPage).PageIndex;
end;

procedure TdlgServerProperties.pnBottomClick(Sender: TObject);
begin
  ShowMessage(JreBinaries.ToString);
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

procedure TdlgServerProperties.FormCreate(Sender: TObject);
begin
  JreBinaries := FindJavaBinaries();
end;

procedure TdlgServerProperties.FormDestroy(Sender: TObject);
begin
  JreBinaries.Free;
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

      cbLevelType.Text := ReadString('level-type', true);
      edLevelSeed.Text := ReadString('level-seed', true);
      cbLevelName.Text := ReadString('level-name', true);

      veAdvanced.Strings.Clear();
      veAdvanced.Strings.AddStrings(Props);
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
      AddStrings(veAdvanced.Strings);

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

