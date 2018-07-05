defmodule ElixirGo.MixProject do
  use Mix.Project

  def project do
    [
      app: :igo,
      version: "0.1.0",
      escript: escript(),
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/jphager2/elixir_igo",
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp escript do
    [main_module: Igo.CLI]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:floki, "~> 0.20.0"}
    ]
  end
end
