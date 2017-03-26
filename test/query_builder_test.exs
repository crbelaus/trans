alias Trans.Article
alias Trans.TestRepo, as: Repo
import Trans.Factory

defmodule QueryBuilderTest do
  use ExUnit.Case

  setup_all do
    {:ok,
      translated_article: insert(:article),
      untranslated_article: insert(:article, test_translation_container: %{}),
    }
  end

  test "should find only one article translated to ES" do
    matches =
      Article
      |> Article.with_translations(:es)
      |> Repo.all
    assert Enum.count(matches) == 1
  end

  test "should not find any article translated to DE" do
    matches =
      Article
      |> Article.with_translations(:de)
      |> Repo.all
    assert Enum.empty?(matches)
  end

  test "should find an article by its FR title",
  %{translated_article: article} do
    fr_title = article.test_translation_container["fr"]["title"]
    matches =
      Article
      |> Article.with_translation(:fr, :title, fr_title)
      |> Repo.all
    assert Enum.count(matches) == 1
    assert hd(matches).id == article.id
  end

  test "should not find an article by a non existant translation" do
    matches =
      Article
      |> Article.with_translation(:es, :title, "FAKE TITLE")
      |> Repo.all
    assert Enum.empty?(matches)
  end

  test "should find an article by partial and case sensitive translation",
  %{translated_article: article} do
    first_words =
      article.test_translation_container["es"]["body"]
      |> String.split
      |> Enum.take(3)
      |> Enum.join(" ")
    matches =
      Article
      |> Article.with_translation(:es, :body, "#{first_words}%", type: :like)
      |> Repo.all
    assert Enum.count(matches) == 1
    assert hd(matches).id == article.id
  end

  test "should not find an article by incorrect case using case sensitive translation",
  %{translated_article: article} do
    first_words =
      article.test_translation_container["fr"]["body"]
      |> String.split
      |> Enum.take(3)
      |> Enum.join(" ")
      |> String.upcase
    matches =
      Article
      |> Article.with_translation(:fr, :body, "#{first_words}%", type: :like)
      |> Repo.all
    assert Enum.empty?(matches)
  end

  test "should find an article by incorrect case using case insensitive translation",
  %{translated_article: article} do
    first_words =
      article.test_translation_container["fr"]["body"]
      |> String.split
      |> Enum.take(3)
      |> Enum.join(" ")
      |> String.upcase
    matches =
      Article
      |> Article.with_translation(:fr, :body, "#{first_words}%", type: :ilike)
      |> Repo.all
    assert Enum.count(matches) == 1
    assert hd(matches).id == article.id
  end
end
