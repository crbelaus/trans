defmodule Trans.Translator do
  @moduledoc """
  Provides functions to easily access translated values from schemas and fallback
  to a default locale when the translation does not exist in the required one.

  The functions provided by this module require structs declared in modules
  using `Trans`.
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

  We may have an `Article` like this (Our main locale is `:en`, but we have
  translations in `:es` and `:fr`):

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

      iex> Trans.Translator.translate(article, :title, :es)
      "Cómo escribir un corrector ortográfico"

  If the requested locale is not available, the default value will be returned:

      iex> Trans.Translator.translate(article, :title, :de)
      "How to Write a Spelling Corrector"

  But if translate! is used and the requested locale is not available, we will receive an error:

      iex> Trans.Translator.translate!(article, :title, :de)
      ** (RuntimeError) translation doesn't exist for field ':title' in language 'de'

  If we request a translation for an invalid field, we will receive an error:

      iex> Trans.Translator.translate(article, :fake_attr, :es)
      ** (RuntimeError) 'fake_attr' is not translatable. Translatable fields are [:title, :body]


  """
  @spec translate(struct, atom, String.t() | atom) :: any
  def translate(%{__struct__: module} = struct, field, locale)
      when (is_binary(locale) or is_atom(locale)) and is_atom(field) do
    unless Trans.translatable?(struct, field) do
      raise "'#{inspect(module)}' module must declare '#{inspect(field)}' as translatable"
    end

    # Return the translation or fall back to the default value
    case translated_field(struct, locale, field) do
      :error -> Map.fetch!(struct, field)
      nil -> Map.fetch!(struct, field)
      translation -> translation
    end
  end

  @spec translate!(struct, atom, String.t() | atom) :: any
  def translate!(%{__struct__: module} = struct, field, locale)
      when (is_binary(locale) or is_atom(locale)) and is_atom(field) do
    unless Trans.translatable?(struct, field) do
      raise "'#{inspect(module)}' module must declare '#{inspect(field)}' as translatable"
    end

    # Return the translation or fall back to the default value
    case translated_field(struct, locale, field) do
      :error ->
        raise "translation doesn't exist for field '#{inspect(field)}' in language '#{locale}'"

      translation ->
        translation
    end
  end

  defp translated_field(%{__struct__: module} = struct, locale, field) do
    with {:ok, all_translations} <- Map.fetch(struct, module.__trans__(:container)),
         {:ok, translations_for_locale} <- get_translations_for_locale(all_translations, locale),
         {:ok, translated_field} <- get_translated_field(translations_for_locale, field) do
      translated_field
    end
  end

  @doc """
  Translates the whole struct with all translatable values and translatable associations to the given locale

  ## Usage example
  Similar to `translate/3` but returns the whole struct

  We can get the Spanish version like this:

      iex> Trans.Translator.translate(article, :es)
      ...> %Article{
      ...>   title: "Cómo escribir un corrector ortográfico",
      ...>   body: "Un artículo maravilloso de Peter Norvig",
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

  """
  @spec translate(struct, String.t() | atom) :: struct
  def translate(%{__struct__: module} = struct, locale)
      when is_binary(locale) or is_atom(locale) do
    if Keyword.has_key?(module.__info__(:functions), :__trans__) do
      struct
      |> translate_fields(locale)
      |> translate_assocs(locale)
    else
      struct
    end
  end

  def translate(struct, _locale), do: struct

  defp translate_fields(%{__struct__: module} = struct, locale) do
    fields = module.__trans__(:fields)

    Enum.reduce(fields, struct, fn field, struct ->
      case translated_field(struct, locale, field) do
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
    get_translated_field(translations_for_locale, String.to_existing_atom(field))
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
