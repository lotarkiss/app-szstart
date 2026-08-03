unit uVersions;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ssockets, sslsockets, opensslsockets, fphttpclient, fpjson, Generics.Collections;

type

  { TUrlSourceFactory }

  TUrlSourceFactory = class abstract
  private
    FLatest: string;
    FVersions: TStrings;
  protected                 
    TargetData: TStringList; // store anything you want here in Refresh();
  public
    constructor Create; virtual; reintroduce;
    destructor Destroy; override;

    procedure Refresh; virtual; abstract;
    function GetUrl(const AVersion: string): string; virtual; abstract;
    class function Fetch(const AURL: string): TJSONData;

    property Versions: TStrings read FVersions;
    property Latest: string read FLatest;
  end;

  { TUrlVanillaFactory }

  TUrlVanillaFactory = class(TUrlSourceFactory)
  public
    procedure Refresh; override;
    function GetUrl(const AVersion: string): string; override;
  end;

  { TUrlBedrockFactory }

  TUrlBedrockFactory = class(TUrlSourceFactory)
  public
    procedure Refresh; override;
    function GetUrl(const AVersion: string): string; override;
  end;

type
  TUrlSourceDictionary = specialize TObjectDictionary<string, TUrlSourceFactory>;

var
  UrlSources: TUrlSourceDictionary;

implementation

{ TUrlSourceFactory }

constructor TUrlSourceFactory.Create;
begin
  inherited Create;
  FVersions  := TStringList.Create;
  TargetData := TStringList.Create;
end;

destructor TUrlSourceFactory.Destroy;
begin
  TargetData.Free;
  FVersions.Free;
  inherited Destroy;
end;

class function TUrlSourceFactory.Fetch(const AURL: string): TJSONData;
begin
  Result := GetJSON(TFPHTTPClient.SimpleGet(AURL));
end;

{$REGION 'smells like pain already...'}

{ TUrlVanillaFactory }

procedure TUrlVanillaFactory.Refresh;
const
  (*
    Just hoping it does not change every week or something...
  *)
  urlVanilla = 'https://launchermeta.mojang.com/mc/game/version_manifest_v2.json';
var
  I: integer;
  Json: TJSONData;
  jRoot: TJSONObject;
  jVers: TJSONArray;
begin
  Versions.Clear;
  TargetData.Clear;   
  FLatest := '';

  Json := Fetch(urlVanilla);
  try
    Assert(Json is TJSONObject, 'Bad endpoint.');
    jRoot          := Json as TJSONObject;
    FLatest        := jRoot.FindPath('latest.release').AsString;

    jVers          := jRoot.Arrays['versions'];
    for I := 0 to jVers.Count -1 do
      with jVers[I] as TJSONObject do
        if Strings['type'] = 'release' then begin
          TargetData.AddPair(Strings['id'], Strings['url']);
          Versions.Add(Strings['id']);
        end;
  finally
    Json.Free;
  end;
end;

function TUrlVanillaFactory.GetUrl(const AVersion: string): string;
var
  urlTarget: string;
  Json: TJSONData;
  jRoot: TJSONObject;
begin
  urlTarget := TargetData.Values[AVersion];
  if urlTarget <> '' then begin
    Json := Fetch(urlTarget);
    try
      jRoot  := Json as TJSONObject;
      Result := jRoot.FindPath('downloads.server.url').AsString;
    finally
      Json.Free;
    end;
  end
  else
    Result := '';
end;

{ TUrlBedrockFactory }

procedure TUrlBedrockFactory.Refresh;
const
  (*
     Ty, so much for this repo. <3
     https://github.com/kittizz/bedrock-server-downloads
  *)
  urlBedrock = 'https://raw.githubusercontent.com/kittizz/bedrock-server-downloads/main/bedrock-server-downloads.json';
var
  I: integer;
  AName: string;
  Json: TJSONData;
  jRoot, jReleases, jVersion, jUrl: TJSONObject;
const
  {$IF defined(MSWINDOWS)}
    binaryBlob = 'windows';
  {$ELSEIF defined(LINUX)}
    binaryBlob = 'linux';
  {$ENDIF}
begin
  {$IF defined(MSWINDOWS) or defined(LINUX)}
  Versions.Clear;
  TargetData.Clear;
  FLatest := '';

  Json := Fetch(urlBedrock);
  try
    Assert(Json is TJSONObject, 'Bad endpoint.');
    jRoot          := Json as TJSONObject;
    jReleases      := jRoot.Objects['release'];
    for I := 0 to jReleases.Count - 1 do begin
      AName    := jReleases.Names[I];
      jVersion := jReleases.Objects[AName];
      jUrl     := jVersion.Objects[binaryBlob];

      TargetData.AddPair(AName, jUrl.Strings['url']);
      Versions.Add(AName);
    end;

    if Versions.Count > 0 then
      FLatest := Versions[Versions.Count - 1];
  finally
    Json.Free;
  end;
  {$ELSE}
  Result := '';
  {$ENDIF}
end;

function TUrlBedrockFactory.GetUrl(const AVersion: string): string;
begin
  Result := TargetData.Values[AVersion];
end;

{$ENDREGION}

initialization
  UrlSources := TUrlSourceDictionary.Create([doOwnsValues]);
  UrlSources.Add('vanilla', TUrlVanillaFactory.Create);
  UrlSources.Add('bedrock', TUrlBedrockFactory.Create);

finalization
  UrlSources.Free;

end.

