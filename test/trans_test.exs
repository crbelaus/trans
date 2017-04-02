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
end
