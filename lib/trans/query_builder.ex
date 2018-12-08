if Code.ensure_loaded?(Ecto.Adapters.SQL) do
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
        ...>   where: not is_nil(translated(Article, a, :es)))

    The generated SQL is:

        SELECT a0."id", a0."title", a0."body", a0."translations"
        FROM "articles" AS a0
        WHERE (NOT ((a0."translations"->"es") IS NULL))

    **Query for items with a certain translated value**

    This query will return all articles whose French title matches the _"Elixir"_:

        iex> Repo.all(from a in Article,
        ...>   where: translated(Article, a.title, :fr) == "Elixir")

    The generated SQL is:

        SELECT a0."id", a0."title", a0."body", a0."translations"
        FROM "articles" AS a0
        WHERE ((a0."translations"->"fr"->>"title") = "Elixir")

    **Query for items using a case insensitive comparison**

    This query will return all articles that contain "elixir" in their Spanish
    body, igoring case.

        iex> Repo.all(from a in Article,
        ...> where: ilike(translated(Article, a.body, :es), "%elixir%"))

    The generated SQL is:

        SELECT a0."id", a0."title", a0."body", a0."translations"
        FROM "articles" AS a0
        WHERE ((a0."translations"->"es"->>"body") ILIKE "%elixir%")

    **More complex queries**

    The `translated/3` macro can also be used with relations and joined schemas.
    For more complex examples take a look at the QueryBuilder tests (the file
    is locaed in `test/query_builder_test.ex`).

    """
    defmacro translated(module, translatable, locale) do
      with field <- field(translatable) do
        module = Macro.expand(module, __CALLER__)
        validate_field(module, field)
        generate_query(schema(translatable), module, field, locale)
      end
    end

    defp generate_query(schema, module, nil, locale) do
      quote do
        fragment(
          "(?->?)",
          field(unquote(schema), unquote(module.__trans__(:container))),
          ^to_string(unquote(locale))
        )
      end
    end

    defp generate_query(schema, module, field, locale) do
      quote do
        fragment(
          "(?->?->>?)",
          field(unquote(schema), unquote(module.__trans__(:container))),
          ^to_string(unquote(locale)),
          ^unquote(field)
        )
      end
    end

    defp schema({{:., _, [schema, _field]}, _metadata, _args}), do: schema
    defp schema(schema), do: schema

    defp field({{:., _, [_schema, field]}, _metadata, _args}), do: to_string(field)
    defp field(_), do: nil

    defp validate_field(module, field) do
      cond do
        is_nil(field) ->
          nil

        not Trans.translatable?(module, field) ->
          raise ArgumentError,
            message: "'#{inspect(module)}' module must declare '#{field}' as translatable"

        true ->
          nil
      end
    end
  end
end
