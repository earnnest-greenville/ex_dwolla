defmodule ExDwolla.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_dwolla,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.circle": :test,
      ],
      test_coverage: [tool: ExCoveralls],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ExDwolla.Application, []}
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.1"},
      {:junit_formatter, "~> 3.0", only: :test},
      {:mojito, "~> 0.4.0"},
      {:uuid, "~> 1.1"},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
    ]
  end
end
