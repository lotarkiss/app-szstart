unit uExamples;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uDatabase;

procedure InitExamples();

implementation

const
  JsonData: array [0..3] of string = (
    '{"UUID":"{123e4567-e89b-12d3-a456-426614174000}","Kind":"java","Path":"/servers/srv1","Name":"Survival","Description":"Main survival world","Protected":false,"NetworkMode":"port_forwarded","Arguments":"--nogui","java_jrePath":"/usr/lib/jvm/java-17","java_jarName":"server.jar","java_jvmXMS":1024,"java_jvmXMX":4096,"java_jvmArgs":"-XX:UseG1GC"}',
    '{"UUID":"{123e4567-e89b-12d3-a456-426614174001}","Kind":"java","Path":"/servers/srv2","Name":"Creative","Description":"Creative building server","Protected":false,"NetworkMode":"upnp_static","Arguments":--nogui","java_jrePath":"/usr/lib/jvm/java-17","java_jarName":"server.jar","java_jvmXMS":2048,"java_jvmXMX":4096,"java_jvmArgs":"-XX:UseZGC"}',
    '{"UUID":"{123e4567-e89b-12d3-a456-426614174002}","Kind":"bedrock","Path":"/servers/bed1","Name":"Bedrock Crossplay","Description":"Bedrock Edition Server","Protected":true,"NetworkMode":"upnp_dynamic","bedrock_serverPath":"bedrock_server"}',
    '{"UUID":"{123e4567-e89b-12d3-a456-426614174003}","Kind":"rcon","Path":"/remote/rcon1","Name":"Remote Control","Description":"External RCON Endpoint","Protected":false,"NetworkMode":"tunnel"}'
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

