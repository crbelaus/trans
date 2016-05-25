use Mix.Config

config :trans, Trans.TestRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "",
  database: "trans_test"
