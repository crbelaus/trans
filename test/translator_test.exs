alias Trans.Translator

import Trans.Factory

defmodule TranslatorTest do
  use ExUnit.Case

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
    expected_message = "'fake_attr' is not translatable. Translatable fields are [:title, :body]"
    assert_raise RuntimeError, expected_message, fn ->
      Translator.translate(build(:article), :es, :fake_attr)
    end
  end

end
