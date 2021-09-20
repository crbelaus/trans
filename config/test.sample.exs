use Mix.Config

config :trans, Trans.Repo,
  username: "postgres",
  password: "postgres",
  database: "trans_test",
  hostname: "localhost",
  port: 5432,
  pool: Ecto.Adapters.SQL.Sandbox,
  log: false
