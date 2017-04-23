alias Trans.Article
alias Trans.Comment
alias Trans.TestRepo, as: Repo

defmodule Trans.Factory do
  @moduledoc false

  def build(factory, attributes) do
    factory |> build() |> struct(attributes)
  end

  def insert(factory, attributes \\ []) do
    factory |> build(attributes) |> Repo.insert!
  end

  def build(:article) do
    %Article{
      title: Faker.Lorem.sentence(5, " "),
      body: Faker.Lorem.sentence(10, " "),
      comments: [build(:comment), build(:comment)],
      translations: %{
        "es" => %{
          "title" => Faker.Lorem.sentence(5, " "),
          "body"  => Faker.Lorem.sentence(10, " ")
        },
        "fr" => %{
          "title" => Faker.Lorem.sentence(5, " "),
          "body"  => Faker.Lorem.sentence(10, " ")
        }
      },
    }
  end

  def build(:comment) do
    %Comment{
      comment: Faker.Lorem.sentence(5, " "),
      transcriptions: %{
        "es" => %{"comment" => Faker.Lorem.sentence(5, " ")},
        "fr" => %{"comment" => Faker.Lorem.sentence(5, " ")},
      }
    }
  end
end
