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
      expected_error = "translation doesn't exist for field ':body' in locale :de"

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
      expected_error = "translation doesn't exist for field ':comment' in locale :de"

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

  describe "with default locale" do
    setup do
      # Only has translations for :es and :fr
      [book: build(:book)]
    end

    test "has a default locale of :en" do
      assert Trans.Book.__trans__(:default_locale) == :en
    end

    test "translate/2 translates the whole book struct",
         %{book: book} do
      fr_book = translate(book, :fr)

      assert fr_book.title == book.translations.fr.title
      assert fr_book.body == book.translations.fr.body
    end

    test "translate/2 translates the whole book struct to the default locale",
         %{book: book} do
      en_book = translate(book, :de)

      assert en_book.title == book.title
      assert en_book.body == book.body

      en_book = translate(book, [:de])

      assert en_book.title == book.title
      assert en_book.body == book.body
    end

    test "translate/2 translates the whole book struct via a fallback chain",
         %{book: book} do
      fr_book = translate(book, [:de, :fr, :en])

      assert fr_book.title == book.translations.fr.title
      assert fr_book.body == book.translations.fr.body
    end

    test "translate/2 translates the book to the default locale in a fallback chain",
         %{book: book} do
      en_book = translate(book, [:de, :en, :fr])

      assert en_book.title == book.title
      assert en_book.body == book.body
    end

    test "translate/2 translates the book to the default locale in an unresolved fallback chain",
         %{book: book} do
      en_book = translate(book, [:de, :it])

      assert en_book.title == book.title
      assert en_book.body == book.body
    end
  end
end
