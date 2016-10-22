defmodule Trans do
  @moduledoc """
  Trans provides a way to manage and query translations embedded into schemas
  and removes the necessity of maintaing extra tables only for translation storage.

  Trans is split into 2 main components:

  * `Trans.Translator` - provides functions to easily access translated values
  from schemas and fallback to a default locale when the translation does not
  exist in the required one.  **If you want to get translations from a schema you
  should take a look at this module**.
  * `Trans.QueryBuilder` - provides functions that can be chained in queries and
  allow filtering by translated values.  **If you want to filter queries using
  translated fields you should take a look at this module**.

  ## What does this package do?

  `Trans` allows you to store translations of a Struct as an extra field of
  that Struct.

  `Trans` sees its main utility when it is used on `Ecto.Schema` modules.
  **When paired with an `Ecto.Schema`, `Trans` allows you to keep the schema and
  its translations on the same database table.**  This removes the necessity of
  spreading the schema and its translations on multiple tables and reduces the
  number of required *JOINs* that must be performed on queries.

  The field that stores the translations on the Struct is called the *translation
  container* and by default it is expected to be named `translations`, but
  that can be easily overriden.

  ## What does this module do?

  Although it does not provide any functions that can be used directly
  (those functions are provided by the `Trans.Translator` and `Trans.QueryBuilder`
  modules), using the `Trans` module provides two main benefits:

  - **Checking the safety of the translation operations** - When your schema uses
  `Trans` it will safe check the queries that filter on a translated field.  This
  means that trying to set a translation filter for an untranslated field will
  produce a error when building the query.

  - **Avoiding the repetition of default options** - If your schema's
  *translation container* receives a different name than the default
  `translations`, it would have to be specified on every call to
  `Trans.QueryBuilder` or `Trans.Translator` functions. When using the `Trans`
  module, this setting can be specified once an applied automatically when required.

  ## Usage examples

  The general way to use `Trans` in a module is:

      use Trans, translates: [:field_1, :field_2][, defaults: [...]]

  Suppose that you have an `Article` schema that has a title and a body that must
  be translated.  You can set up the convenience functions in your module
  like the following example:

      defmodule Article do
        use Ecto.Schema
        use Trans, translates: [:title, :body]

        schema "articles" do
          field :title, :string
          field :body, :string
          field :translations, :map
        end
      end

  Now imagine that the `Article` schema uses a different *translation container*
  to store the translations.  This should be specified when using `Trans` so
  it can automatically provide the required defaults to `Trans.QueryBuilder`
  and `Trans.Translator` like the following example:

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

  """

  defmacro __using__(opts) do
    setup_convenience_functions(get_defaults(opts), get_translatables(opts))
  end

  defp setup_convenience_functions(defaults, translatables) do
    quote do
      # Wrapper of Trans.QueryBuilder.with_translations/3
      def with_translations(query, locale, opts \\ []) do
        Trans.QueryBuilder.with_translations(query, locale, opts ++ unquote(defaults))
      end

      # Wrapper of Trans.QueryBuilder.with_translations
      def with_translation(query, locale, field, expected, opts \\ []) do
        if not Enum.member?(unquote(translatables), field) do
          raise ArgumentError, "The field `#{field}` is not declared as translatable"
        end
        Trans.QueryBuilder.with_translation(query, locale, field, expected, opts ++ unquote(defaults))
      end
    end
  end

  defp get_translatables(opts) do
    case List.keyfind(opts, :translates, 0) do
      nil -> raise ArgumentError, "You must provide a `translates` option with a list of the translatable fields"
      {:translates, translatables} when is_list(translatables) -> translatables
      {:translates, translatables} -> [translatables]
    end
  end

  defp get_defaults(opts) do
    case List.keyfind(opts, :defaults, 0) do
      nil -> []
      {:defaults, defaults} -> defaults
    end
  end

end
