defmodule Trans.Article do
  use Ecto.Schema
  use Trans, translates: [:title, :body]

  import Ecto.Changeset

  @required_fields ~w(title body)
  @optional_fields ~w(translations)

  schema "articles" do
    field :title, :string
    field :body, :string
    field :translations, :map
  end

  def changeset(article, params \\ :empty) do
    article
    |> cast(params, @required_fields, @optional_fields)
  end

end
