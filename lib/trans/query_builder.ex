if Code.ensure_loaded?(Ecto.Query) do
  defmodule Trans.QueryBuilder do

    defmacro translated(module, translatable, opts) do
      with field <- field(translatable) do
        Module.eval_quoted __CALLER__, [
          __validate_fields__(module, field)
        ]
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
              raise ArgumentError, message: "'#{inspect(unquote(module))}' module must declare '#{inspect(unquote(field))}' as translatable"
            true -> nil
          end
        end
      end
    end

  end
end
