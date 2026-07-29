unit uMinecraft;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

const
  spDefaultsJava    = 'SERVER-JAVA';
  spDefaultsBedrock = 'SERVER-BEDROCK';

  spPathProperties  = 'server.properties';
  spPathIcon        = 'server-icon.png';

type

  { TServerProperties }

  TServerProperties = class(TStringList)
  private
    Defaults: TStringList;
  public
    function ReadString(const AField: string): string;
    function ReadBoolean(const AField: string): boolean;
    function ReadInteger(const AField: string): integer;
    function ReadFloat(const AField: string): single;

    procedure WriteString(const AField: string; const AValue: string);
    procedure WriteBoolean(const AField: string; const AValue: boolean);
    procedure WriteInteger(const AField: string; const AValue: integer);
    procedure WriteFloat(const AField: string; const AValue: single);

    procedure Optimize();

    constructor Create(const ADefValues: string = ''); reintroduce;
    destructor Destroy; override;
  end;

implementation

{ TServerProperties }

function TServerProperties.ReadString(const AField: string): string;
begin
  if IndexOfName(AField) = -1 then
    Result := Defaults.Values[AField]
  else
    Result := Self.Values[AField];
end;

function TServerProperties.ReadBoolean(const AField: string): boolean;
var
  S: string;
begin
  S      := ReadString(AField);
  Result := (LowerCase(S) = 'true') or (S = '1');
end;

function TServerProperties.ReadInteger(const AField: string): integer;
begin
  Result := StrToInt(ReadString(AField));
end;

function TServerProperties.ReadFloat(const AField: string): single;
begin
  Result := StrToFloat(ReadString(AField));
end;

procedure TServerProperties.WriteString(const AField: string;
  const AValue: string);
begin
  Values[AField] := AValue;
end;

procedure TServerProperties.WriteBoolean(const AField: string;
  const AValue: boolean);
const
  boolNames: array [boolean] of string = ('false', 'true');
begin
  Values[AField] := boolNames[AValue];
end;

procedure TServerProperties.WriteInteger(const AField: string;
  const AValue: integer);
begin
  Values[AField] := IntToStr(AValue);
end;

procedure TServerProperties.WriteFloat(const AField: string;
  const AValue: single);
begin     
  Values[AField] := FloatToStr(AValue);
end;

procedure TServerProperties.Optimize();
var
  I: integer;
begin
  for I := Count - 1 downto 0 do
    if ValueFromIndex[I] = Defaults.Values[Names[I]] then
      Delete(I);
end;

constructor TServerProperties.Create(const ADefValues: string);
var
  Stream: TStream;
begin
  inherited Create;

  Duplicates := dupIgnore;
  Sorted     := true;

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

