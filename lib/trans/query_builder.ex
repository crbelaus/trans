defmodule Trans.QueryBuilder do
  import Ecto.Query, only: [from: 2]
  @moduledoc """
  Provides functions to build queries with conditions on translated fields. Take
  a look at the `Trans` module documentation to see how you can set up convenience
  helpers in your model module to avoid repetition of default values.
  """

  @doc """
  Adds a condition to the given query to filter only those models translated to
  the given locale.

  Take a look at the `Trans` module to see how you can set up convenience functions
  in your model to avoid excessive repetition of default options.

  ## Usage example

  Suppose that we have an article model which has a title and a body fields, both
  of them can be translated.

      defmodule Article do
        use Ecto.Schema

        schema "articles" do
          field :title, :string
          field :body, :string
          field :translations, :map
        end

      end

  We could then get only the articles that are translated into spanish like this:

      iex> Article |> Trans.QueryBuilder.with_translations(:es) |> Repo.all
      [debug] SELECT a0."id", a0."title", a0."body", a0."translations" FROM "articles" AS a0 WHERE ((a0."translations"->>$1) is not null) ["es"] OK query=4.7ms queue=0.1ms

  ## Translation container

  We may have some models in which translations are stored in a different column
  than the default `translations`. When our translations container is not the
  default one, it must be explicitly specified.

  Suppose that we have a model like the one in the previous example, but which
  stores the translations in the field `my_translation_container`:

      defmodule Article do
        use Ecto.Schema

        schema "articles" do
          field :title, :string
          field :body, :string
          field :my_translation_container, :map
        end

      end

  Then, to get only the articles that are translated into Spanish we could use
  the same technique as in the first example, but specifying the container:

      iex> Article |> Trans.QueryBuilder.with_translations(:es, container: :my_translation_container) |> Repo.all
      [debug] SELECT a0."id", a0."title", a0."body", a0."my_translation_container" FROM "articles" AS a0 WHERE ((a0."my_translation_container"->>$1) is not null) ["es"] OK query=4.7ms queue=0.1ms

  You can avoid the same repetition by using the `Trans` module in your model
  module. Take a look at the `Trans` module documentation to see how to do it.
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

  # TODO with_translation
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

  def with_translation_ilike(query, locale, field, expected, container) do
    from translatable in query,
      where: ilike(fragment("?->?->>?", field(translatable, ^container), ^locale, ^field), ^expected)
  end


end
