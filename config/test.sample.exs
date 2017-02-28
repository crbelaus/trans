use Mix.Config

config :trans, Trans.TestRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "trans_test",
  hostname: "localhost",
  port: 5432
