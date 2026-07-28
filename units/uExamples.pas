unit uExamples;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uDatabase;

procedure InitExamples();

implementation

const
  JsonData: array [0..3] of string = (
    '{"Kind":"java","Path":"/servers/srv1","Name":"Survival","Description":"Main survival world","Protected":false,"Arguments":["--nogui"],"java_jrePath":"/usr/lib/jvm/java-17","java_jarName":"server.jar","java_jvmXMS":1024,"java_jvmXMX":4096,"java_jvmArgs":["-XX:UseG1GC"]}',
    '{"Kind":"java","Path":"/servers/srv2","Name":"Creative","Description":"Creative building server","Protected":false,"Arguments":[--nogui"],"java_jrePath":"/usr/lib/jvm/java-17","java_jarName":"server.jar","java_jvmXMS":2048,"java_jvmXMX":4096,"java_jvmArgs":["-XX:UseZGC"]}',
    '{"Kind":"bedrock","Path":"/servers/bed1","Name":"Bedrock Crossplay","Description":"Bedrock Edition Server","Protected":true}',
    '{"Kind":"rcon","Path":"/remote/rcon1","Name":"Remote Control","Description":"External RCON Endpoint","Protected":false}'
  );

procedure InitExamples();
var
  Json: string;
  Item: TOrmServerEntry;
begin
  Item := TOrmServerEntry.Create();
  try
    with Item do
      for Json in JsonData do begin
        ClearProperties();
        FillFrom(Json);
        Server.Orm.Add(Item, true);
      end;
  finally
    Item.Free;
  end;
end;

end.

