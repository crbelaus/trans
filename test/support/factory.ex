alias Trans.Article
alias Trans.TestRepo, as: Repo

defmodule Trans.Factory do

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
      translations: %{
        "es" => %{
          "title" => Faker.Lorem.sentence(5, " "),
          "body"  => Faker.Lorem.sentence(10, " ")
        },
        "fr" => %{
          "title" => Faker.Lorem.sentence(5, " "),
          "body"  => Faker.Lorem.sentence(10, " ")
        }
      }
    }
  end
end
