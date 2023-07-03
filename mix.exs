defmodule Trans.Mixfile do
  use Mix.Project

  @version "3.0.0"

  def project do
    [
      app: :trans,
      version: @version,
      elixir: "~> 1.11",
      description: "Embedded translations for Elixir schemas",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      app_list: app_list(Mix.env()),
      package: package(),
      deps: deps(),

      # Docs
      name: "Trans",
      source_url: "https://github.com/crbelaus/trans",
      homepage_url: "https://hex.pm/packages/trans",
      docs: [
        source_ref: "v#{@version}",
        main: "Trans"
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:jason, "~> 1.1"},
      {:ecto, "~> 3.0"},
      # Optional dependencies
      {:ecto_sql, "~> 3.0", optional: true},
      {:postgrex, "~> 0.14", optional: true},
      # Doc dependencies
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      maintainers: ["Cristian Álvarez Belaustegui"],
      links: %{"GitHub" => "https://github.com/crbelaus/trans"}
    ]
  end

  # Include Ecto and Postgrex applications in tests
  def app_list(:test), do: [:ecto, :postgrex]
  def app_list(_), do: []

  # Always compile files in "lib". In tests compile also files in
  # "test/support"
  def elixirc_paths(:test), do: ["lib", "test/support"]
  def elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      test: [
        "ecto.create --quiet",
        "ecto.migrate --quiet",
        "test"
      ]
    ]
  end
end
