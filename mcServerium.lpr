program mcServerium;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, frmMainForm, uDatabase, uExamples, dlgServerProps, uMinecraft;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TmcServeriumMain, mcServeriumMain);
  Application.CreateForm(TdlgServerProperties, dlgServerProperties);
  Application.Run;
end.

