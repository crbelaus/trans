# Trans

[![Tests](https://github.com/crbelaus/trans/actions/workflows/ci.yml/badge.svg)](https://github.com/crbelaus/trans/actions/workflows/ci.yml/badge.svg)
[![Hex.pm](https://img.shields.io/hexpm/dt/trans.svg?maxAge=2592000&style=flat-square)](https://hex.pm/packages/trans)

`Trans` provides a way to manage and query translations embedded into schemas
and removes the necessity of maintaining extra tables only for translation storage.
It is inspired by the great [hstore translate](https://rubygems.org/gems/hstore_translate)
gem for Ruby.

`Trans` is published on [hex.pm](https://hex.pm/packages/trans) and the documentation
is also [available online](https://hexdocs.pm/trans/). Source code is available in this same
repository under the Apache2 License.

On April 17th, 2017, `Trans` was [featured in HackerNoon](https://hackernoon.com/introducing-trans2-407610887068)


## Optional Requirements

Having Ecto SQL and Postgrex in your application will allow you to use the `Trans.QueryBuilder`
component to generate database queries based on translated data.  You can still
use the `Trans.Translator` component without those dependencies though.

- [Ecto SQL](https://hex.pm/packages/ecto_sql) 3.0 or higher
- [PostgreSQL](https://hex.pm/packages/postgrex) 9.4 or higher (since `Trans` leverages the JSONB datatype)


## Why Trans?

The traditional approach to content internationalization consists on using an
additional table for each translatable schema. This table works only as a storage
for the original schema translations. For example, we may have a `posts` and
a `posts_translations` tables.

This approach has a few disadvantages:

- It complicates the database schema because it creates extra tables that are
  coupled to the "main" ones.
- It makes migrations and schemas more complicated, since we always have to keep
  the two tables in sync.
- It requires constant JOINs in order to filter or fetch records along with their
  translations.

The approach used by `Trans` is based on modern RDBMSs support for unstructured
datatypes.  Instead of storing the translations in a different table, each
translatable schema has an extra column that contains all of its translations.
This approach drastically reduces the number of required JOINs when filtering or
fetching records.

`Trans` is lightweight and modularized. The `Trans` module provides metadata
that is used by the `Trans.Translator` and `Trans.QueryBuilder` modules, which
implement the main functionality of this library.


## Setup and Quickstart

Let's say that we have an `Article` schema that contains texts in English and we want to translate it to other languages.

```elixir
defmodule MyApp.Article do
  use Ecto.Schema

  schema "articles" do
    field :title, :string
    field :body, :string
  end
end
```

The first step would be to add a new JSONB column to the table so we can store the translations in it.

```elixir
defmodule MyApp.Repo.Migrations.AddTranslationsToArticles do
  use Ecto.Migration

  def change do
    alter table(:articles) do
      add :translations, :map
    end
  end
end
```

Once we have the new database column, we can update the Article schema to include the translations.

```elixir
defmodule MyApp.Article do
  use Ecto.Schema
  use Trans, translates: [:title, :body], default_locale: :en

  schema "articles" do
    field :title, :string
    field :body, :string

    # This generates a MyApp.Article.Translations schema with a
    # MyApp.Article.Translations.Fields for :es and :fr
    translations [:es, :fr]
  end
end
```

After doing this we can leverage the [Trans.Translator](https://hexdocs.pm/trans/Trans.Translator.html) and [Trans.QueryBuilder](https://hexdocs.pm/trans/Trans.QueryBuilder.html) modules to fetch and query translations from the database.

The translation storage can be done using normal `Ecto.Changeset` functions just like it would be done for any other fields or associations.

```elixir
defmodule MyApp.Article do
  def changeset(article, attrs \\ %{}) do
    article
    |> cast(attrs, [:title, :body])
    |> validate_required([:title, :body])
    |> cast_embed(:translations, with: &cast_translations/2)
  end

  defp cast_translations(translations, attrs \\ %{}) do
    translations
    |> cast(attrs, [])
    |> cast_embed(:es)
    |> cast_embed(:fr)
  end
end

# Then, anywhere in your code:
changeset = MyApp.Article.changeset(article, %{
  translations: %{
    es: %{title: "title ES", body: "body ES"},
    fr: %{title: "title FR", body: "body FR"}
  }
})
```

## Customizing the translation container

By default Trans looks for a `translations` field that contains the translations. This is known as the "translation container".

You can override the default translation container passing the `container` option to Trans. In the following example the translations will be stored in the `transcriptions` field.

```elixir
defmodule MyApp.Article do
  use Ecto.Schema
  use Trans, translates: [:title, :body], default_locale: :en, container: :transcriptions

  schema "articles" do
    field :title, :string
    field :body, :strings
    translations [:es, :fr]
  end
end
```

## Customizing the translation schemas

If you want to use your own translation module you can simply pass the `build_field_schema: false` option when using the `translations` macro.

```elixir
defmodule MyApp.Article do
  use Ecto.Schema
  use Trans, translates: [:title, :body], default_locale: :en

  defmodule Translations.Fields do
    use Ecto.Schema

    embedded_schema do
      field :title, :string
      field :body, :string
    end
  end

  schema "articles" do
    field :title, :string
    field :body, :string

    translations [:es, :fr], build_field_schema: false
  end
end
```


## Is Trans dead?

Trans has a slow release cadence, but that does not mean that it is dead. Trans can be considered as "done" in the sense that it does one thing and does it well.

New releases will happen when there are bugs or new changes. **If the last release is from a long time ago you should take this as a sign of stability and maturity, not as a sign of abandonment.**
