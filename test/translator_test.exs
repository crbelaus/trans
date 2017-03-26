alias Trans.Translator

import Trans.Factory

defmodule TranslatorTest do
  use ExUnit.Case
  doctest Trans

  test "retrieve translation for existing attribute" do
    article = build(:article)
    fr_body = Translator.translate(article, :fr, :body, container: :test_translation_container)
    assert fr_body == article.test_translation_container["fr"]["body"]
  end

  test "fallback to default value when no translation available" do
    article = build(:article)
    # Since we don't have a "de" translation, it will return the default value'
    body = Translator.translate(article, :de, :body, container: :test_translation_container)
    assert body == article.body
  end

  test "raise error wen translating an untraslatable attribute" do
    article = build(:article)
    assert_raise KeyError, fn ->
      Translator.translate(article, :es, :fake_attr, container: :test_translation_container)
    end
  end
end
