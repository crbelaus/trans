if Code.ensure_loaded?(Ecto.Query) do
  defmodule Trans.QueryBuilder do
    import Ecto.Query, only: [from: 2]
    @moduledoc """
    Provides functions for building Ecto queries with conditions on translated
    fields.
    """

    @doc """
    Adds a condition to the given query to filter only those schemas translated
    into the given locale.

    ## Usage example (basic)

    Imagine that we have an `Article` schema wich has a title and a body that must
    be translated:

        defmodule Article do
          use Ecto.Schema
          use Trans, translates: [:title, :body]

          schema "articles" do
            field :title, :string
            field :body, :string
            field :translations, :map
          end
        end

    We could then get only the articles that are translated into ES like this:

        iex> Article
        ...> |> Trans.QueryBuilder.with_translations(:es)
        ...> |> Repo.all
        [debug] SELECT a0."id", a0."title", a0."body", a0."translations"
                FROM "articles" AS a0
                WHERE ((a0."translations"->>$1) is not null) ["es"]
        [debug] OK query=4.7ms queue=0.1ms

    ## Usage example (different *translation container*)

    As stated in the documentation of `Trans`, the *translation container* is the
    field that contains the list of translations for the struct.

    By default this function looks for the translations in a field called
    `translations`.  If your struct stores the translations in a different field,
    it should be specified when calling this function.

    Imagine that we have an `Article` schema like the previous example, but this
    time the translations will be stored in the field `article_translations`:

        defmodule Article do
          use Ecto.Schema
          use Trans, defaults: [container: :article_translations],
            translates: [:title, :body]

          schema "articles" do
            field :title, :string
            field :body, :string
            field :article_translations, :map
          end
        end

    Then, to get only the articles that are translated into ES we could use
    the same technique as in the first example, but specifying the container:

        iex> Article
        ...> |> Trans.QueryBuilder.with_translations(:es, container: :article_translations)
        ...> |> Repo.all
        [debug] SELECT a0."id", a0."title", a0."body", a0."article_translations"
                FROM "articles" AS a0
                WHERE ((a0."article_translations"->>$1) is not null) ["es"]
        [debug] OK query=4.7ms queue=0.1ms

    Having to repat constantly the name of the *translation container* can get
    tiresome quickly.  You can avoid that by using the `Trans` module in your
    schema.  Take a look at its documentation in order to see some examples.
    """
    def with_translations(query, locale, opts \\ [])

    def with_translations(query, locale, opts) when is_atom(locale) do
      with_translations(query, to_string(locale), opts)
    end

    def with_translations(query, locale, opts) when is_binary(locale) do
      translations_container = opts[:container] || :translations
      from translatable in query,
        where: fragment("(?->>?) is not null", field(translatable, ^translations_container), ^locale)
    end

    @doc """
    Adds a condition to the given query to filter only those records for which the
    field translation in the given locale matches the specified value using one
    of the available comparison operators.

    ## Usage example (basic)

    Imagine that we have an `Article` schema wich has a title and a body that must
    be translated:

        defmodule Article do
          use Ecto.Schema
          use Trans, translates: [:title, :body]

          schema "articles" do
            field :title, :string
            field :body, :string
            field :translations, :map
          end
        end

    We could then get only the articles for which the title in French matches
    "La République" like this:

        iex> Article
        ...> |> Trans.QueryBuilder.with_translation(:es, :title, "La République")
        ...> |> Repo.all
        [debug] SELECT a0."id", a0."title", a0."body", a0."translations"
                FROM "articles" AS a0
                WHERE (a0."translations"->$1->>$2 = $3) ["fr", "title", "La République"]
        [debug] OK query=2.6ms queue=0.1ms

    If we want to use a comparison with wilcards, we may specify a LIKE comparison:

        iex> Article
        ...> |> Trans.QueryBuilder.with_translation(:es, :title, "%République%", type: :like)
        ...> |> Repo.all
        [debug] SELECT a0."id", a0."title", a0."body", a0."translations"
                FROM "articles" AS a0
                WHERE (a0."translations"->$1->>$2 LIKE $3) ["fr", "title", "%République%"]
        [debug] OK query=2.1ms queue=0.1ms

    We can also perform a case insensitive comparison by using a ILIKE comparison:

        iex> Article
        ...> |> Trans.QueryBuilder.with_translation(:es, :title, "%république%", type: :ilike)
        ...> |> Repo.all
        [debug] SELECT a0."id", a0."title", a0."body", a0."translations"
                FROM "articles" AS a0
                WHERE (a0."translations"->$1->>$2 ILIKE $3) ["fr", "title", "%république%"]
        [debug] OK query=2.1ms queue=0.1ms

    ## Usage example (different *translation container*)

    As stated in the documentation of `Trans`, the *translation container* is the
    field that contains the list of translations for the struct.

    By default this function looks for the translations in a field called
    `translations`.  If your struct stores the translations in a different field,
    it should be specified when calling this function.

    Imagine that we have an `Article` schema like the previous example, but this
    time the translations will be stored in the field `article_translations`:

        defmodule Article do
          use Ecto.Schema
          use Trans, defaults: [container: :article_translations],
            translates: [:title, :body]

          schema "articles" do
            field :title, :string
            field :body, :string
            field :article_translations, :map
          end
        end

    As in the previous example, we may want to fetch all articles whose title contains
    the word "république" by performing a case insensitive operation. This time
    we must also specify the translation container name:

        iex> Article
        ...> |> Trans.QueryBuilder.with_translation(:fr, :title, "%république%", type: :ilike, container: :article_translations)
        ...> |> Repo.all
        [debug] SELECT a0."id", a0."title", a0."body", a0."article_translations"
                FROM "articles" AS a0
                WHERE (a0."article_translations"->$1->>$2 ILIKE $3) ["fr", "title", "%république%"]
        [debug] OK query=2.1ms queue=0.1ms

    Having to repat constantly the name of the *translation container* can get
    tiresome quickly.  You can avoid that by using the `Trans` module in your
    schema.  Take a look at its documentation in order to see some examples.
    """
    def with_translation(query, locale, field, expected, opts \\ [])

    def with_translation(query, locale, field, expected, opts)
    when is_atom(locale) or is_atom(field) do
      with_translation(query, to_string(locale), to_string(field), expected, opts)
    end

    def with_translation(query, locale, field, expected, opts)
    when is_binary(locale) and is_binary(field) do
      container = opts[:container] || :translations
      case opts[:type] do
        :like -> with_translation_like(query, locale, field, expected, container)
        :ilike -> with_translation_ilike(query, locale, field, expected, container)
        _ -> with_translation_matching(query, locale, field, expected, container)
      end
    end

    defp with_translation_matching(query, locale, field, expected, container) do
      from translatable in query,
        where: fragment("?->?->>?", field(translatable, ^container), ^locale, ^field) == ^expected
    end

    defp with_translation_like(query, locale, field, expected, container) do
      from translatable in query,
        where: like(fragment("?->?->>?", field(translatable, ^container), ^locale, ^field), ^expected)
    end

    defp with_translation_ilike(query, locale, field, expected, container) do
      from translatable in query,
        where: ilike(fragment("?->?->>?", field(translatable, ^container), ^locale, ^field), ^expected)
    end
  end
end
