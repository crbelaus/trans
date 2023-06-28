defmodule TransTest do
  require Trans
  use Trans.TestCase

  defmodule DefaultContainer do
    use Ecto.Schema
    use Trans, translates: [:content], default_locale: :en

    embedded_schema do
      field :content, :string
      field :metadata, :map
      translations [:es, :fr]
    end
  end

  test "with default container" do
    assert Trans.translatable?(DefaultContainer, :content)
    refute Trans.translatable?(DefaultContainer, :metadata)

    assert DefaultContainer.__trans__(:default_locale) == :en
    assert DefaultContainer.__trans__(:container) == :translations

    assert {
             :parameterized,
             Ecto.Embedded,
             %Ecto.Embedded{
               cardinality: :one,
               field: :translations,
               on_cast: nil,
               on_replace: :update,
               ordered: true,
               owner: DefaultContainer,
               related: DefaultContainer.Translations,
               unique: true
             }
           } = DefaultContainer.__schema__(:type, :translations)

    assert [:es, :fr] = DefaultContainer.Translations.__schema__(:fields)
    assert [:content] = DefaultContainer.Translations.Fields.__schema__(:fields)
  end

  defmodule CustomContainer do
    use Ecto.Schema
    use Trans, translates: [:content], default_locale: :en, container: :transcriptions

    embedded_schema do
      field :content, :string
      field :metadata, :map
      translations [:es, :fr]
    end
  end

  test "with custom container" do
    assert Trans.translatable?(CustomContainer, :content)
    refute Trans.translatable?(CustomContainer, :metadata)

    assert CustomContainer.__trans__(:default_locale) == :en
    assert CustomContainer.__trans__(:container) == :transcriptions

    assert {
             :parameterized,
             Ecto.Embedded,
             %Ecto.Embedded{
               cardinality: :one,
               field: :transcriptions,
               on_cast: nil,
               on_replace: :update,
               ordered: true,
               owner: CustomContainer,
               related: CustomContainer.Translations,
               unique: true
             }
           } = CustomContainer.__schema__(:type, :transcriptions)

    assert [:es, :fr] = CustomContainer.Translations.__schema__(:fields)
    assert [:content] = CustomContainer.Translations.Fields.__schema__(:fields)
  end

  defmodule CustomSchema do
    use Ecto.Schema
    use Trans, translates: [:content], default_locale: :en

    defmodule Translations.Fields do
      use Ecto.Schema

      @primary_key false
      embedded_schema do
        field :content, :string
      end
    end

    embedded_schema do
      field :content, :string
      field :metadata, :map
      translations [:es, :fr], build_field_schema: false
    end
  end

  test "with custom schema" do
    assert Trans.translatable?(CustomSchema, :content)
    refute Trans.translatable?(CustomSchema, :metadata)

    assert CustomSchema.__trans__(:default_locale) == :en
    assert CustomSchema.__trans__(:container) == :translations

    assert {
             :parameterized,
             Ecto.Embedded,
             %Ecto.Embedded{
               cardinality: :one,
               field: :translations,
               on_cast: nil,
               on_replace: :update,
               ordered: true,
               owner: CustomSchema,
               related: CustomSchema.Translations,
               unique: true
             }
           } = CustomSchema.__schema__(:type, :translations)

    assert [:es, :fr] = CustomSchema.Translations.__schema__(:fields)
    assert [:content] = CustomSchema.Translations.Fields.__schema__(:fields)
  end
end
