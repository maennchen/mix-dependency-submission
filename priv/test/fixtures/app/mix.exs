defmodule App.MixProject do
  use Mix.Project

  def project do
    [
      app: :app,
      deps: [
        {:credo, "~> 1.7"},
        {:mime, "~> 2.0"},
        {:expo, github: "elixir-gettext/expo"}
      ]
    ]
  end
end
