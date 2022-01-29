if Code.ensure_loaded?(Ecto.Adapters.SQL) do
  defmodule Trans.QueryBuilder do
    @moduledoc """
    Provides helpers for filtering translations in `Ecto.Queries`.

    This module requires `Ecto.SQL` to be available during the compilation.
    """

    @doc """
    Generates a SQL fragment for accessing a translated field in an `Ecto.Query`.

    The generated SQL fragment can be coupled with the rest of the functions and operators provided
    by `Ecto.Query` and `Ecto.Query.API`.

    ## Safety

    This macro will emit errors when used with untranslatable schema modules or fields. Errors are
    emited during the compilation phase thus avoiding runtime errors after the queries are built.

    ## Examples

    Assuming the Article schema defined in
    [Structured translations](Trans.html#module-structured-translations):

        # Return all articles that have a Spanish translation
        from a in Article, where: translated(Article, a, :es) != "null"
        #=> SELECT a0."id", a0."title", a0."body", a0."translations"
        #=> FROM "articles" AS a0
        #=> WHERE a0."translations"->"es" != 'null'

        # Query items with a certain translated value
        from a in Article, where: translated(Article, a.title, :fr) == "Elixir"
        #=> SELECT a0."id", a0."title", a0."body", a0."translations"
        #=> FROM "articles" AS a0
        #=> WHERE ((a0."translations"->"fr"->>"title") = "Elixir")

        # Query items using a case insensitive comparison
        from a in Article, where: ilike(translated(Article, a.body, :es), "%elixir%")
        #=> SELECT a0."id", a0."title", a0."body", a0."translations"
        #=> FROM "articles" AS a0
        #=> WHERE ((a0."translations"->"es"->>"body") ILIKE "%elixir%")

    ## Structured translations vs free-form translations

    The `Trans.QueryBuilder` works with both
    [Structured translations](Trans.html#module-structured-translations)
    and with [Free-form translations](Transl.html#module-free-form-translations).

    In most situations, the queries can be performed in the same way for both cases. **When querying
    for data translated into a certain locale we must know wheter we are using structured or
    free-form translations**.

    When using structured translations, the translations are saved as an embedded schema. This means
    that **the locale keys will be always present even if there is no translation for that locale.**
    In the database we have a `"null"` JSON value.

        # If MyApp.Article uses structured translations
        Repo.all(from a in MyApp.Article, where: translated(MyApp.Article, a, :es) != "null")
        #=> SELECT a0."id", a0."title", a0."body", a0."translations"
        #=> FROM "articles" AS a0
        #=> WHERE (a0."translations"->"es") != 'null'

    When using free-form translations, the translations are stored in a simple map. This means that
    **the locale keys may be absent if there is no translation for that locale.** In the database we
    have a `NULL` value.

        # If MyApp.Article uses free-form translations
        Repo.all(from a in MyApp.Article, where: not is_nil(translated(MyApp.Article, a, :es)))
        #=> SELECT a0."id", a0."title", a0."body", a0."translations"
        #=> FROM "articles" AS a0
        #=> WHERE (NOT ((a0."translations"->"es") IS NULL))

    ## More complex queries

    The `translated/3` macro can also be used with relations and joined schemas.
    For more complex examples take a look at the QueryBuilder tests (the file
    is located in `test/trans/query_builder_test.ex`).
    """
    defmacro translated(module, translatable, locale) do
      with field <- field(translatable) do
        module = Macro.expand(module, __CALLER__)
        validate_field(module, field)
        generate_query(schema(translatable), module, field, locale)
      end
    end

    defmacro translated_as(module, translatable, locale) do
      field = field(translatable)
      translated = quote do: translated(unquote(module), unquote(translatable), unquote(locale))
      translated_as(translated, field)
    end

    defp translated_as(translated, nil) do
      translated
    end

    defp translated_as(translated, field) do
      {:fragment, [], ["? AS #{inspect to_string(field)}", translated]}
    end

    defp generate_query(schema, module, nil, locales) when is_list(locales) do
      for locale <- locales do
        generate_query(schema, module, nil, locale)
      end
      |> coalesce(locales)
    end

    defp generate_query(schema, module, nil, locale) do
      quote do
        fragment(
          "NULLIF((?->?),'null')",
          field(unquote(schema), unquote(module.__trans__(:container))),
          ^to_string(unquote(locale))
        )
      end
    end

    defp generate_query(schema, module, field, locales) when is_list(locales) do
      for locale <- locales do
        generate_query(schema, module, field, locale)
      end
      |> coalesce(locales)
    end

    defp generate_query(schema, module, field, locale) do
      if locale == module.__trans__(:default_locale) do
        quote do
          field(unquote(schema), unquote(field))
        end
      else
        quote do
          fragment(
            "(?->?->>?)",
            field(unquote(schema), unquote(module.__trans__(:container))),
            ^to_string(unquote(locale)),
            ^to_string(unquote(field))
          )
        end
      end
    end

    defp coalesce(ast, enum) do
      placeholders = Enum.map(enum, fn _x -> "?" end) |> Enum.join(",")
      fun = "COALESCE(" <> placeholders <> ")"

      {:fragment, [], [fun | ast]}
    end

    defp schema({{:., _, [schema, _field]}, _metadata, _args}), do: schema
    defp schema(schema), do: schema

    defp field({{:., _, [_schema, field]}, _metadata, _args}), do: field
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
