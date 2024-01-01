defmodule Caveatica.MixProject do
  use Mix.Project

  @app :caveatica
  @target System.get_env("MIX_TARGET") |> String.to_atom()
  @version "0.1.0"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.14",
      archives: [nerves_bootstrap: "~> 1.10"],
      start_permanent: Mix.env() == :prod,
      build_embedded: true,
      deps: deps(),
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :ssh],
      mod: {Caveatica.App, []}
    ]
  end

  defp deps do
    [
      {:circuits_gpio, "~> 1.0"},
      {:nerves, "~> 1.9.0", runtime: false},
      {:nerves_time, "~> 0.4.2", targets: @target},
      {:nerves_runtime, "~> 0.13.0", targets: @target},
      {:nerves_pack, "~> 0.7.0", targets: @target},
      {:nerves_system_rpi0, "~> 1.22", runtime: false, targets: :rpi0},
      {:nerves_system_rpi3, "~> 1.22", runtime: false, targets: :rpi3},
      {:nerves_system_rpi4, "~> 1.22", runtime: false, targets: :rpi4},
      {:picam, "~> 0.4.1"},
      {:ring_logger, "~> 0.8.1"},
      {:toolshed, "~> 0.2.13"},
      # Websocket
      {:slipstream, "~> 1.0"}
    ]
  end

  def release do
    [
      overwrite: true,
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod or [keep: ["Docs"]]
    ]
  end
end
