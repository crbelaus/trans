defmodule Trans.TranslatorTest do
  use Trans.TestCase

  import Trans.Translator

  describe "with embedded schema translations" do
    setup do
      # Only has translations for :es and :fr
      [article: build(:article)]
    end

    test "translate/3 returns the translation of a field",
         %{article: article} do
      assert translate(article, :body, :fr) == article.translations.fr.body
    end

    test "translate/3 falls back to the default value if the field is not translated",
         %{article: article} do
      assert translate(article, :body, :de) == article.body
    end

    test "translate!/3 fails if the field is not translated",
         %{article: article} do
      expected_error = "translation doesn't exist for field ':body' in language 'de'"

      assert_raise RuntimeError, expected_error, fn ->
        translate!(article, :body, :de)
      end
    end

    test "translate/2 translates the whole struct",
         %{article: article} do
      fr_article = translate(article, :fr)

      assert fr_article.title == article.translations.fr.title
      assert fr_article.body == article.translations.fr.body

      for {fr_comment, index} <- Enum.with_index(fr_article.comments) do
        original_comment = Enum.at(fr_article.comments, index)
        assert fr_comment.comment == original_comment.transcriptions["fr"]["comment"]
      end
    end

    test "translate/2 falls back to the default locale if the translation does not exist",
         %{article: article} do
      de_article = translate(article, :de)

      assert de_article.title == article.title
      assert de_article.body == article.body

      for {de_comment, index} <- Enum.with_index(de_article.comments) do
        original_comment = Enum.at(de_article.comments, index)
        assert de_comment.comment == original_comment.comment
      end
    end
  end

  describe "with free map translations" do
    setup do
      # Only has translations for :es and :fr
      [comment: build(:comment)]
    end

    test "translate/3 returns the translation of a field",
         %{comment: comment} do
      assert translate(comment, :comment, :es) == comment.transcriptions["es"]["comment"]
    end

    test "translate/3 falls back to the default value if the field is not translated",
         %{comment: comment} do
      assert translate(comment, :comment, :non_existing_locale) == comment.comment
    end

    test "translate!/3 fails if the field is not translated",
         %{comment: comment} do
      expected_error = "translation doesn't exist for field ':comment' in language 'de'"

      assert_raise RuntimeError, expected_error, fn ->
        translate!(comment, :comment, :de)
      end
    end

    test "translate/2 translates the whole struct",
         %{comment: comment} do
      fr_comment = translate(comment, :fr)

      assert fr_comment.comment == comment.transcriptions["fr"]["comment"]
    end
  end
end
