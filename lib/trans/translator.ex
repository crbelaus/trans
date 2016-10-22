defmodule Trans.Translator do
  @moduledoc """
  Provides functions to easily access translated values from schemas and fallback
  to a default locale when the translation does not exist in the required one.
  """

  @doc """
  Gets the translated value for the given locale and field. If the field is not
  translated into the required locale, the default locale will be used.

  ## Usage example (basic)

  Imagine that we have an `Article` schema wich has a title and a body that must
  be translated:

      defmodule Article do
        use Ecto.Schema
        use Trans, translates: [:title, :body]

        schema "articles" do
          field :title, :string
          field :body, :string
          field :translations, :map
        end
      end

  We may have an `Article` like this (Our main locale is EN, but we have
  translations in ES and FR):

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

  We can then get the title translated into ES:

      iex> Trans.Translator.translate(article, :es, :title)
      "Cómo escribir un corrector ortográfico"

  If we try to get the title translated into a non available locale, Trans will
  automatically fallback to the default one.

      iex> Trans.Translator.translate(article, :de, :title)
      "How to Write a Spelling Corrector"

  ## Usage example (different *translation container*)

  As stated in the documentation of `Trans`, the *translation container* is the
  field that contains the list of translations for the struct.

  By default this function looks for the translations in a field called
  `translations`.  If your struct stores the translations in a different field,
  it should be specified when calling this function.

  Imagine that we have an `Article` schema like the previous example, but this
  time the translations will be stored in the field `article_translations`:

      defmodule Article do
        use Ecto.Schema
        use Trans, defaults: [container: :article_translations],
          translates: [:title, :body]

        schema "articles" do
          field :title, :string
          field :body, :string
          field :article_translations, :map
        end
      end

  We may have an `Article` like this (Our main locale is EN, but we have
  translations in ES and FR):

      iex> article = %Article{
      ...>   title: "How to Write a Spelling Corrector",
      ...>   body: "A wonderful article by Peter Norvig",
      ...>   article_translations: %{
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

  We can translate any field as usual, but the translation container must be
  explicitly specified.

      iex> Trans.Translator.translate(article, :es, :title, container: :article_translations)
      "Cómo escribir un corrector ortográfico"

  """
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
