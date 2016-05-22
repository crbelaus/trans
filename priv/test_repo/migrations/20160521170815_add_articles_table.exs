defmodule Trans.TestRepo.Migrations.AddArticlesTable do
  use Ecto.Migration

  def change do
    create table(:articles) do
      add :title, :string
      add :body, :string
      add :translations, :map
    end
  end
end
