defmodule Trans.QueryBuilderTest do
  use Trans.TestCase

  import Trans.QueryBuilder

  alias Trans.Repo

  defmodule DefaultContainer do
    use Ecto.Schema
    use Trans, translates: [:content], default_locale: :en

    schema "default_translation_container" do
      field :content, :string
      translations [:es, :fr, :de]
    end
  end

  describe "default container" do
    setup do
      translated_struct =
        Repo.insert!(%DefaultContainer{
          content: "Content EN",
          translations: %DefaultContainer.Translations{
            es: %DefaultContainer.Translations.Fields{
              content: "Content ES"
            },
            fr: %DefaultContainer.Translations.Fields{
              content: "Content FR"
            }
          }
        })

      untranslated_struct =
        Repo.insert!(%DefaultContainer{
          content: "Untranslated Content EN",
          translations: %DefaultContainer.Translations{}
        })

      [translated_struct: translated_struct, untranslated_struct: untranslated_struct]
    end

    test "should find only one struct translated to ES" do
      query =
        from dc in DefaultContainer,
          where: not is_nil(translated(DefaultContainer, dc, :es))

      assert Repo.aggregate(query, :count) == 1
    end

    test "should not find any struct translated to DE" do
      query =
        from dc in DefaultContainer,
          where: not is_nil(translated(DefaultContainer, dc, :de))

      refute Repo.exists?(query)
    end

    test "should find one struct translated to ES falling back from DE" do
      query =
        from dc in DefaultContainer,
          where: not is_nil(translated(DefaultContainer, dc, [:de, :es]))

      assert Repo.aggregate(query, :count) == 1
    end

    test "should find no struct translated to DE falling back from RU since neither exist" do
      query =
        from dc in DefaultContainer,
          where: not is_nil(translated(DefaultContainer, dc, [:ru, :de]))

      refute Repo.exists?(query)
    end

    # This is an example where we use `NULLIF(value, 'null')` to
    # standardise on using SQL NULL in all cases where there is no data.
    test "that a valid locale that has no translations returns nil (not 'null')" do
      query =
        from dc in DefaultContainer,
          where: is_nil(translated(DefaultContainer, dc, :it))

      assert Repo.aggregate(query, :count) == 2
    end

    test "that a valid locale that has no translations returns nil for locale chain" do
      query =
        from dc in DefaultContainer,
          where: not is_nil(translated(DefaultContainer, dc, [:de]))

      refute Repo.exists?(query)
    end

    test "should find all structs falling back from DE since EN is default" do
      query =
        from dc in DefaultContainer,
          where: not is_nil(translated(DefaultContainer, dc.content, [:de, :en]))

      assert Repo.aggregate(query, :count) == 2
    end

    test "should find all structs with dynamic fallback chain" do
      query =
        from dc in DefaultContainer,
          where: not is_nil(translated(DefaultContainer, dc.content, [:es, :fr]))

      assert Repo.aggregate(query, :count) == 2
    end

    test "should select all structs with dynamic fallback chain" do
      result =
        Repo.all(
          from dc in DefaultContainer,
            select: translated_as(DefaultContainer, dc.content, [:es, :fr]),
            where: not is_nil(translated(DefaultContainer, dc.content, [:es, :fr]))
        )

      assert length(result) == 2
    end

    test "select the translated (or base) column falling back from unknown DE to default EN",
         %{translated_struct: translated_struct, untranslated_struct: untranslated_struct} do
      result =
        Repo.all(
          from dc in DefaultContainer,
            select: translated_as(DefaultContainer, dc.content, [:de, :en]),
            where: not is_nil(translated(DefaultContainer, dc.content, [:de, :en]))
        )

      assert result == [translated_struct.content, untranslated_struct.content]
    end

    test "select translations for a valid locale with no data should return the default",
         %{translated_struct: translated_struct, untranslated_struct: untranslated_struct} do
      result =
        Repo.all(
          from dc in DefaultContainer,
            select: translated_as(DefaultContainer, dc.content, :it)
        )

      assert result == [translated_struct.content, untranslated_struct.content]
    end

    test "select translations for a valid locale with no data should fallback to the default" do
      results =
        Repo.all(
          from adc in DefaultContainer,
            select: translated_as(DefaultContainer, adc.content, [:de, :en])
        )

      for result <- results do
        assert result =~ "Content EN"
      end
    end

    test "should find a struct by its FR title", %{translated_struct: struct} do
      matches =
        Repo.all(
          from dc in DefaultContainer,
            where:
              translated(DefaultContainer, dc.content, :fr) == ^struct.translations.fr.content,
            select: dc.id
        )

      assert matches == [struct.id]
    end

    test "should not find a struct by a non existent translation" do
      query =
        from dc in DefaultContainer,
          where: translated(DefaultContainer, dc.content, :es) == "FAKE TITLE"

      refute Repo.exists?(query)
    end

    test "should find an struct by partial and case sensitive translation",
         %{translated_struct: struct} do
      matches =
        Repo.all(
          from dc in DefaultContainer,
            where: ilike(translated(DefaultContainer, dc.content, :es), "%ES%"),
            select: dc.id
        )

      assert matches == [struct.id]
    end

    test "should raise when adding conditions to an untranslatable field" do
      # Since the QueryBuilder errors are emitted during compilation, we do a
      # little trick to delay the compilation of the query until the test
      # is running, so we can catch the raised error.
      invalid_module =
        quote do
          defmodule TestWrongQuery do
            require Ecto.Query
            import Ecto.Query, only: [from: 2]

            def invalid_query do
              from dc in DefaultContainer,
                where: not is_nil(translated(DefaultContainer, dc.translations, :es))
            end
          end
        end

      expected_error =
        "'Trans.QueryBuilderTest.DefaultContainer' module must declare 'translations' as translatable"

      assert_raise ArgumentError, expected_error, fn -> Code.eval_quoted(invalid_module) end
    end
  end

  defmodule CustomContainer do
    use Ecto.Schema
    use Trans, translates: [:content], default_locale: :en, container: :transcriptions

    schema "custom_translation_container" do
      field :content, :string
      translations [:es, :fr, :de]
    end
  end

  describe "custom container" do
    setup do
      struct =
        Repo.insert!(%CustomContainer{
          content: "Content EN",
          transcriptions: %CustomContainer.Translations{
            es: %CustomContainer.Translations.Fields{
              content: "Content ES"
            }
          }
        })

      [struct: struct]
    end

    test "uses the custom container automatically", %{struct: struct} do
      query =
        from cc in CustomContainer,
          where: translated(CustomContainer, cc.content, :es) == ^struct.transcriptions.es.content

      assert Repo.exists?(query)
    end
  end
end
