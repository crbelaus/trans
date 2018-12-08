defmodule Trans.TestRepo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :trans,
    adapter: Ecto.Adapters.Postgres
end
