defmodule Needlepoint.MixProject do
  use Mix.Project

  def project do
    [
      app: :needlepoint,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),

      # Docs
      name: "Needlepoint",
      source_url: "https://github.com/dallaselynn/needlepoint",
      homepage_url: "https://hexdocs.pm/needlepoint",
      docs: [
        main: "readme",
        extras: [
          "README.md"
        ]
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
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "A collection of NLP algorithms."
  end

  defp package() do
    [
      maintainers: ["Dallas Lynn"],
      files: ~w(lib priv .formatter.exs mix.exs README* LICENSE* test),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/dallaselynn/needlepoint"}
    ]
  end
end
