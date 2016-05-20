defmodule Trans.Translator do

  def translate(struct, translation_container, locale, field)
  when is_atom(translation_container) and is_atom(locale) and is_atom(field) do
    translate(struct, translation_container, to_string(locale), to_string(field))
  end

  def translate(struct, translation_container, locale, field)
  when is_atom(translation_container) and is_binary(locale) and is_binary(field) do
    translated_field = with {:ok, all_translations} <- Map.fetch(struct, translation_container),
                            {:ok, translations_for_locale} <- Map.fetch(all_translations, locale),
                            {:ok, translated_field} <- Map.fetch(translations_for_locale, field),
      do: translated_field
    case translated_field do
      :error -> Map.fetch(struct, field) # Fallback to the default value
      _ -> translated_field # Return the translated value
    end
  end
end
