defmodule Shrink.MixProject do
  use Mix.Project

  def project do
    [
      app: :shrink,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: dialyzer(),
      test_coverage: coverage()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Shrink.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bandit, "~> 1.2"},
      {:credo, "~> 1.7.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4.3", only: [:dev, :test], runtime: false},
      {:dns_cluster, "~> 0.1.1"},
      {:ecto_sql, "~> 3.10"},
      {:ecto_psql_extras, "~> 0.7.15"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:ex_machina, "~> 2.7.0", only: :test},
      {:excellent_migrations, "~> 0.1.8", only: [:dev, :test], runtime: false},
      {:floki, ">= 0.30.0", only: :test},
      {:gettext, "~> 0.20"},
      {:heroicons,
       github: "tailwindlabs/heroicons", tag: "v2.1.1", sparse: "optimized", app: false, compile: false, depth: 1},
      {:jason, "~> 1.2"},
      {:phoenix, "~> 1.7.11"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.2"},
      {:postgrex, ">= 0.0.0"},
      {:styler, "~> 0.11.9", only: [:dev, :test], runtime: false},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind shrink", "esbuild shrink"],
      "assets.deploy": [
        "tailwind shrink --minify",
        "esbuild shrink --minify",
        "phx.digest"
      ],
      ci: [
        "format --check-formatted",
        "compile --all-warnings --warnings-as-errors",
        "excellent_migrations.check_safety",
        "test --cover",
        "dialyzer",
        "credo",
        "xref graph --label compile --format cycles --fail-above 0"
      ]
    ]
  end

  def cli do
    [preferred_envs: [ci: :test]]
  end

  defp coverage do
    [
      ignore_modules: [
        # Codegen
        ShrinkWeb.Gettext,
        # Deploy-only
        Shrink.Release,
        # False-positive
        Shrink.DataCase,
        Shrink.Repo,
        ShrinkWeb.ConnCase,
        # Low-value
        ShrinkWeb.CoreComponents,
        ShrinkWeb.Layouts,
        ~r/^ShrinkWeb\.\w+HTML$/
      ],
      summary: [threshold: 75]
    ]
  end

  defp dialyzer do
    [
      ignore_warnings: ".dialyzer_ignore.exs",
      list_unused_filters: true,
      plt_add_apps: [:ex_unit, :mix],
      plt_core_path: "_build/plts",
      plt_local_path: "_build/plts"
    ]
  end
end
