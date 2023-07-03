defmodule Trans.TranslatorTest do
  use Trans.TestCase

  alias Trans.Translator

  defmodule ExampleSchema do
    use Ecto.Schema
    use Trans, translates: [:content], default_locale: :en

    embedded_schema do
      field :content, :string
      translations [:es, :fr]
    end
  end

  setup do
    struct = %ExampleSchema{
      content: "Content EN",
      translations: %ExampleSchema.Translations{
        es: %ExampleSchema.Translations.Fields{
          content: "Content ES"
        }
      }
    }

    [struct: struct]
  end

  describe inspect(&Translator.translate/2) do
    test "translates the whole struct to the desired locale", %{struct: struct} do
      translated = Translator.translate(struct, :es)

      assert translated.content == struct.translations.es.content
    end

    test "falls back to the next locale with a custom fallback chain", %{struct: struct} do
      translated = Translator.translate(struct, [:fr, :es])

      assert translated.content == struct.translations.es.content
    end

    test "falls back to the default locale with an unresolved fallback chain", %{struct: struct} do
      translated = Translator.translate(struct, [:fr])

      assert translated.content == struct.content
    end
  end

  describe inspect(&Translator.translate/3) do
    test "translate the field to the desired locale", %{struct: struct} do
      assert Translator.translate(struct, :content, :es) == struct.translations.es.content
    end

    test "falls back to the default locale if translation does not exist", %{struct: struct} do
      assert Translator.translate(struct, :content, :fr) == struct.content
    end

    test "falls back to the next locale in a custom fallback chain", %{struct: struct} do
      assert Translator.translate(struct, :content, [:fr, :es]) ==
               struct.translations.es.content
    end

    test "falls back to the default locale in an unresolved fallback chain", %{struct: struct} do
      assert Translator.translate(struct, :content, [:fr]) == struct.content
    end
  end

  describe inspect(&Translator.translate!/3) do
    test "raises if the translation does not exist", %{struct: struct} do
      expected_error = ~s[translation doesn't exist for field ':content' in locale :fr]

      assert_raise RuntimeError, expected_error, fn ->
        Translator.translate!(struct, :content, :fr)
      end
    end
  end
end
