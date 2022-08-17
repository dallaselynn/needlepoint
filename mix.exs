defmodule Needlepoint.MixProject do
  use Mix.Project

  def project do
    [
      app: :needlepoint,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "Needlepoint",
      source_url: "https://github.com/dallaselynn/needlepoint",
      # homepage_url: "http://YOUR_PROJECT_HOMEPAGE",
      docs: [
        # The main page in the docs
        main: "Needlepoint",
        # logo: "path/to/logo.png",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:statistics, "~> 0.6.2"},
      {:nx, "~> 0.1.0-dev", github: "elixir-nx/nx", branch: "main", sparse: "nx"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
