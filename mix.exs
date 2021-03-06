defmodule Events.Mixfile do
  use Mix.Project

  def project do
    [
      app: :events,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Events.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 2.2.3"},
      {:postgrex, "~> 0.13.3"},
      {:poison, "~> 3.1.0"},
      {:httpoison, "~> 0.13"},
      {:slime, "~> 1.0.0"},
      {:timex, "~> 3.1.24"},
      {:floki, "~> 0.18.0"},
      {:ok, "~> 1.9.2"},
    ]
  end
end
