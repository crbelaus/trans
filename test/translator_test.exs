alias Trans.Translator

import Trans.Factory

defmodule TranslatorTest do
  use ExUnit.Case
  doctest Trans

  test "retrieve translation for existing attribute" do
    article = build(:article)
    fr_body = Translator.translate(article, :fr, :body)
    assert fr_body == article.translations["fr"]["body"]
  end

  test "fallback to default value when no translation available" do
    article = build(:article)
    # Since we don't have a "de" translation, it will return the default value'
    body = Translator.translate(article, :de, :body)
    assert body == article.body
  end

  test "raise error wen translating an untraslatable attribute" do
    article = build(:article)
    assert_raise KeyError, fn ->
      Translator.translate(article, :es, :fake_attr)
    end
  end

  test "raise error when no translation container" do
    assert_raise ArgumentError, fn ->
      Translator.translate(%{}, :es, :fake_attr)
    end
  end
end
