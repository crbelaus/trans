if Code.ensure_loaded?(Ecto.Query) do
  defmodule Trans.QueryBuilder do
    @moduledoc """
    Adds conditions to `Ecto` queries on translated fields.
    """

    @doc """
    Generates a SQL fragment for accessing a translated field in an `Ecto.Query`.

    The generated SQL fragment can be coupled with the rest of the functions and
    operators provided by `Ecto.Query` and `Ecto.Query.API`.

    ## Safety

    This macro will emit errors when used with untranslatable
    schema modules or fields. Errors are emited during the compilation phase
    thus avoiding runtime errors after the queries are built.

    ## Usage examples

    Imagine that we have an _Article_ schema declared as follows:

        defmodule Article do
          use Ecto.Schema
          use Trans, translates: [:title, :body]

          schema "articles" do
            field :title, :string
            field :body, :string
            field :translations, :map
          end
        end

    **Query for items that have a certain translation**

    This `Ecto.Query` will return all _Articles_ that have an Spanish translation:

        iex> Repo.all(from a in Article,
        ...>   where: not is_nil(translated(Article, a, locale: :es)) )

    The generated SQL is:

        SELECT a0."id", a0."title", a0."body", a0."translations"
        FROM "articles" AS a0
        WHERE (NOT ((a0."translations"->"es") IS NULL))

    **Query for items with a certain translated value**

    This query will return all articles whose French title matches the _"Elixir"_:

        iex> Repo.all(from a in Article,
        ...>   where: translated(Article, a.title, locale: :fr) == "Elixir")

    The generated SQL is:

        SELECT a0."id", a0."title", a0."body", a0."translations"
        FROM "articles" AS a0
        WHERE ((a0."translations"->"fr"->>"title") = "Elixir")

    **Query for items using a case insensitive comparison**

    This query will return all articles that contain "elixir" in their Spanish
    body, igoring case.

        iex> Repo.all(from a in Article,
        ...> where: ilike(translated(Article, a.body, locale: :es), "%elixir%"))

    The generated SQL is:

        SELECT a0."id", a0."title", a0."body", a0."translations"
        FROM "articles" AS a0
        WHERE ((a0."translations"->"es"->>"body") ILIKE "%elixir%")


    """
    defmacro translated(module, translatable, opts) do
      with field <- field(translatable) do
        Module.eval_quoted(__CALLER__, __validate_fields__(module, field))
        generate_query(schema(translatable), field, locale(opts))
      end
    end

    defp generate_query(schema, nil, locale) do
      quote do
        fragment("(?->?)", field(unquote(schema), :translations), ^unquote(locale))
      end
    end

    defp generate_query(schema, field, locale) do
      quote do
        fragment("(?->?->>?)", field(unquote(schema), :translations), ^unquote(locale), ^unquote(field))
      end
    end

    defp locale(opts) do
      case Keyword.fetch(opts, :locale) do
        {:ok, locale} when is_atom(locale)   -> to_string(locale)
        {:ok, locale} when is_binary(locale) -> locale
        _ -> raise ArgumentError, mesage: "You must specify a locale for the query. For example `translated(x.field, locale: :en)`."
      end
    end

    defp schema({{:., _, [schema, _field]}, _metadata, _args}), do: schema
    defp schema(schema), do: schema

    defp field({{:., _, [_schema, field]}, _metadata, _args}), do: to_string(field)
    defp field(_), do: nil

    @doc false
    def __validate_fields__(module, field) do
      quote do
        with field <- unquote(field) do
          cond do
            is_nil(field) -> nil
            not Trans.translatable?(unquote(module), unquote(field)) ->
              raise ArgumentError, message: "'#{inspect(unquote(module))}' module must declare '#{unquote(field)}' as translatable"
            true -> nil
          end
        end
      end
    end

  end
end
