defmodule Trans.TestCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      import Trans.TestCase
      import Ecto.Query

      alias Trans.Repo
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Trans.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end
end
