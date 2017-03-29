alias Trans.Article
alias Trans.TestRepo, as: Repo
import Trans.Factory
import Ecto.Query, only: [from: 2]
import Trans.QueryBuilder

defmodule QueryBuilderTest do
  use ExUnit.Case

  setup_all do
    {:ok,
      translated_article: insert(:article),
      untranslated_article: insert(:article, test_translation_container: %{}),
    }
  end

  test "should find an article by its FR title",
  %{translated_article: article} do
    fr_title = article.test_translation_container["fr"]["title"]
    matches = Repo.all(from a in Article,
      where: translated(Trans.Article, a.title, locale: :fr) == ^fr_title)
    assert Enum.count(matches) == 1
    assert hd(matches).id == article.id
  end
end
