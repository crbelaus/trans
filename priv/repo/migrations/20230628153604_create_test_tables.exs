defmodule Trans.Repo.Migrations.CreateTestTables do
  use Ecto.Migration

  def change do
    create table(:default_translation_container) do
      add :content, :string
      add :translations, :map
    end

    create table(:custom_translation_container) do
      add :content, :string
      add :transcriptions, :map
    end
  end
end
