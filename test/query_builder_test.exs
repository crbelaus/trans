alias Trans.Article
alias Trans.Comment
alias Trans.TestRepo, as: Repo

import Trans.Factory
import Trans.QueryBuilder
import Ecto.Query, only: [from: 2]

defmodule QueryBuilderTest do
  use ExUnit.Case

  setup_all do
    {:ok,
      translated_article: insert(:article),
      untranslated_article: insert(:article, translations: %{})
    }
  end

  test "should find only one article translated to ES" do
    count = Repo.one(from a in Article,
      where: not is_nil(translated(Article, a, :es)),
      select: count(a.id)
    )
    assert count == 1
  end

  test "should not find any article translated to DE" do
    count = Repo.one(from a in Article,
      where: not is_nil(translated(Article, a, :de)),
      select: count(a.id))
    assert count == 0
  end

  test "should use a custom translation container automaticalle",
  %{translated_article: article} do
    with comment <- hd(article.comments) do
      matches = Repo.all(from c in Comment,
        where: translated(Comment, c.comment, :fr) == ^comment.transcriptions["fr"]["comment"])
      assert Enum.count(matches) == 1
      assert hd(matches).id == comment.id
    end
  end

  test "should find an article by its FR title",
  %{translated_article: article} do
    matches = Repo.all(from a in Article,
      where: translated(Article, a.title, :fr) == ^article.translations["fr"]["title"])
    assert Enum.count(matches) == 1
    assert hd(matches).id == article.id
  end

  test "should not find an article by a non existant translation" do
    count = Repo.one(from a in Article,
      select: count(a.id),
      where: translated(Article, a.title, :es) == "FAKE TITLE")
    assert count == 0
  end

  test "should find an article by partial and case sensitive translation",
  %{translated_article: article} do
    first_words =
      article.translations["es"]["body"]
      |> String.split
      |> Enum.take(3)
      |> Enum.join(" ")
      |> Kernel.<>("%")
    matches = Repo.all(from a in Article,
      where: ilike(translated(Article, a.body, :es), ^first_words))
    assert Enum.count(matches) == 1
    assert hd(matches).id == article.id
  end

  test "should not find an article by incorrect case using case sensitive translation",
  %{translated_article: article} do
    first_words =
      article.translations["fr"]["body"]
      |> String.split
      |> Enum.take(3)
      |> Enum.join(" ")
      |> String.upcase
      |> Kernel.<>("%")
    count = Repo.one(from a in Article,
      select: count(a.id),
      where: like(translated(Article, a.body, :fr), ^first_words))
    assert count == 0
  end

  test "should find an article by incorrect case using case insensitive translation",
  %{translated_article: article} do
    first_words =
      article.translations["fr"]["body"]
      |> String.split
      |> Enum.take(3)
      |> Enum.join(" ")
      |> String.upcase
      |> Kernel.<>("%")
    matches = Repo.all(from a in Article,
      where: ilike(translated(Article, a.body, :fr), ^first_words))
    assert Enum.count(matches) == 1
    assert hd(matches).id == article.id
  end

  test "should find an article looking for one of its comments translations",
  %{translated_article: article} do
    with comment <- hd(article.comments).transcriptions["es"]["comment"] do
      matches = Repo.all(from a in Article,
        join: c in Comment, on: a.id == c.article_id,
        where: translated(Comment, c.comment, :es) == ^comment)

      assert Enum.count(matches) == 1
      assert hd(matches).id == article.id
    end
  end

  test "should find an article looking for a translation and one of its comments translations",
  %{translated_article: article} do
    with title <- article.translations["fr"]["title"],
         comment <- hd(article.comments).transcriptions["fr"]["comment"] do

      matches = Repo.all(from a in Article,
        join: c in Comment, on: a.id == c.article_id,
        where: translated(Article, a.title, :fr) == ^title,
        where: translated(Comment, c.comment, :fr) == ^comment)

      assert Enum.count(matches) == 1
      assert hd(matches).id == article.id
    end
  end

  test "should raise when adding conditions to an untranslatable field" do
    # Since the QueryBuilder errors are emitted during compilation, we do a
    # little trick to delay the compilation of the query until the test
    # is running, so we can catch the raised error.
    invalid_module = quote do
      defmodule TestWrongQuery do
        require Ecto.Query
        import Ecto.Query, only: [from: 2]

        def invalid_query do
          from a in Article,
            where: not is_nil(translated(Article, a.translations, :es))
        end
      end
    end

    assert_raise ArgumentError,
      "'Trans.Article' module must declare 'translations' as translatable",
      fn -> Code.eval_quoted(invalid_module) end
  end

  test "should allow passing the locale from a variable" do
    locale = :es
    articles = Repo.all(from a in Article,
      order_by: translated(Article, a.title, locale))
    assert Enum.any?(articles)
  end
end
