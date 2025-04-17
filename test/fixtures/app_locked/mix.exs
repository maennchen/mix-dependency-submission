defmodule AppNameToReplace.MixProject do
  use Mix.Project

  def project do
    [
      app: :app_name_to_replace,
      version: "0.0.0-dev",
      deps: [
        {:credo, "~> 1.7"},
        {:mime, "~> 2.0"},
        {:expo, github: "elixir-gettext/expo"}
      ]
    ]
  end
end
