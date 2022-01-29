defmodule Trans.Repo.Migrations.TransGenTranslateFunction do
  use Ecto.Migration

  def up do
    execute("""
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
            RETURN j->field;
          ELSEIF c->locale IS NOT NULL THEN
            IF c->locale->>field IS NOT NULL THEN
              RETURN c->locale->>field;
            END IF;
          END IF;
        END LOOP;
        RETURN j->field;
      END;
    $$;
    """)

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
    execute(
      "DROP FUNCTION IF EXISTS public.translate_field(container varchar, field varchar, default_locale varchar, locales varchar[])"
    )

    execute(
      "DROP FUNCTION IF EXISTS public.translate_field(container varchar, default_locale varchar, locales varchar[])"
    )
  end
end