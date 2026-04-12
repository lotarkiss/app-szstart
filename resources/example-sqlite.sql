INSERT INTO servers (id, kind, path, name, description, protected, args)
VALUES
('srv1', 'java', '/servers/srv1', 'Survival', 'Main survival world', 0, '--nogui'),
('srv2', 'java', '/servers/srv2', 'Creative', 'Creative building server', 0, '--nogui'),
('bed1', 'bedrock', '/servers/bed1', 'Bedrock Crossplay', 'Bedrock edition server', 1, ''),
('rcon1', 'rcon', '/remote/rcon1', 'Remote Control', 'External RCON endpoint', 0, '');

INSERT INTO java_opts (
  server_id,
  jre_path,
  jar_name,
  jvm_xms,
  jvm_xmx,
  jvm_args
)
VALUES
('srv1', '/usr/lib/jvm/java-17', 'server.jar', 1024, 4096, '-XX:+UseG1GC'),
('srv2', '/usr/lib/jvm/java-17', 'server.jar', 2048, 4096, '-XX:+UseZGC');

INSERT INTO bedrock_opts (server_id)
VALUES
('bed1');

INSERT INTO rcon_opts (
  server_id,
  host,
  port,
  username,
  password_enc,
  nonce
)
VALUES
('rcon1', '127.0.0.1', 25575, 'admin', X'0011223344556677', X'8899AABBCCDDEEFF');