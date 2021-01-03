defmodule TelegramBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :telegram_bot,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  # TODO: Remove mix from `extra_applications` as soon as we figure out a better way to start process dynamically on
  # application.ex.
  def application do
    [
      extra_applications: [:logger, :mix],
      mod: {TelegramBot.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:engine, in_umbrella: true},
      {:image_uploader, in_umbrella: true},
      {:plug_cowboy, "~> 2.0"},
      {:jason, "~> 1.2"},
      {:nadia, github: "feliperenan/nadia"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end

  defp dialyzer do
    [
      plt_core_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end
end
