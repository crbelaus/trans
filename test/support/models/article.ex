defmodule Trans.Article do
  use Ecto.Schema

  schema "articles" do
    field :title, :string
    field :body, :string
    field :translations, :map
  end

end
