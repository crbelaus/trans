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
  translated fields you should take a look at this module**. To use this module
  you must have `Ecto` among your dependencies.

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

  This module provides metadata that is required by the `Trans.QueryBuilder` and
  the `Trans.Translator` modules to work. When used, this module will define
  two functions in your module:

  - `__trans__(:container)` returns an atom with the name of the translation
  container field.
  - `__trans__(:fields)` returns a list of atoms with the names of the
  translatable fields.

  ## Usage examples

  The general way to use `Trans` in a module is:

      use Trans, translates: [:field_1, :field_2][, container: :translation_container_field]

  Suppose that you have an `Article` schema that has a title and a body that must
  be translated.  You can set up Trans in your module like the following example:

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
        use Trans, translates: [:title, :body], container: :article_translations

        schema "articles" do
          field :title, :string
          field :body, :string
          field :article_translations, :map
        end
      end

  """

  defmacro __using__(opts) do
    quote do
      @doc """
      This function provides metadata used by Trans for the `Trans.QueryBuilder`
      and the `Trans.Translator` modules.

      Imagine the following module.

          defmodule Article do
            use Ecto.Schema
            use Trans, translates: [:title, :body], container: :article_translations

            schema "articles" do
              field :title, :string
              field :body, :string
              field :article_translations, :map
            end
          end

      Calling `__trans__(:container)` will return the name of the translation
      container field.

          iex(1)> Article.__trans__(:container)
          :article_translations

      Calling `__trans__(:fields)` will return a list with the translatable
      fields.

          iex(1)> Article.__trans__(:fields)
          [:title, :body]
      """
      @spec __trans__(:fields) :: list(atom)
      def __trans__(:fields), do: unquote(translatables(opts))
    end
  end

  defp translatables(opts) do
    case Keyword.fetch(opts, :translates) do
      {:ok, fields} when is_list(fields) -> fields
      _ -> raise ArgumentError, message: "Trans requires a 'translates' option that contains the list of translatable fields names"
    end
  end

end
