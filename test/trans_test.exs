defmodule TransTest do
  use ExUnit.Case

  alias Trans.Article
  alias Trans.TestRepo
  alias Trans.Translator
  doctest Trans

  setup_all do
    attrs_wo_translations = %{
      title: "Title of the article without translations",
      body: "Body of the article without translations"
    }
    attrs_w_translations = %{
      title: "Title of the article with translations",
      body: "Body of the article with translations",
      translations: %{
        "es": %{"title": "title ES", "body": "body ES"},
        "fr": %{"title": "title FR", "body": "body FR"}
      }
    }
    TestRepo.insert! Article.changeset(%Article{}, attrs_wo_translations)
    TestRepo.insert! Article.changeset(%Article{}, attrs_w_translations)
    :ok
  end

  test "find article translated to ES" do
    matches = Article |> Article.with_translations(:es) |> TestRepo.all
    assert Enum.count(matches) == 1
  end

  test "find (non existant) article translated to DE" do
    matches = Article |> Article.with_translations(:de) |> TestRepo.all
    assert Enum.empty?(matches)
  end

  test "find article by translated title" do
    matches = Article
    |> Article.with_translation(:fr, :title, "title FR")
    |> TestRepo.all
    assert Enum.count(matches) == 1
  end

  test "find (non existant) article by translated title" do
    matches = Article
    |> Article.with_translation(:fr, :title, "title ES")
    |> TestRepo.all
    assert Enum.empty?(matches)
  end

  test "find article by translated body using case-sensitive pattern" do
    matches = Article
    |> Article.with_translation(:es, :body, "%ES", type: :like)
    |> TestRepo.all
    assert Enum.count(matches) == 1
  end

  test "find article by translated body using wrong pattern" do
    matches = Article
    |> Article.with_translation(:es, :body, "%es", type: :like)
    |> TestRepo.all
    assert Enum.empty?(matches)
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
    assert Translator.translate(article, :body, locale: :fr) == "body FR"
  end

  test "translate existing attribute to non-existing locale fallbacks to default" do
    article = Article
    |> Article.with_translation(:es, :body, "%es", type: :ilike)
    |> TestRepo.one
    assert Translator.translate(article, :body, locale: :uk) == "Body of the article with translations"
  end

  test "raise KeyError when translating non-existing attribute" do
    article = Article
    |> Article.with_translation(:es, :body, "%es", type: :ilike)
    |> TestRepo.one
    assert_raise KeyError, fn ->
      Translator.translate(article, :wadus, locale: :uk)
    end
  end

end
