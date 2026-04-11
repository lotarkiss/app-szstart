CREATE TABLE servers (
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL CHECK(kind IN ('java','bedrock','rcon')),
  path TEXT NOT NULL,
  name TEXT,
  description TEXT,
  protected INTEGER NOT NULL DEFAULT 0,
  args TEXT
);

CREATE TABLE java_opts (
  server_id TEXT PRIMARY KEY,
  jre_path TEXT NOT NULL,
  jar_name TEXT NOT NULL,
  jvm_xms INTEGER NOT NULL,
  jvm_xmx INTEGER NOT NULL,
  jvm_args TEXT NOT NULL,
  FOREIGN KEY(server_id) REFERENCES servers(id) ON DELETE CASCADE
);

CREATE TABLE bedrock_opts (
  server_id TEXT PRIMARY KEY,
  FOREIGN KEY(server_id) REFERENCES servers(id) ON DELETE CASCADE
);

CREATE TABLE rcon_opts (
  server_id TEXT PRIMARY KEY,
  host TEXT NOT NULL,
  port INTEGER NOT NULL,
  username TEXT NOT NULL,
  password_enc BLOB NOT NULL,
  nonce BLOB NOT NULL,
  FOREIGN KEY(server_id) REFERENCES servers(id) ON DELETE CASCADE
);