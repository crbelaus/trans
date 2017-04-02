defmodule Trans.Article do
  use Ecto.Schema
  use Trans, translates: [:title, :body]

  import Ecto.Changeset

  schema "articles" do
    field :title, :string
    field :body, :string
    field :translations, :map
  end

  def changeset(article, params \\ :empty) do
    article
    |> cast(params, [:title, :body, :translations])
    |> validate_required([:title, :body])
  end

end
