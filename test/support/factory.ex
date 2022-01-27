alias Trans.{Article, Book}
alias Trans.Comment
alias Trans.Repo, as: Repo

defmodule Trans.Factory do
  @moduledoc false

  def build(factory, attributes) do
    factory |> build() |> struct(attributes)
  end

  def insert(factory, attributes \\ []) do
    factory |> build(attributes) |> Repo.insert!()
  end

  def build(:article) do
    %Article{
      title: unique_string("Article title in English"),
      body: unique_string("Article body in English"),
      comments: [build(:comment), build(:comment)],
      translations: %Article.Translations{
        es: %Article.Translations.Fields{
          title: unique_string("Article title in Spanish"),
          body: unique_string("Article body in Spanish")
        },
        fr: %Article.Translations.Fields{
          title: unique_string("Article title in French"),
          body: unique_string("Article body in French")
        }
      }
    }
  end

  def build(:book) do
    %Book{
      title: unique_string("Book title in English"),
      body: unique_string("Book body in English"),
      translations: %Book.Translations{
        es: %Book.Translations.Fields{
          title: unique_string("Book title in Spanish"),
          body: unique_string("Book body in Spanish")
        },
        fr: %Book.Translations.Fields{
          title: unique_string("Book title in French"),
          body: unique_string("Book body in French")
        }
      }
    }
  end

  def build(:comment) do
    %Comment{
      comment: unique_string("Comment in English"),
      transcriptions: %{
        "es" => %{"comment" => unique_string("Comment in Spanish")},
        "fr" => %{"comment" => unique_string("Comment in French")}
      }
    }
  end

  # Adds a random suffix to the given string to make it unique.
  defp unique_string(string) do
    Enum.join([string, System.unique_integer()], " - ")
  end
end
