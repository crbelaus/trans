defmodule Trans do
  @moduledoc """
  Trans is split into 2 main components:

  * `Trans.Translator`: provides functions for obtaining translated values from
  a module.
  * `Trans.QueryBuilder`: provides functions for finding modules by translated
  values.

  Take a look at the documentation of those modules to see what functions they
  provide.

  ## Usage

  You can use this module in each of your model modules like this:

      use Trans, translates: [:field1, :field2], defaults: [...]

  By using `Trans` you can set up convenience functions to avoid unnecesary
  repetition of default options. For example, your model may use a translation
  container with a different name than the default `translations`. In this case
  you would need to specify the translation container in each call to
  `Trans.QueryBuilder`. By using the `Trans` module you can specify a list of
  default options that will be automatically applied to those modules.

  When using `Trans`, two main functions will be set up in your module:
  `with_translations` and `with_translation`. Those two functions call their
  respectives in the `Trans.QueryBuilder` module, but automatically passing
  the `defaults` specified when using `Trans`.
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
