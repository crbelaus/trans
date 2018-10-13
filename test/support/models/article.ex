defmodule Trans.Article do
  @moduledoc false

  use Ecto.Schema
  use Trans, translates: [:title, :body]

  import Ecto.Changeset

  schema "articles" do
    field(:title, :string)
    field(:body, :string)
    field(:translations, :map)
    has_many(:comments, Trans.Comment)
  end

  def changeset(article, params \\ %{}) do
    article
    |> cast(params, [:title, :body, :translations])
    |> validate_required([:title, :body])
  end
end
