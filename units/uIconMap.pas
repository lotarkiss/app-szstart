unit uIconMap;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Controls, uDatabase, Generics.Collections;

type

  { TIconMap }

  TIconMap = class(specialize TObjectDictionary<string, TPortableNetworkGraphic>)
  private
    DebugColor: TColor;
  public
    constructor Create(); reintroduce;

    procedure DrawIcon(ACanvas: TCanvas; const ARect: TRect;
      const AEntry: TOrmServerEntry);

    function FindIcon(const AEntry: TOrmServerEntry; var G: TPortableNetworkGraphic): boolean;
    procedure UpdateIcon(const AEntry: TOrmServerEntry);
    procedure UpdateAll(const AList: IOrmServerEntries);   
    procedure UpdateMissing(const AList: IOrmServerEntries);
  end;

implementation

{ TIconMap }

constructor TIconMap.Create;
begin
  inherited Create([doOwnsValues]);
  DebugColor := random($FFFFFF + 1); // for debugging
end;

procedure TIconMap.DrawIcon(ACanvas: TCanvas; const ARect: TRect;
  const AEntry: TOrmServerEntry);
var
  G: TPortableNetworkGraphic;
begin
  if Assigned(AEntry) and TryGetValue(AEntry.UUID, G) then
    ACanvas.StretchDraw(ARect, G)
  else begin
    ACanvas.Brush.Color := DebugColor;
    ACanvas.FillRect(ARect);
  end;
end;

function TIconMap.FindIcon(const AEntry: TOrmServerEntry; var G: TPortableNetworkGraphic): boolean;
var
  Path: string;
begin
  Result := false;
  if not Assigned(AEntry) then
    exit;

  if not TryGetValue(AEntry.UUID, G) then begin
    Path := IncludeTrailingPathDelimiter(AEntry.Path) + 'server-icon.png';
    if FileExists(Path) then begin
      G := TPortableNetworkGraphic.Create;
      G.LoadFromFile(Path);
      Add(AEntry.UUID, G);
      Result := true;
    end;
  end;
end;

procedure TIconMap.UpdateIcon(const AEntry: TOrmServerEntry);
var
  G: TPortableNetworkGraphic;
begin
  if not Assigned(AEntry) then
    exit;

  if ContainsKey(AEntry.UUID) then
    Remove(AEntry.UUID);

  FindIcon(AEntry, G);
end;

procedure TIconMap.UpdateAll(const AList: IOrmServerEntries);
begin
  Clear;
  UpdateMissing(AList);
end;

procedure TIconMap.UpdateMissing(const AList: IOrmServerEntries);
var
  Entry: TOrmServerEntry;
  G: TPortableNetworkGraphic;
begin
  if not Assigned(AList) then
    exit;

  for Entry in AList do
    FindIcon(Entry, G);
end;

end.

