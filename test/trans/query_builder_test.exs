defmodule Trans.QueryBuilderTest do
  use Trans.TestCase

  import Trans.QueryBuilder

  alias Trans.{Article, Book, Comment}

  setup do
    [
      translated_article: insert(:article),
      untranslated_article: insert(:article, translations: %{})
    ]
  end

  test "should find only one article translated to ES" do
    # Articles use nested structs for translations, this means that the translation container
    # allways has the locale keys, but they are "null" if empty.
    count =
      Repo.one(
        from(
          a in Article,
          where: not is_nil(translated(Article, a, :es)),
          select: count(a.id)
        )
      )

    assert count == 1
  end

  test "should not find any article translated to DE" do
    count =
      Repo.one(
        from(
          a in Article,
          where: not is_nil(translated(Article, a, :de)),
          select: count(a.id)
        )
      )

    assert count == 0
  end

  test "should find one article translated to ES falling back from DE" do
    query =
      from(
        a in Article,
        where: not is_nil(translated(Article, a, [:de, :es])),
        select: count(a.id)
      )

    count = Repo.one(query)

    assert count == 1
  end

  test "should find no article translated to DE falling back from RU since neither exist" do
    query =
      from(
        a in Article,
        where: not is_nil(translated(Article, a, [:ru, :de])),
        select: count(a.id)
      )

    count = Repo.one(query)

    assert count == 0
  end

  # This is an example where we use `NULLIF(value, 'null')` to
  # standardise on using SQL NULL in all cases where there is no data.
  test "that a valid locale that has no translations returns nil (not 'null')" do
    query =
      from(
        a in Book,
        where: is_nil(translated(Book, a, :it)),
        select: count(a.id)
      )

    count = Repo.one(query)

    assert count == 2
  end

  test "that a valid locale that has no translations returns nil for locale chain" do
    count =
      Repo.one(
        from(
          a in Book,
          where: is_nil(translated(Book, a, [:de, :it])),
          select: count(translated(Book, a, [:de, :it]))
        )
      )

    # Both rows return NULL and coun(column) doesn't unclude
    # rows where is_null(column)
    assert count == 0
  end

  test "that a valid locale that has no translations returns nil for dynamic locales" do
    count =
      Repo.one(
        from(
          a in Book,
          where: is_nil(translated(Book, a, Trans.Factory.locales(:it))),
          select: count(a.id)
        )
      )

    assert count == 2
  end

  test "should find all books falling back from DE since EN is default" do
    count =
      Repo.one(
        from(
          a in Book,
          where: not is_nil(translated(Book, a.title, [:de, :en])),
          select: count(a.id)
        )
      )

    assert count == 2
  end

  test "should find all books with dynamic fallback chain" do
    count =
      Repo.one(
        from(
          a in Book,
          where: not is_nil(translated(Book, a0.title, Trans.Factory.locales([:it, :es]))),
          select: count(a.id)
        )
      )

    assert count == 2
  end

  test "should select all books with dynamic fallback chain" do
    result =
      Repo.all(
        from(
          a in Book,
          select: translated_as(Book, a.title, Trans.Factory.locales([:it, :es])),
          where: not is_nil(translated(Book, a.title, Trans.Factory.locales([:it, :es])))
        )
      )

    assert length(result) == 2
  end

  test "should find all books falling back from DE since EN is default (using is_nil)" do
    count =
      Repo.one(
        from(
          a in Book,
          where: not is_nil(translated(Book, a.title, [:de, :en])),
          select: count(a.id)
        )
      )

    assert count == 2
  end

  test "select the translated (or base) column falling back from unknown DE to default EN",
       %{translated_article: translated_article, untranslated_article: untranslated_article} do
    result =
      Repo.all(
        from(
          a in Book,
          select: translated_as(Book, a.title, [:de, :en]),
          where: not is_nil(translated(Book, a.title, [:de, :en]))
        )
      )

    assert length(result) == 2
    assert [translated_article.title, untranslated_article.title]
  end

  test "select translations for a valid locale with no data should return the default",
       %{translated_article: translated_article, untranslated_article: untranslated_article} do
    result =
      Repo.all(
        from(
          a in Book,
          select: translated_as(Book, a.title, :it)
        )
      )

    assert result == [translated_article.title, untranslated_article.title]
  end

  test "select translations for a valid locale with no data should fallback to the default" do
    results =
      Repo.all(
        from(
          a in Book,
          select: translated_as(Book, a.title, [:it, :en])
        )
      )

    for result <- results do
      assert result =~ "Article title in English"
    end
  end

  test "should use a custom translation container automatically",
       %{translated_article: article} do
    with comment <- hd(article.comments) do
      matches =
        Repo.all(
          from(
            c in Comment,
            where: translated(Comment, c.comment, :fr) == ^comment.transcriptions["fr"]["comment"]
          )
        )

      assert Enum.count(matches) == 1
      assert hd(matches).id == comment.id
    end
  end

  test "should find an article by its FR title",
       %{translated_article: article} do
    matches =
      Repo.all(
        from(
          a in Article,
          where: translated(Article, a.title, :fr) == ^article.translations.fr.title
        )
      )

    assert Enum.count(matches) == 1
    assert hd(matches).id == article.id
  end

  test "should not find an article by a non existant translation" do
    count =
      Repo.one(
        from(
          a in Article,
          select: count(a.id),
          where: translated(Article, a.title, :es) == "FAKE TITLE"
        )
      )

    assert count == 0
  end

  # In the current released version this returns a count of 1 because
  # it doesn't return the default value (the base column) when the
  # article doesn't have a translated body. This would seem inconsistent
  # with the documentation.
  #
  # This implementation returns the base column in all cases which
  # I think is the original authors intent.

  test "should find an article by partial and case sensitive translation",
       %{translated_article: article} do
    first_words =
      article.translations.es.body
      |> String.split()
      |> Enum.take(3)
      |> Enum.join(" ")
      |> Kernel.<>("%")

    matches =
      Repo.all(
        from(
          a in Article,
          where: ilike(translated(Article, a.body, :es), ^first_words)
        )
      )

    assert Enum.count(matches) == 2
    assert hd(matches).id == article.id
  end

  test "should not find an article by incorrect case using case sensitive translation",
       %{translated_article: article} do
    first_words =
      article.translations.fr.body
      |> String.split()
      |> Enum.take(3)
      |> Enum.join(" ")
      |> String.upcase()
      |> Kernel.<>("%")

    count =
      Repo.one(
        from(
          a in Article,
          select: count(a.id),
          where: like(translated(Article, a.body, :fr), ^first_words)
        )
      )

    assert count == 0
  end

  # In the current released version this returns a count of 1 because
  # it doesn't return the default value (the base column) when the
  # article doesn't have a translated body. This would seem inconsistent
  # with the documentation.
  #
  # This implementation returns the base column in all cases which
  # I think is the original authors intent.

  test "should find an article by incorrect case using case insensitive translation",
       %{translated_article: article} do
    first_words =
      article.translations.fr.body
      |> String.split()
      |> Enum.take(3)
      |> Enum.join(" ")
      |> String.upcase()
      |> Kernel.<>("%")

    query =
      from(
        a in Article,
        where: ilike(translated(Article, a.body, :fr), ^first_words)
      )

    # IO.inspect Ecto.Adapters.SQL.to_sql(:all, Repo, query)

    matches = Repo.all(query)

    assert Enum.count(matches) == 2
    assert hd(matches).id == article.id
  end

  test "should find an article looking for one of its comments translations",
       %{translated_article: article} do
    with comment <- hd(article.comments).transcriptions["es"]["comment"] do
      matches =
        Repo.all(
          from(
            a in Article,
            join: c in Comment,
            on: a.id == c.article_id,
            where: translated(Comment, c.comment, :es) == ^comment
          )
        )

      assert Enum.count(matches) == 1
      assert hd(matches).id == article.id
    end
  end

  test "should find an article looking for a translation and one of its comments translations",
       %{translated_article: article} do
    with title <- article.translations.fr.title,
         comment <- hd(article.comments).transcriptions["fr"]["comment"] do
      matches =
        Repo.all(
          from(
            a in Article,
            join: c in Comment,
            on: a.id == c.article_id,
            where: translated(Article, a.title, :fr) == ^title,
            where: translated(Comment, c.comment, :fr) == ^comment
          )
        )

      assert Enum.count(matches) == 1
      assert hd(matches).id == article.id
    end
  end

  test "should raise when adding conditions to an untranslatable field" do
    # Since the QueryBuilder errors are emitted during compilation, we do a
    # little trick to delay the compilation of the query until the test
    # is running, so we can catch the raised error.
    invalid_module =
      quote do
        defmodule TestWrongQuery do
          require Ecto.Query
          import Ecto.Query, only: [from: 2]

          def invalid_query do
            from(
              a in Article,
              where: not is_nil(translated(Article, a.translations, :es))
            )
          end
        end
      end

    assert_raise ArgumentError,
                 "'Trans.Article' module must declare 'translations' as translatable",
                 fn -> Code.eval_quoted(invalid_module) end
  end

  test "should allow passing the locale from a variable" do
    locale = :es

    articles =
      Repo.all(
        from(
          a in Article,
          order_by: translated(Article, a.title, locale)
        )
      )

    assert Enum.any?(articles)
  end

  test "should allow passing the locale from a function" do
    locale = fn -> :es end

    articles =
      Repo.all(
        from(
          a in Article,
          order_by: translated(Article, a.title, locale.())
        )
      )

    assert Enum.any?(articles)
  end
end
