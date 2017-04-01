defmodule Trans.Translator do
  @moduledoc """
  Provides functions to easily access translated values from schemas and fallback
  to a default locale when the translation does not exist in the required one.

  The functions provided by this module require structs declared in modules
  that use `Trans`.
  """

  @doc """
  Gets a translated value into the given locale or falls back to the default
  value if there is no translation available.

  ## Usage example

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

  We may have an `Article` like this (Our main locale is _:en_, but we have
  translations in _:es_ and _:fr_):

      iex> article = %Article{
      ...>   title: "How to Write a Spelling Corrector",
      ...>   body: "A wonderful article by Peter Norvig",
      ...>   translations: %{
      ...>     "es" => %{
      ...>       title: "Cómo escribir un corrector ortográfico",
      ...>       body: "Un artículo maravilloso de Peter Norvig"
      ...>     },
      ...>     "fr" => %{
      ...>        title: "Comment écrire un correcteur orthographique",
      ...>        body: "Un merveilleux article de Peter Norvig"
      ...>      }
      ...>   }
      ...> }

  We can then get the Spanish title:

      iex> Trans.Translator.translate(article, :es, :title)
      "Cómo escribir un corrector ortográfico"

  If the requested locale is not available, the default value will be returned:

      iex> Trans.Translator.translate(article, :de, :title)
      "How to Write a Spelling Corrector"

  If we request a translation for an invalid field, we will receive an error:

      iex> Trans.Translator.Translate(article, :es, :fake_attr)
      ** (RuntimeError) 'fake_attr' is not translatable. Translatable fields are [:title, :body]

  """
  @spec translate(struct, atom, atom) :: any
  def translate(%{__struct__: module} = struct, locale, field)
  when is_atom(locale) and is_atom(field) do
    translatable_fields = get_translatable_fields(module)
    raise_if_untranslatable(translatable_fields, field)

    translated_field = with {:ok, all_translations} <- Map.fetch(struct, :translations),
                            {:ok, translations_for_locale} <- Map.fetch(all_translations, to_string(locale)),
                            {:ok, translated_field} <- Map.fetch(translations_for_locale, to_string(field)),
      do: translated_field
    case translated_field do
      :error -> Map.fetch!(struct, field) # Fallback to the default value
      _ -> translated_field # Return the translated value
    end
  end

  defp get_translatable_fields(module) do
    if module.__info__(:functions)[:__trans__] do
      module.__trans__(:fields)
    else
      raise "#{module} must use `Trans` in order to be translated"
    end
  end

  defp raise_if_untranslatable(fields, field) do
    unless Enum.member?(fields, field) do
      raise "'#{field}' is not translatable. Translatable fields are #{inspect(fields)}"
    end
  end

end
