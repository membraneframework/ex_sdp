defmodule Membrane.Protocol.SDP.MixProject do
  use Mix.Project

  def project do
    [
      app: :membrane_protocol_sdp,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:bunch, "~> 0.3"},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false}
    ]
  end
end
