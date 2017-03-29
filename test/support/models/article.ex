defmodule Trans.Article do
  use Ecto.Schema
  use Trans, translates: [:title, :body], container: :test_translation_container

  import Ecto.Changeset

  schema "articles" do
    field :title, :string
    field :body, :string
    field :test_translation_container, :map
  end

  def changeset(article, params \\ :empty) do
    article
    |> cast(params, [:title, :body, :test_translation_container])
    |> validate_required([:title, :body])
  end

end
