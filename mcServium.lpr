program mcServium;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, anchordockpkg, frmMainForm, uDatabase, uExamples, dlgServerProps,
  uMinecraft, uJRE, frmServerLog, uProcess, uRCON, uServer, dlgJavaPicker,
  uVersions, dlgDownload, uIconMap;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TmcServiumMain, mcServiumMain);
  Application.Run;
end.

