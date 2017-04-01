defmodule Trans do
  @moduledoc ~S"""
  `Trans` provides a way to manage and query translations embedded into schemas
  and removes the necessity of maintaining extra tables only for translation
  storage.

  ## What does this package do?

  `Trans` allows you to store translations of a struct embedded into a filed of
  that struct.

  Trans is split into two main components:

  - `Trans.Translator` - allows to easily access translated values from structs
  and automatically fallbacks to the default value when the translation does
  not exist in the required locale. If you want to get translations from a
  struct you should take a look at this module.
  - `Trans.QueryBuilder` - adds conditions to `Ecto.Query` for filtering values
  of translated fields. If you want to get data from the database filtered by
  conditions on the translated fields you should take a look at this module. This
  module will be available only if `Ecto` is available.

  Trans shines when paired with an `Ecto.Schema`. It allows you to keep the
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
  declared as translatable must be present in the schema or struct declaration
  of the module.
  """

  defmacro __using__(opts) do
    quote do
      Module.put_attribute(__MODULE__, :trans_fields, unquote(
        translatable_fields(opts)
      ))

      @after_compile {Trans, :__validate_translatable_fields__}

      Module.eval_quoted __ENV__, [
        Trans.__fields__(@trans_fields)
      ]
    end
  end

  @doc false
  def __fields__(fields) when is_list(fields) do
    quote do
      @spec __trans__(:fields) :: list(atom)
      def __trans__(:fields), do: unquote(fields)
    end
  end

  @doc false
  def __validate_translatable_fields__(%{module: module}, _bytecode) do
    struct_fields =
      module.__struct__()
      |> Map.keys
      |> MapSet.new
    translatable_fields =
      module.__trans__(:fields)
      |> MapSet.new
    invalid_fields = MapSet.difference(translatable_fields, struct_fields)
    case MapSet.size(invalid_fields) do
      0 -> nil
      1 -> raise ArgumentError, message: "#{module} declares '#{MapSet.to_list(invalid_fields)}' as translatable but it is not defined in the module's struct"
      _ -> raise ArgumentError, message: "#{module} declares '#{MapSet.to_list(invalid_fields)}' as translatable but it they not defined in the module's struct"
    end
  end

  defp translatable_fields(opts) do
    case Keyword.fetch(opts, :translates) do
      {:ok, fields} when is_list(fields) -> fields
      _                                  -> error_must_specify_fields()
    end
  end

  defp error_must_specify_fields do
    raise ArgumentError, message: "Trans requires a 'translates' option that contains the list of translatable fields names"
  end

end
