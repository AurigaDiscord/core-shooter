defmodule Shooter.Mixfile do
  use Mix.Project

  def project do
    [
      app: :shooter,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Shooter, []},
      applications: [:confex, :poison, :amqp, :httpoison],
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:confex, "~> 3.3.0"},
      {:poison, "~> 3.1"},
      {:amqp, "~> 1.0.3"},
      {:httpoison, "~> 1.0"}
    ]
  end
end
