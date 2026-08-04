unit uMinecraft;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

const
  spDefaultsJava    = 'SERVER-JAVA';
  spDefaultsBedrock = 'SERVER-BEDROCK';

  spPathProperties  = 'server.properties';  
  spPathEula        = 'eula.txt';
  spPathIcon        = 'server-icon.png';

type

  { TServerProperties }

  TServerProperties = class(TStringList)
  private
    Defaults: TStringList;
  public
    class function UnescapeString(const AText: string): string;
    class function EscapeString(const AText: string): string;

    function ReadString(const AField: string; const ReadAndDelete: boolean): string;
    function ReadBoolean(const AField: string; const ReadAndDelete: boolean): boolean;
    function ReadInteger(const AField: string; const ReadAndDelete: boolean): integer;
    function ReadFloat(const AField: string; const ReadAndDelete: boolean): single;

    procedure WriteString(const AField: string; const AValue: string);
    procedure WriteBoolean(const AField: string; const AValue: boolean);
    procedure WriteInteger(const AField: string; const AValue: integer);
    procedure WriteFloat(const AField: string; const AValue: single);

    procedure Optimize();

    constructor Create(const ADefValues: string = ''); reintroduce;
    destructor Destroy; override;
  end;

implementation

const
  propsSpecialChar: array of char = (':'); // it seems these are prepended with \

{ TServerProperties }

class function TServerProperties.UnescapeString(const AText: string): string;
var
  C: char;
begin
  Result := AText;
  for C in propsSpecialChar do
    Result := StringReplace(Result, '\' + C, C, [rfReplaceAll]);
end;

class function TServerProperties.EscapeString(const AText: string): string;
var
  C: char;
begin
  Result := AText;
  for C in propsSpecialChar do
    Result := StringReplace(Result, C, '\' + C, [rfReplaceAll]);
end;

function TServerProperties.ReadString(const AField: string;
  const ReadAndDelete: boolean): string;
begin
  if IndexOfName(AField) = -1 then
    Result := UnescapeString(Defaults.Values[AField])
  else begin
    Result := UnescapeString(Self.Values[AField]);

    if ReadAndDelete then // so we can dump to a table every unused entry...
      Self.Delete(IndexOfName(AField));
  end;
end;

function TServerProperties.ReadBoolean(const AField: string;
  const ReadAndDelete: boolean): boolean;
var
  S: string;
begin
  S      := ReadString(AField, ReadAndDelete);
  Result := (LowerCase(S) = 'true') or (S = '1');
end;

function TServerProperties.ReadInteger(const AField: string;
  const ReadAndDelete: boolean): integer;
begin
  if not TryStrToInt(ReadString(AField, ReadAndDelete), Result) then
    Result := 0;
end;

function TServerProperties.ReadFloat(const AField: string;
  const ReadAndDelete: boolean): single;
begin
  if not TryStrToFloat(ReadString(AField, ReadAndDelete), Result) then
    Result := 0;
end;

procedure TServerProperties.WriteString(const AField: string;
  const AValue: string);
begin
  Values[AField] := EscapeString(AValue);
end;

procedure TServerProperties.WriteBoolean(const AField: string;
  const AValue: boolean);
const
  boolNames: array [boolean] of string = ('false', 'true');
begin
  WriteString(AField, boolNames[AValue]);
end;

procedure TServerProperties.WriteInteger(const AField: string;
  const AValue: integer);
begin
  WriteString(AField, IntToStr(AValue));
end;

procedure TServerProperties.WriteFloat(const AField: string;
  const AValue: single);
begin     
  WriteString(AField, FloatToStr(AValue));
end;

procedure TServerProperties.Optimize();
var
  I: integer;
begin
  for I := Count - 1 downto 0 do
    if (length(Strings[I]) = 0) or
       (Strings[I][1] = '#') or
       (ValueFromIndex[I] = Defaults.Values[Names[I]]) then
      Delete(I);
end;

constructor TServerProperties.Create(const ADefValues: string);
var
  Stream: TStream;
begin
  inherited Create;

  //Duplicates := dupIgnore;
  //Sorted     := true;

  Defaults := TStringList.Create;
    if ADefValues <> '' then begin
    Stream   := TResourceStream.Create(hInstance, ADefValues, RT_RCDATA);
    try
      Defaults.LoadFromStream(Stream);
    finally
      Stream.Free;
    end;
  end;
end;

destructor TServerProperties.Destroy;
begin
  Defaults.Free;
  inherited Destroy;
end;

end.

