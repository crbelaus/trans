use Mix.Config

config :trans, Trans.Repo,
  username: "postgres",
  password: "postgres",
  database: "trans_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  log: false
