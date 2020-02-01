alias Trans.Article
alias Trans.Comment
alias Trans.TestRepo, as: Repo

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
      translations: %{
        "es" => %{
          "title" => unique_string("Article title in Spanish"),
          "body" => unique_string("Article body in Spanish")
        },
        "fr" => %{
          "title" => unique_string("Article title in French"),
          "body" => unique_string("Article body in French")
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
    suffix =
      string
      |> String.length()
      |> :crypto.strong_rand_bytes()
      |> Base.url_encode64()

    Enum.join([string, suffix], " - ")
  end
end
