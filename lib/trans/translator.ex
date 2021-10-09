defmodule Trans.Translator do
  @moduledoc """
  Provides easy access to struct translations.

  Although translations are stored in regular fields of an struct and can be accessed directly, **it
  is recommended to access translations using the functions provided by this module** instead. This
  functions present additional behaviours such as:

  * Checking that the given struct uses `Trans`
  * Automatically inferring the [translation container](Trans.html#module-translation-container)
    when needed.
  * Falling back to the default value or raising if a translation does not exist.
  * Translating entire structs.

  All examples in this module assume the following article, based on the schema defined in
  [Structured translations](Trans.html#module-structured-translations)

      article = %MyApp.Article{
        title: "How to Write a Spelling Corrector",
        body: "A wonderful article by Peter Norvig",
        translations: %MyApp.Article.Translations{
          es: %MyApp.Article.Translation{
            title: "Cómo escribir un corrector ortográfico",
            body: "Un artículo maravilloso de Peter Norvig"
          },
          fr: %MyApp.Article.Translation{
             title: "Comment écrire un correcteur orthographique",
             body: "Un merveilleux article de Peter Norvig"
           }
        }
      }
  """

  defguardp is_locale(locale) when is_binary(locale) or is_atom(locale)

  @doc """
  Translate a whole struct into the given locale.

  Translates the whole struct with all translatable values and translatable associations into the
  given locale. Similar to `translate/3` but returns the whole struct.

  ## Examples

  Assuming the example article in this module, we can translate the entire struct into Spanish:

      # Translate the entire article into Spanish
      article_es = Trans.Translator.translate(article, :es)

      article_es.title #=> "Cómo escribir un corrector ortográfico"
      article_es.body #=> "Un artículo maravilloso de Peter Norvig"

  Just like `translate/3`, falls back to the default locale if the translation does not exist:

      # The Deutsch translation does not exist
      article_de = Trans.Translator.translate(article, :de)

      article_de.title #=> "How to Write a Spelling Corrector"
      article_de.body #=> "A wonderful article by Peter Norvig"
  """
  @doc since: "2.3.0"
  @spec translate(Trans.translatable(), Trans.locale()) :: Trans.translatable()
  def translate(%{__struct__: module} = translatable, locale) when is_locale(locale) do
    if Keyword.has_key?(module.__info__(:functions), :__trans__) do
      translatable
      |> translate_fields(locale)
      |> translate_assocs(locale)
    else
      translatable
    end
  end

  @doc """
  Translate a single field into the given locale.

  Translates the field into the given locale or falls back to the default value if there is no
  translation available.

  ## Examples

  Assuming the example article in this module:

      # We can get the Spanish title:
      Trans.Translator.translate(article, :title, :es)
      "Cómo escribir un corrector ortográfico"

      # If the requested locale is not available, the default value will be returned:
      Trans.Translator.translate(article, :title, :de)
      "How to Write a Spelling Corrector"

      # If we request a translation for an invalid field, we will receive an error:
      Trans.Translator.translate(article, :fake_attr, :es)
      ** (RuntimeError) 'Article' module must declare 'fake_attr'  as translatable
  """
  @spec translate(Trans.translatable(), atom, Trans.locale()) :: any
  def translate(%{__struct__: module} = translatable, field, locale)
      when is_locale(locale) and is_atom(field) do
    unless Trans.translatable?(translatable, field) do
      raise "'#{inspect(module)}' module must declare '#{inspect(field)}' as translatable"
    end

    # Return the translation or fall back to the default value
    case translate_field(translatable, locale, field) do
      :error -> Map.fetch!(translatable, field)
      nil -> Map.fetch!(translatable, field)
      translation -> translation
    end
  end

  @doc """
  Translate a single field into the given locale or raise if there is no translation.

  Just like `translate/3` gets a translated field into the given locale. Raises if there is no
  translation availabe.

  ## Examples

  Assuming the example article in this module:

      Trans.Translator.translate!(article, :title, :de)
      ** (RuntimeError) translation doesn't exist for field ':title' in language 'de'
  """
  @doc since: "2.3.0"
  @spec translate!(Trans.translatable(), atom, Trans.locale()) :: any
  def translate!(%{__struct__: module} = translatable, field, locale)
      when is_locale(locale) and is_atom(field) do
    unless Trans.translatable?(translatable, field) do
      raise "'#{inspect(module)}' module must declare '#{inspect(field)}' as translatable"
    end

    # Return the translation or fall back to the default value
    case translate_field(translatable, locale, field) do
      :error ->
        raise "translation doesn't exist for field '#{inspect(field)}' in language '#{locale}'"

      translation ->
        translation
    end
  end

  defp translate_field(%{__struct__: module} = struct, locale, field) do
    with {:ok, all_translations} <- Map.fetch(struct, module.__trans__(:container)),
         {:ok, translations_for_locale} <- get_translations_for_locale(all_translations, locale),
         {:ok, translated_field} <- get_translated_field(translations_for_locale, field) do
      translated_field
    end
  end

  defp translate_fields(%{__struct__: module} = struct, locale) do
    fields = module.__trans__(:fields)

    Enum.reduce(fields, struct, fn field, struct ->
      case translate_field(struct, locale, field) do
        :error -> struct
        translation -> Map.put(struct, field, translation)
      end
    end)
  end

  defp translate_assocs(%{__struct__: module} = struct, locale) do
    associations = module.__schema__(:associations)
    embeds = module.__schema__(:embeds)

    Enum.reduce(associations ++ embeds, struct, fn assoc_name, struct ->
      Map.update(struct, assoc_name, nil, fn
        %Ecto.Association.NotLoaded{} = item ->
          item

        items when is_list(items) ->
          Enum.map(items, &translate(&1, locale))

        %{} = item ->
          translate(item, locale)

        item ->
          item
      end)
    end)
  end

  # check if struct (means it's using ecto embeds); if so, make sure 'locale' is also atom
  defp get_translations_for_locale(%{__struct__: _} = all_translations, locale)
       when is_binary(locale) do
    get_translations_for_locale(all_translations, String.to_existing_atom(locale))
  end

  defp get_translations_for_locale(%{__struct__: _} = all_translations, locale)
       when is_atom(locale) do
    Map.fetch(all_translations, locale)
  end

  # fallback to default behaviour
  defp get_translations_for_locale(all_translations, locale) do
    Map.fetch(all_translations, to_string(locale))
  end

  # there are no translations for this locale embed
  defp get_translated_field(nil, _field), do: nil

  # check if struct (means it's using ecto embeds); if so, make sure 'field' is also atom
  defp get_translated_field(%{__struct__: _} = translations_for_locale, field)
       when is_binary(field) do
    get_translated_field(translations_for_locale, String.to_atom(field))
  end

  defp get_translated_field(%{__struct__: _} = translations_for_locale, field)
       when is_atom(field) do
    Map.fetch(translations_for_locale, field)
  end

  # fallback to default behaviour
  defp get_translated_field(translations_for_locale, field) do
    Map.fetch(translations_for_locale, to_string(field))
  end
end
