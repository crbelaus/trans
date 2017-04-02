defmodule Trans.TestRepo.Migrations.AddCommentsTable do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :comment, :string
      add :article_id, references(:articles)
      add :transcriptions, :map
    end
  end
end
