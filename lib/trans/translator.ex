defmodule Trans.Translator do
  @moduledoc """
  Provides functions to access translated fiels in a model. Take a
  look at the `Trans` module documentation to see how you can set up convenience
  helpers in your model module to avoid repetition of default values.
  """

  @doc """
  Returns the translated value for the given locale and field. If the field is
  not translated into the given locale, fallbacks to the default one.

  Take a look at the `Trans` module to see how you can set up convenience functions
  to access the translated values from your model module and avoid repetition of
  defaul options.

  ## Usage example

  Suppose that we have an article model which has a title and a body fields, both
  fields can be translated.

      defmodule Trans.Article do
        use Ecto.Schema

        schema "articles" do
          field :title, :string
          field :body, :string
          field :translations, :map
        end

      end

  We have an article translated to spanish.

      iex> changeset = Article.changeset(%Article{}, %{
          title: "Title in the default locale",
          body: "Body in the default locale",
          translations: %{
            "es" => %{title: "Title in Spanish", body: "Body in Spanish"}
          }
        })
      iex> article = Repo.insert!(changeset)
      %Article{...}

  We can then get the title translated to Spanish:

      iex> Trans.Translator.translate(article, :es, :title)
      "Title in Spanish"

  If we try to get the title translated in a different locale, `Trans` will
  automatically fallback to the default value

      iex> Trans.Translator.translate(article, :fr, :title)
      "Title in the default locale"

  ## Translation container

  The translation container is the field that contains the translations of other
  fields. By default, this function will look for translations into a field named
  `translations`.  If you use a different container you can also specify it so
  the translations are looked up correctly.

  Suppose we have an article model like the one we had in the first example, but
  this time we are storing the translations in the `my_translation_container`
  field:

      defmodule Trans.Article do
        use Ecto.Schema

        schema "articles" do
          field :title, :string
          field :body, :string
          field :my_translation_container, :map
        end

      end

  We have an article translated to spanish.

      iex> changeset = Article.changeset(%Article{}, %{
          title: "Title in the default locale",
          body: "Body in the default locale",
          my_translation_container: %{
            "es" => %{title: "Title in Spanish", body: "Body in Spanish"}
          }
        })
      iex> article = Repo.insert!(changeset)
      %Article{...}

  We can translate any field as usual. Since the translation container is not
  the default one, it needs to be explicitly specified.

      iex> Trans.Translator.translate(article, :es, :title, container: :my_translation_container)
      "Title in Spanish"

  When we want to translate multiple fields, having to pass the translation
  container name everytime can be a little bit tedious. You can avoid this
  repetition by using the `Trans` module in your own module module.
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
