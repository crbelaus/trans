defmodule Trans.Translator do

  def translate(struct, locale, field, opts \\ []) when is_map(struct) do
    translation_container = opts[:container] || :translations
    translated_field = with {:ok, all_translations} <- Map.fetch(struct, translation_container),
                            {:ok, translations_for_locale} <- Map.fetch(all_translations, to_string(locale)),
                            {:ok, translated_field} <- Map.fetch(translations_for_locale, to_string(field)),
      do: translated_field
    case translated_field do
      :error -> Map.fetch!(struct, field) # Fallback to the default value
      _ -> translated_field # Return the translated value
    end
  end


end
