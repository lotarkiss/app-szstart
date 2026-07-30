unit uPlatform;

interface

uses SysUtils, Classes, Menus;

procedure UpdateMenuKeys(const AMenu: TMenuItem);
function GetHomePath(): string;
function GetAppDataPath(const CanCreate: boolean = false): string;

implementation

procedure UpdateMenuKeys(const AMenu: TMenuItem);
var
  I: integer;
begin
  {$IFNDEF DARWIN}
  AMenu.ShortCut := AMenu.ShortCutKey2;
  {$ENDIF}
  AMenu.ShortCutKey2 := 0;

  for I := 0 to AMenu.Count - 1 do
    UpdateMenuKeys(AMenu.Items[I]);
end;

function GetHomePath(): string;
begin
  {$IF defined(UNIX)}
    Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('HOME'));
  {$ELSEIF defined(MSWINDOWS)}
    Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('USERPROFILE'));
  {$ELSE}
    Result := ?;
  {$ENDIF}
end;

function GetAppDataPath(const CanCreate: boolean): string;
begin
  {$IF defined(DARWIN)}
    Result := GetHomePath() + 'Library/Application Support/com.lotarkiss.mcServerium/';
  {$ELSEIF defined(UNIX)}
    Result := GetHomePath() + '.local/share/mcServerium/';
  {$ELSEIF defined(MSWINDOWS)}
    Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('APPDATA')) + 'mcServerium/';
  {$ELSE}
    Result := ?;
  {$ENDIF}

  if CanCreate then
    ForceDirectories(Result);
end;

end.

