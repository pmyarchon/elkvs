defmodule Elkvs.Mixfile do
  use Mix.Project

  def project do
    [
      app: :elkvs,
      version: "0.1.0",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  def application do
    [
      applications: [:logger, :cowboy, :plug],
      mod: {Elkvs, []}
    ]
  end

  # Dependencies
  defp deps do
    [
      {:plug, "~> 1.3.3"},
      {:cowboy, "~> 1.1.2"}
    ]
  end
end
