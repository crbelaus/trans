defmodule Trans do

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
