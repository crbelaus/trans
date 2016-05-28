defmodule Trans.Article do
  use Ecto.Schema
  use Trans, translates: [:title, :body], defaults: [container: :test_translation_container]

  import Ecto.Changeset

  @required_fields ~w(title body)
  @optional_fields ~w(test_translation_container)

  schema "articles" do
    field :title, :string
    field :body, :string
    field :test_translation_container, :map
  end

  def changeset(article, params \\ :empty) do
    article
    |> cast(params, @required_fields, @optional_fields)
  end

end
