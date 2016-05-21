defmodule Trans do

  defmacro __using__(opts) do
    quote do

      # Set up the translations container field
      @translations_container unquote(opts[:container] || :translations)

      # Wrapper of Trans.QueryBuilder.with_translations/3
      def with_translations(query, locale, opts \\ []) do
        Trans.QueryBuilder.with_translations(query, locale,
          opts ++ [container: @translations_container])
      end

      # Wrapper of Trans.QueryBuilder.with_translations
      def with_translation(query, locale, field, expected, opts \\ []) do
        Trans.QueryBuilder.with_translation(query, locale, field, expected,
          opts ++ [container: @translations_container])
      end

    end
  end

end
