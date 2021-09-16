alias Trans.Translator

import Trans.Factory

defmodule TranslatorTest do
  use ExUnit.Case

  test "retrieve translation for existing attribute using locale as atom" do
    article = build(:article)
    fr_body = Translator.translate(article, :body, :fr)
    assert fr_body == article.translations["fr"]["body"]
  end

  test "retrieve translation for existing attribute using locale as string" do
    article = build(:article)
    fr_body = Translator.translate(article, :body, "fr")
    assert fr_body == article.translations["fr"]["body"]
  end

  test "retrieve translation using translate! for existing attribute using locale as string" do
    article = build(:article)
    fr_body = Translator.translate!(article, :body, "fr")
    assert fr_body == article.translations["fr"]["body"]
  end

  test "fallback to default value when no translation available" do
    article = build(:article)
    # Since we don't have a "de" translation, it will return the default value'
    body = Translator.translate(article, :body, :de)
    assert body == article.body
  end

  test "raise error when no translation available" do
    article = build(:article)
    # Since we don't have a "de" translation, translate! will raise an error'

    assert_raise RuntimeError,
                 "translation doesn't exist for field ':body' in language 'de'",
                 fn ->
                   Translator.translate!(article, :body, :de)
                 end
  end

  test "use custom translation container if required" do
    comment = build(:comment)
    assert Translator.translate(comment, :comment, :es) == comment.transcriptions["es"]["comment"]
  end

  test "raise error wen translating an untraslatable attribute" do
    assert_raise RuntimeError,
                 "'Trans.Article' module must declare ':fake_attr' as translatable",
                 fn ->
                   Translator.translate(build(:article), :fake_attr, :es)
                 end
  end

  test "translates the whole struct at once" do
    article = build(:article)
    fr_article = Translator.translate(article, :fr)
    assert fr_article.title == article.translations["fr"]["title"]
    assert fr_article.body == article.translations["fr"]["body"]
  end

  test "translates the nested structs" do
    %{comments: [comment | _]} = article = build(:article)
    %{comments: [fr_comment | _]} = Translator.translate(article, :fr)
    assert fr_comment.comment == comment.transcriptions["fr"]["comment"]
  end
end
