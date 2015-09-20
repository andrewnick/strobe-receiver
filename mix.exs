defmodule Janis.Mixfile do
  use Mix.Project

  def project do
    [app: :janis,
     version: "0.0.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:porcelain, :logger, :dnssd],
     mod: {Janis, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [ {:porcelain, "~> 2.0"},
      {:socket, "~> 0.3.0"},
      {:dnssd, github: "benoitc/dnssd_erlang"},
      {:poison, "~> 1.5"},
      {:poolboy, github: "devinus/poolboy"},
    ]
  end
end
