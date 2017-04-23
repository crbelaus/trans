defmodule Trans.Comment do
  @moduledoc false

  use Ecto.Schema
  use Trans, translates: [:comment], container: :transcriptions

  import Ecto.Changeset

  schema "comments" do
    field :comment, :string
    field :transcriptions, :map
    belongs_to :article, Trans.Article
  end

  def changeset(comment, params \\ %{}) do
    comment
    |> cast(params, [:comment, :transcriptions])
    |> validate_required([:comment])
  end
end
