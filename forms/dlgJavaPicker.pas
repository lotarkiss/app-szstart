unit dlgJavaPicker;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons, uJRE;

type

  { TdlgJavaPick }

  TdlgJavaPick = class(TForm)
    bvBottom: TBevel;
    btnCancel: TBitBtn;
    btnOK: TBitBtn;
    edPath: TEdit;
    lbJavaVersion: TLabel;
    lbJava: TLabel;
    lbPath: TLabel;
    lbxJava: TListBox;
    pnBottom: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lbxJavaClick(Sender: TObject);
  private

  public
    Binaries: TJavaBinaries;
  end;

var
  dlgJavaPick: TdlgJavaPick;

implementation

uses Math;

{$R *.lfm}

{ TdlgJavaPick }

procedure TdlgJavaPick.FormCreate(Sender: TObject);
var
  Pair: TJavaBinaries.TDictionaryPair;
begin
  Screen.Cursor := crHourGlass;
  try
    Binaries := uJRE.FindJavaBinaries();

    lbxJava.Items.Clear;
    for Pair in Binaries do
      lbxJava.Items.AddObject(Pair.Key, Pair.Value);

    lbxJava.ItemIndex := Min(lbxJava.Count - 1, 0);
    lbxJavaClick(Self);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TdlgJavaPick.FormDestroy(Sender: TObject);
begin
  Binaries.Free;
end;

procedure TdlgJavaPick.lbxJavaClick(Sender: TObject);
begin
  if lbxJava.ItemIndex <> -1 then begin
    lbJavaVersion.Caption := (lbxJava.Items.Objects[lbxJava.ItemIndex] as TStringList).Text;
    edPath.Text := lbxJava.Items[lbxJava.ItemIndex];
    btnOK.Enabled := true;
  end
  else begin
    lbJavaVersion.Caption := '';      
    edPath.Text := '';
    btnOK.Enabled := false;
  end;
end;

end.

