if Code.ensure_loaded?(Ecto.Adapters.SQL) do
  defmodule Mix.Tasks.Trans.Gen.TranslateFunction do
    use Mix.Task

    import Mix.Generator
    import Mix.Ecto, except: [migrations_path: 1]
    import Macro, only: [camelize: 1, underscore: 1]

    @shortdoc "Generates an Ecto migration to create the translate_field database function"

    @moduledoc """
    Generates a migration to add a database function
    `translate_field` that uses the `Trans` structured
    transaltion schema to resolve a translation for a field.

    """

    @doc false
    @dialyzer {:no_return, run: 1}

    def run(args) do
      no_umbrella!("trans_gen_translate_function")
      repos = parse_repo(args)
      name = "trans_gen_translate_function"

      Enum.each(repos, fn repo ->
        ensure_repo(repo, args)
        path = Path.relative_to(migrations_path(repo), Mix.Project.app_path())
        file = Path.join(path, "#{timestamp()}_#{underscore(name)}.exs")
        create_directory(path)

        assigns = [mod: Module.concat([repo, Migrations, camelize(name)])]

        content =
          assigns
          |> migration_template
          |> format_string!

        create_file(file, content)

        if open?(file) and Mix.shell().yes?("Do you want to run this migration?") do
          Mix.Task.run("ecto.migrate", [repo])
        end
      end)
    end

    defp timestamp do
      {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
      "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
    end

    defp pad(i) when i < 10, do: <<?0, ?0 + i>>
    defp pad(i), do: to_string(i)

    if Code.ensure_loaded?(Code) && function_exported?(Code, :format_string!, 1) do
      @spec format_string!(String.t()) :: iodata()
      @dialyzer {:no_return, format_string!: 1}
      def format_string!(string) do
        Code.format_string!(string)
      end
    else
      @spec format_string!(String.t()) :: iodata()
      def format_string!(string) do
        string
      end
    end

    if Code.ensure_loaded?(Ecto.Migrator) &&
         function_exported?(Ecto.Migrator, :migrations_path, 1) do
      def migrations_path(repo) do
        Ecto.Migrator.migrations_path(repo)
      end
    end

    if Code.ensure_loaded?(Mix.Ecto) && function_exported?(Mix.Ecto, :migrations_path, 1) do
      def migrations_path(repo) do
        Mix.Ecto.migrations_path(repo)
      end
    end

    embed_template(:migration, ~S|
      defmodule <%= inspect @mod %> do
        use Ecto.Migration

        def up do
          execute """
          CREATE OR REPLACE FUNCTION public.translate_field(record record, container varchar, field varchar, default_locale varchar, locales varchar[])
          RETURNS varchar
          STRICT
          STABLE
          LANGUAGE plpgsql
          AS $$
            DECLARE
              locale varchar;
              j json;
              c json;
              l varchar;
            BEGIN
              j := row_to_json(record);
              c := j->container;

              FOREACH locale IN ARRAY locales LOOP
                IF locale = default_locale THEN
                  RETURN j->>field;
                ELSEIF c->locale IS NOT NULL THEN
                  IF c->locale->>field IS NOT NULL THEN
                    RETURN c->locale->>field;
                  END IF;
                END IF;
              END LOOP;
              RETURN j->>field;
            END;
          $$;
          """

          execute("""
          CREATE OR REPLACE FUNCTION public.translate_field(record record, container varchar, default_locale varchar, locales varchar[])
          RETURNS jsonb
          STRICT
          STABLE
          LANGUAGE plpgsql
          AS $$
            DECLARE
              locale varchar;
              j json;
              c json;
            BEGIN
              j := row_to_json(record);
              c := j->container;

              FOREACH locale IN ARRAY locales LOOP
                IF c->locale IS NOT NULL THEN
                  RETURN c->locale;
                END IF;
              END LOOP;
              RETURN NULL;
            END;
          $$;
          """)
        end

        def down do
          execute "DROP FUNCTION IF EXISTS public.translate_field(container varchar, field varchar, default_locale varchar, locales varchar[])"
          execute "DROP FUNCTION IF EXISTS public.translate_field(container varchar, default_locale varchar, locales varchar[])"
        end
      end
    |)
  end
end
