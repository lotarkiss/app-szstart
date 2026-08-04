unit dlgDownload;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  ExtCtrls, Buttons;

type

  { TdlgDownloader }

  TdlgDownloader = class(TForm)
    BitBtn1: TBitBtn;
    btnDownload: TButton;
    cbKind: TComboBox;
    lbVersions: TLabel;
    lbKind: TLabel;
    lbFilename: TLabel;
    lbTarget: TLabel;
    lbxVersions: TListBox;
    pbProgress: TProgressBar;
    procedure btnDownloadClick(Sender: TObject);
    procedure cbKindChange(Sender: TObject);
    procedure DisableClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure lbxVersionsClick(Sender: TObject);
  private
  public
    procedure SetData(const AKind, APath: string);
    procedure OnProgress(Sender: TObject; const ContentLength, CurrentPos: Int64);
  end;

var
  dlgDownloader: TdlgDownloader;

implementation

uses Math, uVersions, ssockets, sslsockets, opensslsockets, fphttpclient;

resourcestring
  dlgDownloadSuccessText   = 'The file (%s) was downloaded successfully.';
  dlgDownloadAlreadyExists = 'The file (%s) is already exists. Overwrite?';

{$R *.lfm}

{ TdlgDownloader }

procedure TdlgDownloader.lbxVersionsClick(Sender: TObject);
begin
  btnDownload.Enabled := (cbKind.ItemIndex <> -1) and (lbxVersions.ItemIndex <> -1);
  if btnDownload.Enabled then
    lbTarget.Caption :=
      (cbKind.Items.Objects[cbKind.ItemIndex] as TUrlSourceFactory).GetFileName(
        lbxVersions.Items[lbxVersions.ItemIndex])
  else
    lbTarget.Caption := '';
end;

procedure TdlgDownloader.SetData(const AKind, APath: string);
var
  P: TUrlSourceDictionary.TDictionaryPair;
  D: TUrlSourceDictionary;
begin
  lbTarget.Hint := IncludeTrailingPathDelimiter(APath);

  if AKind = 'java' then
    D := UrlJava
  else if AKind = 'bedrock' then
    D := UrlBedrock
  else begin
    cbKind.Clear;
    lbxVersions.Clear;
    lbTarget.Caption := '';
    btnDownload.Enabled := false;
    exit;
  end;

  with cbKind.Items do begin
    Clear;
    for P in D do
      AddObject(P.Key, P.Value);
  end;

  cbKind.ItemIndex := Min(0, cbKind.Items.Count - 1);
  cbKindChange(Self);
end;

procedure TdlgDownloader.OnProgress(Sender: TObject; const ContentLength,
  CurrentPos: Int64);
begin
  Application.ProcessMessages;
  pbProgress.Max := Int64Rec(ContentLength).Lo;
  pbProgress.Position := Int64Rec(CurrentPos).Lo;
end;

procedure TdlgDownloader.cbKindChange(Sender: TObject);
begin
  lbxVersions.Clear;

  if cbKind.ItemIndex <> -1 then
    with cbKind.Items.Objects[cbKind.ItemIndex] as TUrlSourceFactory do begin
     Refresh();
     lbxVersions.Items.Assign(Versions);
     lbxVersions.ItemIndex := lbxVersions.Items.IndexOf(Latest);
     lbxVersionsClick(Self);
    end;
end;

procedure TdlgDownloader.DisableClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction := caNone;
end;

procedure TdlgDownloader.btnDownloadClick(Sender: TObject);
var
  Url, Filename: string;
begin
  if (cbKind.ItemIndex = -1) or (lbxVersions.ItemIndex = -1) then
    exit;

  FileName := lbTarget.Hint + lbTarget.Caption;
  if FileExists(FileName) then
    if MessageDlg(format(dlgDownloadAlreadyExists, [lbTarget.Caption]),
         mtConfirmation, [mbYes, mbNo], 0, mbNo) <> mrYes then
      exit;
                           
  OnClose := @DisableClose;
  Enabled := false;
  try
    Url := (cbKind.Items.Objects[cbKind.ItemIndex] as TUrlSourceFactory).GetUrl(
          lbxVersions.Items[lbxVersions.ItemIndex]);

    with TFPHTTPClient.Create(nil) do
      try
        OnDataReceived := @OnProgress;
        Get(Url, FileName);
        ShowMessage(format(dlgDownloadSuccessText, [lbTarget.Caption]));
        ModalResult := mrOK;
      finally
        Free;
      end;
  finally                  
    OnClose := nil;
    Enabled := true;
  end;
end;

end.

