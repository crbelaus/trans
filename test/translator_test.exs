alias Trans.Translator

import Trans.Factory

defmodule TranslatorTest do
  use ExUnit.Case

  test "retrieve translation for existing attribute" do
    article = build(:article)
    fr_body = Translator.translate(article, :body, :fr)
    assert fr_body == article.translations["fr"]["body"]
  end

  test "fallback to default value when no translation available" do
    article = build(:article)
    # Since we don't have a "de" translation, it will return the default value'
    body = Translator.translate(article, :body, :de)
    assert body == article.body
  end

  test "use custom translation container if required" do
    comment = build(:comment)
    assert Translator.translate(comment, :comment, :es) == comment.transcriptions["es"]["comment"]
  end

  test "raise error wen translating an untraslatable attribute" do
    assert_raise RuntimeError, "'Trans.Article' module must declare ':fake_attr' as translatable", fn ->
      Translator.translate(build(:article), :fake_attr, :es)
    end
  end

end
