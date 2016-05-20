defmodule Trans.Translator do

  def translate(struct, locale, field, translation_container \\ :translations)

  def translate(struct, locale, field, translation_container)
  when is_map(struct) and is_atom(translation_container) and is_atom(locale) and is_atom(field) do
    translate(struct, to_string(locale), to_string(field), translation_container)
  end

  def translate(struct, locale, field, translation_container)
  when is_map(struct) and is_atom(translation_container) and is_binary(locale) and is_binary(field) do
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
