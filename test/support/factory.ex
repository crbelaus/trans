  alias Trans.Article

defmodule Trans.Factory do
  use ExMachina.Ecto, repo: Trans.TestRepo

  def article_factory do
    %Article{
      title: Faker.Lorem.sentence(5, " "),
      body: Faker.Lorem.sentence(10, " "),
      test_translation_container: %{
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
