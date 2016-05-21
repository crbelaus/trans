defmodule Trans.QueryBuilder do
  import Ecto.Query, only: [from: 2]

  # TODO add documentation
  def with_translations(query, locale, opts \\ [])

  def with_translations(query, locale, opts) when is_atom(locale) do
    with_translations(query, to_string(locale), opts)
  end

  def with_translations(query, locale, opts) when is_binary(locale) do
    translations_container = opts[:container] || :translations
    from translatable in query,
      where: fragment("(?->>?) is not null", field(translatable, ^translations_container), ^locale)
  end

  # TODO with_translation
  def with_translation(query, locale, field, expected, opts \\ [])

  def with_translation(query, locale, field, expected, opts)
  when is_atom(locale) or is_atom(field) do
    with_translation(query, to_string(locale), to_string(field), expected, opts)
  end

  def with_translation(query, locale, field, expected, opts)
  when is_binary(locale) and is_binary(field) do
    container = opts[:container] || :translations
    case opts[:type] do
      :like -> with_translation_like(query, locale, field, expected, container)
      :ilike -> with_translation_ilike(query, locale, field, expected, container)
      _ -> with_translation_matching(query, locale, field, expected, container)
    end
  end

  defp with_translation_matching(query, locale, field, expected, container) do
    from translatable in query,
      where: fragment("?->?->>?", field(translatable, ^container), ^locale, ^field) == ^expected
  end

  defp with_translation_like(query, locale, field, expected, container) do
    from translatable in query,
      where: like(fragment("?->?->>?", field(translatable, ^container), ^locale, ^field), ^expected)
  end

  def with_translation_ilike(query, locale, field, expected, container) do
    from translatable in query,
      where: ilike(fragment("?->?->>?", field(translatable, ^container), ^locale, ^field), ^expected)
  end


end
