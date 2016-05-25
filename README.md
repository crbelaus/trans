# What is Trans?
[![Build Status](https://api.travis-ci.org/belaustegui/trans.svg?branch=master)](https://travis-ci.org/belaustegui/trans)

Trans is a library that helps you managing embedded model translations.
Trans is inspired by the great [hstore translate](https://github.com/Leadformance/hstore_translate) gem for Ruby.

**IMPORTANT**: for the moment, **Trans query building works only with PostgreSQL**, since the queries use
the special operators for JSONB. Keep this in mind if you want to find models filtering from translated
attributes.

## Why Trans?

The traditional approach to content internationalization consists of using an additional
table for each translatable model, this table contains the model translations. For example,
we may have a `posts` and `posts_translations` tables.

Trans provides a different approach based on modern RDBMSs support for unstructured data.
Each translatable model can have a field (stored as a column in the database) that contains
its translations in the form of a dictionary. This approach allows us to reduce table joins,
specially when the number of translatable models and instances gets bigger.

Trans is lightweight and modularized. The main functionality is provided by the `Trans.Translator` and the `Trans.QueryBuilder` modules. The `Trans` module simplifies the calls to translator and query builder functions from a model.

## How can I use Trans?

### Adding translations to a model

The first step consists on adding a new column to the desired table. This column will be known as the **translation container**.

```elixir
defmodule MyApp.Repo.Migrations.AddTranslationsColumn do
  use Ecto.Migration

  def change do
    update table(:articles) do
      add :translations, :map
    end
  end
end
```

The model's schema must be also updated, so it can be mapped by Ecto.

```elixir
defmodule MyApp.Article do
  use Ecto.Schema

  schema "articles" do
    ... # Previous fields
    field :title, :string
    field :body, :string
    field :author, :string
    field :translations, :map # This field will contain our translations
  end
end
```

### Using helper functions

Trans provides two kind of helper functions:

  * Content translation accessors, provided by the `Trans.Translator` module.
  * Helpers for query construction, provided by the `Trans.QueryBuilder` module.

The functions provided by those two modules can be used with **any** model.

If a certain model has some special configuration (for example, the translation container
field is named `translations_container` instead of simply `translations`) it may be
tiresome to manually specify this on every call.  To avoid this unnecesary repetition,
we can use the `Trans` module, which provides a nice way of specifying default options
that will be automatically passed to `Trans.Translator` and `Trans.QueryBuilder`.

You can use the `Trans` module in your model like this:

```elixir
defmodule MyApp.Article do
  # ...
  use Trans, container: :translations
  # ...
end
```

If our translations container field is called `translations`, we can omit the `container: :translations` option.

### Storing translations

Translations are stored as a map of maps in the translation container field. For example

```elixir

translations = %{
  "es" => %{"title" => "¿Por qué Trans es genial?", "body" => "Disertación sobre la genialidad de Trans"},
  "fr" => %{"title" => "Pourquoi Trans est grande?", "body" => "Dissertation sur le génie de Trans"}
}

changeset = Article.changeset(%Article{}, %{
  title: "Why Trans is great",
  body: "An explanation about the Trans greatness",
  author: "Cristian Álvarez Belaustegui",
  translations: translations
})

article = Repo.insert!(changeset)

```

### Querying translations

We may need to get articles that are translated into a certain language. To do this we may
use the `Trans.QueryBuilder.with_translations/3` function (or the helper provided by `Trans` in our model).

```elixir
articles_translated_to_spanish = Article |> Article.with_translations(:es) |> Repo.all
# SELECT a0."id", a0."title", a0."body", a0."translations", a0."author" FROM "articles" AS a0 WHERE (a0."translations"->>$1) is not null) ["es"] OK query=17.1ms queue=0.1ms
```

We may also want to get articles for which their french title contains "Trans".

```elixir
articles = Article |> Article.with_translation(:fr, :title, "%Trans%", type: :like)
# [debug] SELECT a0."id", a0."title", a0."body", a0."translations", a0."author" FROM "articles" AS a0 WHERE (a0."translations"->$1->>$2 LIKE $3) ["fr", "title", "%Trans%"] OK query=2.1ms queue=0.1ms
```

The `Trans.QueryBuilder.with_translation/5` function supports three types of comparisons:

* If no type is specified, the query will look for an exact match.
* For a case-sensitive pattern comparison use `type: :like`
* For a case-insensitive pattern comparison use `type: :ilike`

### Translating fields

When we have a model struct, we can use the `Trans.Translator.translate/4` (or the equivalent helper provided by `Trans`) function to easily load
a certain translation.

```elixir
Article.translate(article, :es, :body) # "Disertación sobre la genialidad de Trans"
```

The `Trans.Translator.translate/3` function also provides a fallback mechanism for when
non existant translations are accessed:

```elixir
Article.translate(article, :de, :title) # Fallback to untranslated value: "Why Trans is great"
```

Since the translation container is a simple map, we can always access its values manually:

```elixir
article.translations["es"]["body"] # "Disertación sobre la genialidad de Trans"
```
