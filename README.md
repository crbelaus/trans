# Trans

[![Travis](https://img.shields.io/travis/belaustegui/trans.svg?maxAge=2592000&&style=flat-square)](https://travis-ci.org/belaustegui/trans)
[![Hex.pm](https://img.shields.io/hexpm/dt/trans.svg?maxAge=2592000&style=flat-square)](https://hex.pm/packages/trans)

`Trans` provides a way to manage and query translations embedded into schemas
and removes the necessity of maintaing extra tables only for translation storage.

`Trans` is inspired by the great [`hstore translate`](https://github.com/Leadformance/hstore_translate)
gem for Ruby.

`Trans` is published on [hex.pm](https://hex.pm/packages/trans) and the documentation
is also [available online](https://hexdocs.pm/trans/).

## Optional Requirements

Having Ecto and Postgrex in your application will allow you to use the `Trans.QueryBuilder`
component to generate database queries based on translated data.  You can still
use the `Trans.Translator` component without those dependencies though.

- Ecto 2.0 or higher
- PostgreSQL 9.4 or higher (since `Trans` leverages the JSONB datatype)

Support for MySQL JSON type (introduced in MySQL 5.7) will come also, but right
now it is not yet implemented.

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

Trans is lightweight and modularized. The main functionality is provided by the
`Trans.Translator` and the `Trans.QueryBuilder` modules, while the `Trans` module
simplifies the calls to translator and query builder functions from a schema.

## Making a schema translatable

Every translatable schema needs a field in which the translations are stored.
This field is known as the *translation container*.

The first step consists on adding a new column to the schema's table:

```elixir
defmodule MyApp.Repo.Migrations.AddTranslationsToArticles do
  use Ecto.Migration

  def change do
    update table(:articles) do
      add :translations, :map
    end
  end
end
```

The schema must be also updated, so the new column can be automatically mapped
by `Ecto`.

```elixir
defmodule Article do
  use Ecto.Schema

  schema "articles" do
    field :title, :string     # our previous fields...
    field :body, :string      # our previous fields...
    field :translations, :map # this is our translation container
  end
end
```

## Storing translations

Translations are stored as a map of maps in the *translation container* of our
schema.  For example:

```elixir
iex> changeset = Article.changeset(%Article{}, %{
...>   title: "How to Write a Spelling Corrector",
...>   body: "A wonderful article by Peter Norvig",
...>   translations: %{
...>     "es" => %{
...>       title: "Cómo escribir un corrector ortográfico",
...>       body: "Un artículo maravilloso de Peter Norvig"
...>     },
...>     "fr" => %{
...>        title: "Comment écrire un correcteur orthographique",
...>        body: "Un merveilleux article de Peter Norvig"
...>      }
...>   }
...> })

iex> article = Repo.insert!(changeset)
```

## Filtering queries by translations

We may want to fetch articles that are translated into a certain language.  To
do this we may use the `with_translations/3` function of the `Trans.QueryBuilder`
module:

```elixir
iex> Article
...> |> Trans.QueryBuilder.with_translations(:es)
...> |> Repo.all
[debug] SELECT a0."id", a0."title", a0."body", a0."translations"
        FROM "articles" AS a0
        WHERE ((a0."translations"->>$1) is not null) ["es"]
[debug] OK query=4.7ms queue=0.1ms
```

We can also get more specific and fetch only those articles for which their
Spanish title contains the word "Trans".

```elixir
iex> Article
...> |> Trans.QueryBuilder.with_translation(:es, :title, "Trans")
...> |> Repo.all
[debug] SELECT a0."id", a0."title", a0."body", a0."translations"
        FROM "articles" AS a0
        WHERE (a0."translations"->$1->>$2 = $3) ["es", "title", "Trans"]
[debug] OK query=2.6ms queue=0.1ms
```

By default `Trans` looks for an exact match when we add a condition.  We may
also perform a LIKE or ILIKE comparison and use wilcards like this:

```elixir
iex> Article
...> |> Trans.QueryBuilder.with_translation(:es, :title, "%Trans%", type: :like)
...> |> Repo.all
[debug] SELECT a0."id", a0."title", a0."body", a0."translations"
        FROM "articles" AS a0
        WHERE (a0."translations"->$1->>$2 LIKE $3) ["es", "title", "%Trans%"]
[debug] OK query=2.1ms queue=0.1ms
```

## Obtainig translations from a struct

In those examples we will be referring to this article:

```elixir
iex> article = %Article{
...>   title: "How to Write a Spelling Corrector",
...>   body: "A wonderful article by Peter Norvig",
...>   translations: %{
...>     "es" => %{
...>       title: "Cómo escribir un corrector ortográfico",
...>       body: "Un artículo maravilloso de Peter Norvig"
...>     },
...>     "fr" => %{
...>        title: "Comment écrire un correcteur orthographique",
...>        body: "Un merveilleux article de Peter Norvig"
...>      }
...>   }
...> }
```

Once we have already loaded a struct, we may use the `Trans.Translator.translate/4`
function to easily access a translation for a certain field.

```elixir
iex> Article.translate(article, :es, :body)
"Cómo escribir un corrector ortográfico"
```

The `Trans.Translator.translate/4` function also provides a fallback mechanism
that activates when the required translation does not exist:

```elixir
iex> Article.translate(article, :de, :title)
"How to Write a Spelling Corrector" # Fallback to untranslated value
```

## Using a different *translation container*

In the previous examples we have used `translations` as the name of the
*translation container* and `Trans` looks automatically for translations into this
field.

We can also give the *translation container* a different name:

```elixir
defmodule Article do
  use Ecto.Schema

  schema "articles" do
    field :title, :string
    field :body, :string
    field :article_translations, :map # this is our translation container
  end
end
```

We can call the same functions as in previous examples, but we have to specify
the name of the *translation container* to override the default:

```elixir
iex> Article
...> |> Trans.QueryBuilder.with_translation(:es, :title, "Trans", container: :article_translations)
...> |> Repo.all
[debug] SELECT a0."id", a0."title", a0."body", a0."translations"
        FROM "articles" AS a0
        WHERE (a0."article_translations"->$1->>$2 = $3) ["es", "title", "Trans"]
[debug] OK query=2.6ms queue=0.1ms
```

Having to specify the name of the *translation container* everytime is error
prone and can become tiresome.  Instead we can use the `Trans` module in our
schema and have this option specified automatically for us:

```elixir
defmodule Article do
  use Ecto.Schema
  use Trans, defaults: [container: :article_translations],
    translates: [:title, :body]

  schema "articles" do
    field :title, :string
    field :body, :string
    field :article_translations, :map
  end
end
```

Now we can do:

```elixir
iex> Article
...> |> Article.with_translation(:es, :title, "Trans")
...> |> Repo.all
[debug] SELECT a0."id", a0."title", a0."body", a0."translations"
        FROM "articles" AS a0
        WHERE (a0."article_translations"->$1->>$2 = $3) ["es", "title", "Trans"]
[debug] OK query=2.6ms queue=0.1ms
```