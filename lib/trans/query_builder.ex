if Code.ensure_loaded?(Ecto.Query) do
  defmodule Trans.QueryBuilder do

    defmacro translated(translatable, opts) do
      generate_query(schema(translatable), field(translatable), locale(opts))
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
        _ -> error_unspecified_locale()
      end
    end

    defp schema({{:., _, [schema, _field]}, _metadata, _args}), do: schema
    defp schema(schema), do: schema

    defp field({{:., _, [_schema, field]}, _metadata, _args}), do: to_string(field)
    defp field(_), do: nil

    defp error_unspecified_locale do
      raise ArgumentError, mesage: "You must specify a locale for the query. For example `translated(x.field, locale: :en)`."
    end

  end
end
