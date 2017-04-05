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
now it is not yet implemented at the database adapter level.

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

Then we must use `Trans` from our schema module to indicate which fields will
be translated.

```elixir
defmodule Article do
  use Ecto.Schema
  use Trans, translates: [:title, :body]

  schema "articles" do
    field :title, :string
    field :body, :string
    field :translations, :map
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
do this we use the `Trans.QueryBuilder.translated/3` macro, which generates the
required SQL fragment for us.

```elixir
iex> Repo.all(from a in Article,
...>   where: not is_nil(translated(Article, a, :es)))
# SELECT a0."id", a0."title", a0."body", a0."translations"
#         FROM "articles" AS a0
#        WHERE (NOT ((a0."translations"->"es") IS NULL))
```

We can also get more specific and fetch only those articles for which their
Spanish title matches "Elixir".

```elixir
iex> Repo.all(from a in Article,
...>   where: translated(Article, a.title, :es) == "Elixir")
# SELECT a0."id", a0."title", a0."body", a0."translations"
# FROM "articles" AS a0
# WHERE ((a0."translations"->"fr"->>"title") = "Elixir")
```

The SQL fragment generated by the `Trans.QueryBuilder.translated/3` macro is
compatible with the rest of functions and macros provided by `Ecto.Query` and
`Ecto.Query.Api`.

```elixir
iex> Repo.all(from a in Article,
...> where: ilike(translated(Article, a.body, :es), "%elixir%"))
# SELECT a0."id", a0."title", a0."body", a0."translations"
# FROM "articles" AS a0
# WHERE ((a0."translations"->"es"->>"body") ILIKE "%elixir%")
```

More complex queries such as adding conditions to joined schemas can be easily
generated in the same way. Take a look at the documentation and tests for more
examples.

## Obtaining translations from a struct

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

Once we have already loaded a struct, we may use the `Trans.Translator.translate/3`
function to easily access a translation of a certain field.

```elixir
iex> Trans.Translator.translate(article, :title, :es)
"Cómo escribir un corrector ortográfico"
```

The `Trans.Translator.translate/3` function also provides a fallback mechanism
that activates when the required translation does not exist:

```elixir
iex> Trans.Translator.translate(article, :title, :de)
"How to Write a Spelling Corrector"
```

## Using a different *translation container*

In the previous examples we have used `translations` as the name of the
*translation container* and `Trans` looks automatically for translations into this
field.

We can also give the *translation container* a different name, for example
**article_translations**:

```elixir
defmodule Article do
  use Ecto.Schema
  use Trans, translates: [:title, :body], container: :article_translations

  schema "articles" do
    field :title, :string
    field :body, :string
    field :article_translations, :map
  end
end
```

We can call the same functions as in previous examples and both `Trans.Translator`
and `Trans.QueryBuilder` will automatically look for translations in the correct field.

```elixir
iex> Repo.all(from a in Article,
...>   where: not is_nil(translated(Article, a, :es)))
# SELECT a0."id", a0."title", a0."body", a0."article_translations"
#         FROM "articles" AS a0
#        WHERE (NOT ((a0."article_translations"->"es") IS NULL))
```
