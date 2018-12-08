defmodule Trans do
  @moduledoc ~S"""
  `Trans` provides a way to manage and query translations embedded into schemas
  and removes the necessity of maintaining extra tables only for translation
  storage.

  ## What does this package do?

  `Trans` allows you to store translations for a struct embedded into a field of
  that struct itself.

  `Trans` is split into two main components:

  - `Trans.Translator` - allows to easily access translated values from structs
  and automatically fallbacks to the default value when the translation does
  not exist in the required locale.
  - `Trans.QueryBuilder` - adds conditions to `Ecto.Query` for filtering values
  of translated fields. This module will be available only if `Ecto.SQL` is available.

  `Trans` shines when paired with an `Ecto.Schema`. It allows you to keep the
  translations into a field of the schema and avoids requiring extra tables for
  translation storage and complex _joins_ when retrieving translations from the
  database.

  ## What does this module do?

  This module provides the required metadata for `Trans.Translator` and
  `Trans.QueryBuilder` modules. You can use `Trans` in your module like in the
  following example (usage of `Ecto.Schema` and schema declaration are optional):

      defmodule Article do
        use Ecto.Schema
        use Trans, translates: [:title, :body]

        schema "articles" do
          field :title, :string
          field :body, :text
          field :translations, :map
        end
      end

  When used, `Trans` will define a `__trans__` function that can be used for
  runtime introspection of the translation metadata.

  - `__trans__(:fields)` - Returns the list of translatable fields. Fields
  declared as translatable must be present in the module's schema or struct declaration.
  - `__trans__(:container)` - Returns the name of the _translation container_ field.
  To learn more about the _translation container_ field see the following section.

  ## The translation container

  By default, `Trans` stores and looks for translations in a field named
  `translations`. This field is known as the translations container.

  If you need to use a different field name for storing translations, you can
  specify it when using `Trans` from your module. In the following example,
  `Trans` will store and look for translations in the field `locales`.

      defmodule Article do
        use Ecto.Schema
        use Trans, translates: [:title, :body], container: :locales

        schema "articles" do
          field :title, :string
          field :body, :text
          field :locales, :map
        end
      end
  """

  defmacro __using__(opts) do
    quote do
      Module.put_attribute(__MODULE__, :trans_fields, unquote(translatable_fields(opts)))
      Module.put_attribute(__MODULE__, :trans_container, unquote(translation_container(opts)))

      @after_compile {Trans, :__validate_translatable_fields__}
      @after_compile {Trans, :__validate_translation_container__}

      @spec __trans__(:fields) :: list(atom)
      def __trans__(:fields), do: @trans_fields

      @spec __trans__(:container) :: atom
      def __trans__(:container), do: @trans_container
    end
  end

  @doc """
  Checks whether the given field is translatable or not.

  **Important:** This function will raise an error if the given module does
  not use `Trans`.

  ## Usage example

  Imagine that we have an _Article_ schema declared as follows:

      defmodule Article do
        use Ecto.Schema
        use Trans, translates: [:title, :body]

        schema "articles" do
          field :title, :string
          field :body, :string
          field :translations, :map
        end
      end

  If we want to know whether a certain field is translatable or not we can use
  this function as follows (we can also pass a struct instead of the module
  name itself):

      iex> Trans.translatable?(Article, :title)
      true
      iex> Trans.translatable?(%Article{}, :not_existing)
      false
  """
  @spec translatable?(module | struct, String.t() | atom) :: boolean
  def translatable?(%{__struct__: module}, field), do: translatable?(module, field)

  def translatable?(module_or_struct, field)
      when is_atom(module_or_struct) and is_binary(field) do
    translatable?(module_or_struct, String.to_atom(field))
  end

  def translatable?(module_or_struct, field) when is_atom(module_or_struct) and is_atom(field) do
    if Keyword.has_key?(module_or_struct.__info__(:functions), :__trans__) do
      Enum.member?(module_or_struct.__trans__(:fields), field)
    else
      raise "#{module_or_struct} must use `Trans` in order to be translated"
    end
  end

  @doc false
  def __validate_translatable_fields__(%{module: module}, _bytecode) do
    struct_fields =
      module.__struct__()
      |> Map.keys()
      |> MapSet.new()

    translatable_fields =
      :fields
      |> module.__trans__
      |> MapSet.new()

    invalid_fields = MapSet.difference(translatable_fields, struct_fields)

    case MapSet.size(invalid_fields) do
      0 ->
        nil

      1 ->
        raise ArgumentError,
          message:
            "#{module} declares '#{MapSet.to_list(invalid_fields)}' as translatable but it is not defined in the module's struct"

      _ ->
        raise ArgumentError,
          message:
            "#{module} declares '#{MapSet.to_list(invalid_fields)}' as translatable but it they not defined in the module's struct"
    end
  end

  @doc false
  def __validate_translation_container__(%{module: module}, _bytecode) do
    container = module.__trans__(:container)

    unless Enum.member?(Map.keys(module.__struct__()), container) do
      raise ArgumentError,
        message:
          "The field #{container} used as the translation container is not defined in #{module} struct"
    end
  end

  defp translatable_fields(opts) do
    case Keyword.fetch(opts, :translates) do
      {:ok, fields} when is_list(fields) ->
        fields

      _ ->
        raise ArgumentError,
          message:
            "Trans requires a 'translates' option that contains the list of translatable fields names"
    end
  end

  defp translation_container(opts) do
    case Keyword.fetch(opts, :container) do
      :error -> :translations
      {:ok, container} -> container
    end
  end
end
