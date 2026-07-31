unit uJRE;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Generics.Collections
  {$IFDEF UNIX}
  , BaseUnix
  {$ENDIF}
  ;

type

  { TJavaBinaries }

  TJavaBinaries = class(specialize TObjectDictionary<string, TStringList>)
  public
    function ToString: {$ifdef FPC_HAS_FEATURE_ANSISTRINGS}ansistring{$else FPC_HAS_FEATURE_ANSISTRINGS}shortstring{$endif FPC_HAS_FEATURE_ANSISTRINGS}; override;
  end;

function FindJavaBinaries(): TJavaBinaries;

implementation

uses Process;

function FindJavaBinaries(): TJavaBinaries;
const
  PlatformPaths: array of string = (
    {$IF defined(MSWINDOWS)}
       'C:\Program Files',
       'C:\Program Files (x86)',
       '~\AppData\Local',                     // Vista+
       '~\Local Settings\Application Data',   // 2000/XP
       '~\scoop',
       '~\.sdkman'
    {$ELSEIF defined(DARWIN)}
      '/Library/Java/JavaVirtualMachines/',
      '/System/Library/Java/',
      '/usr/local/',
      '/opt/homebrew/',
      '/opt/',
      '~/.sdkman/'
    {$ELSE}
      '/usr/lib/jvm/',
      '/usr/java/',
      '/opt/',
      '/usr/local/',
      '~/.sdkman/',
      '~/.jdks/',
      '~/.local/'
    {$ENDIF}
  );
var
  HomeDir, PlatRaw, PlatSubst, PathJava, VerStr: string;
  Paths, Version: TStringList;

  procedure FindJavaBinary(Path: string; List: TStringList);
  const
  {$IFDEF MSWINDOWS}
    BinaryName = 'java.exe';
  {$ELSE}
    BinaryName = 'java';
  {$ENDIF}
  var
    SearchResult: TSearchRec;
  begin
    Path := IncludeTrailingPathDelimiter(Path);
    if FindFirst(Path + AllFilesMask, faAnyFile, SearchResult) = 0 then
     begin
       repeat
         if (ExtractFileName(ExcludeTrailingPathDelimiter(Path)) = 'bin') and
            (SearchResult.Name = BinaryName)
            {$IFDEF UNIX} and
            (fpAccess(PChar(Path + BinaryName), X_OK) = 0)
            {$ENDIF} then begin
              List.Add(Path + BinaryName);
            end
         else if (SearchResult.Name <> '.') and (SearchResult.Name <> '..') and
            (SearchResult.Attr and faDirectory = faDirectory) then
             FindJavaBinary(Path + SearchResult.Name, List);
       until FindNext(searchResult) <> 0;
       FindClose(searchResult);
     end;
  end;

begin
  Result := TJavaBinaries.Create([doOwnsValues]);

  {$IFDEF MSWINDOWS}
  HomeDir := ExcludeTrailingPathDelimiter(GetEnvironmentVariable('USERPROFILE'));
  {$ELSE}
  HomeDir := ExcludeTrailingPathDelimiter(GetEnvironmentVariable('HOME'));
  {$ENDIF}

  Paths := TStringList.Create;
  try
    for PlatRaw in PlatformPaths do begin
      PlatSubst := ExcludeTrailingPathDelimiter(StringReplace(PlatRaw, '~', HomeDir, [rfReplaceAll]));
      if DirectoryExists(PlatSubst) then
        FindJavaBinary(PlatSubst, Paths);
    end;

    for PathJava in Paths do begin
      Version := TStringList.Create;
      try
        if RunCommand(PathJava + ' --version', VerStr) then
          Version.Text := VerStr;
      finally                       
        Result.Add(PathJava, Version);
      end;
    end;
  finally
    Paths.Free;
  end;
end;

{ TJavaBinaries }

function TJavaBinaries.ToString: {$ifdef FPC_HAS_FEATURE_ANSISTRINGS}ansistring{$else FPC_HAS_FEATURE_ANSISTRINGS}shortstring{$endif FPC_HAS_FEATURE_ANSISTRINGS};
var
  Key: string;
  Value: TStringList;
begin
  Result := '';
  for Key in Keys do
    if TryGetValue(Key, Value) then
      Result := Result + Key + LineEnding + Value.Text + LineEnding;
end;

end.

