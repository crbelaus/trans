alias Trans.Article

import Trans.Factory

defmodule TransTest do
  use ExUnit.Case
  doctest Trans

  test "checks whether a field is translatable or not given a module" do
    assert Trans.translatable?(Article, :title) == true
    assert Trans.translatable?(Article, "title") == true
    assert Trans.translatable?(Article, :fake_field) == false
  end

  test "checks whether a field is translatable or not given a struct" do
    with article <- build(:article) do
      assert Trans.translatable?(article, :title) == true
      assert Trans.translatable?(article, "title") == true
      assert Trans.translatable?(article, :fake_field) == false
    end
  end

  test "returns the default translation container when unspecified" do
    assert Article.__trans__(:container) == :translations
  end

  test "compilation fails when translation container is not a valid field" do
    invalid_module = quote do
      defmodule TestArticle do
        use Trans, translates: [:title, :body], container: :invalid_container
        defstruct title: "", body: "", translations: %{}
      end
    end

    assert_raise ArgumentError,
      "The field invalid_container used as the translation container is not defined in Elixir.TestArticle struct",
      fn -> Code.eval_quoted(invalid_module) end
  end

end
