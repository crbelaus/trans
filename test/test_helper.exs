Trans.Repo.start_link()

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Trans.Repo, :manual)
