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

  def with_translation_matching(query, locale, field, expected, opts \\ [])

  # TODO add documentation
  def with_translation_matching(query, locale, field, expected, opts)
  when is_atom(locale) or is_atom(field) do
    with_translation_matching(query, to_string(locale), to_string(field), expected, opts)
  end

  def with_translation_matching(query, locale, field, expected, opts)
  when is_binary(locale) and is_binary(field) do
    translations_container = opts[:container] || :translations
    from translatable in query,
      where: fragment("?->?->>?", field(translatable, ^translations_container), ^locale, ^field) == ^expected
  end

  # TODO add documentation
  def with_translation_like(query, locale, field, pattern, opts \\ [])

  def with_translation_like(query, locale, field, pattern, opts)
  when is_atom(locale) or is_atom(field) do
    with_translation_like(query, to_string(locale), to_string(field), pattern, opts)
  end

  def with_translation_like(query, locale, field, pattern, opts)
  when is_binary(locale) and is_binary(field) do
    translations_container = opts[:container] || :translations
    from translatable in query,
      where: like(fragment("?->?->>?", field(translatable, ^translations_container), ^locale, ^field), ^pattern)
  end

  # TODO add documentation
  def with_translation_ilike(query, locale, field, pattern, opts \\ [])

  def with_translation_ilike(query, locale, field, pattern, opts)
  when is_atom(locale) or is_atom(field) do
    with_translation_ilike(query, to_string(locale), to_string(field), pattern, opts)
  end

  def with_translation_ilike(query, locale, field, pattern, opts)
  when is_binary(locale) and is_binary(field) do
    translations_container = opts[:container] || :translations
    from translatable in query,
      where: ilike(fragment("?->?->>?", field(translatable, ^translations_container), ^locale, ^field), ^pattern)
  end


end
