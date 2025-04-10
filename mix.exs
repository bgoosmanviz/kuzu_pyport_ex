defmodule KuzuPyPortEx.MixProject do
  use Mix.Project

  @version "0.1.6"
  @source_url "https://github.com/bgoosmanviz/kuzu_pyport_ex"

  def project do
    [
      app: :kuzu_pyport_ex,
      description: "Elixir wrapper for a Python process running KuzuDB",
      name: "KuzuPyPortEx",
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :export],
      # mod: {KuzuPyPortEx.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:export, "~> 0.1.0"}
    ]
  end

  defp package do
    [
      files: [
        "lib",
        "mix.exs",
        "priv/python/kuzu_proxy.py",
        "priv/python/requirements.txt"
      ],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
