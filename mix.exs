# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule MixDependencySubmission.MixProject do
  use Mix.Project

  @version "1.0.0-beta.1"
  @source_url "https://github.com/maennchen/mix-dependency-submission"
  @description """
  :warning: This repository is not ready for use. Please check back later.
  Calculates dependencies for Mix and submits the list to the GitHub Dependency Submission API
  """

  def project do
    [
      app: :mix_dependency_submission,
      version: @version,
      elixir: "1.17.3",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      description: @description,
      dialyzer: [list_unused_filters: true],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "coveralls.json": :test,
        "coveralls.post": :test,
        "coveralls.xml": :test
      ],
      package: package(),
      escript: [main_module: MixDependencySubmission.CLI],
      source_url: @source_url,
      # Loaded via archive in MixDependencySubmission.CLI.prepare_run/0
      xref: [exclude: [Hex.Repo]]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :mix]
    ]
  end

  defp package do
    %{
      licenses: ["Apache-2.0"],
      maintainers: ["Jonatan Männchen"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => @source_url <> "/releases",
        "Issues" => @source_url <> "/issues"
      }
    }
  end

  defp docs do
    [
      source_url: @source_url,
      source_ref: "v" <> @version,
      main: "readme",
      extras: ["README.md"]
    ]
  end

  defp deps do
    [
      {:castore, "~> 1.0"},
      {:credo, "~> 1.0", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.5", only: [:test], runtime: false},
      {:jason, "~> 1.4"},
      {:optimus, "~> 0.2"},
      {:purl, "~> 0.1.1"},
      {:req, "~> 0.5.6"},
      {:styler, "~> 1.1", only: [:dev, :test], runtime: false}
    ]
  end
end
