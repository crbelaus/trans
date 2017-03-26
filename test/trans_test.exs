alias Trans.Article
alias Trans.TestRepo
alias Trans.Translator

defmodule TransTest do
  use ExUnit.Case
  import Trans.Factory
  doctest Trans

  setup_all do
    attrs_wo_translations = %{
      title: "Title of the article without translations",
      body: "Body of the article without translations"
    }
    attrs_w_translations = %{
      title: "Title of the article with translations",
      body: "Body of the article with translations",
      test_translation_container: %{
        "es": %{"title": "title ES", "body": "body ES"},
        "fr": %{"title": "title FR", "body": "body FR"}
      }
    }
    TestRepo.insert! Article.changeset(%Article{}, attrs_wo_translations)
    TestRepo.insert! Article.changeset(%Article{}, attrs_w_translations)
    :ok
  end

  test "find article by translated body using case-insensitive pattern" do
    matches = Article
    |> Article.with_translation(:es, :body, "%es", type: :ilike)
    |> TestRepo.all
    assert Enum.count(matches) == 1
  end

  test "translate existing attribute" do
    article = Article
    |> Article.with_translation(:es, :body, "%es", type: :ilike)
    |> TestRepo.one
    assert Translator.translate(article, :fr, :body, container: :test_translation_container) == "body FR"
  end

  test "translate existing attribute to non-existing locale fallbacks to default" do
    article = Article
    |> Article.with_translation(:es, :body, "%es", type: :ilike)
    |> TestRepo.one
    assert Translator.translate(article, :uk, :body) == "Body of the article with translations"
  end

  test "raise KeyError when translating non-existing attribute" do
    article = Article
    |> Article.with_translation(:es, :body, "%es", type: :ilike)
    |> TestRepo.one
    assert_raise KeyError, fn ->
      Translator.translate(article, :wadus, locale: :uk)
    end
  end

  test "raise ArgumentError when querying by non-translatable attribute" do
    assert_raise ArgumentError, ~r/not declared as translatable/, fn ->
      Article
      |> Article.with_translation(:es, :fake_attribute, "I don't exist")
      |> TestRepo.one
    end
  end

end
