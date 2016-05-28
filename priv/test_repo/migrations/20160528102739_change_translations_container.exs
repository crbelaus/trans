defmodule Trans.TestRepo.Migrations.ChangeTranslationsContainer do
  use Ecto.Migration

  def change do
    rename table(:articles), :translations, to: :test_translation_container
  end
end
