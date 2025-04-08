# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule MixDependencySubmission.MixProject do
  use Mix.Project

  @version "1.0.0-beta.4"
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
      source_url: @source_url,
      releases: releases()
    ]
  end

  def application do
    opts = [extra_applications: [:logger, :mix]]

    case Mix.env() do
      :test -> opts
      _other -> [{:mod, {MixDependencySubmission.Application, []}} | opts]
    end
  end

  def releases do
    [
      mix_dependency_submission: [
        applications: [hex: :load],
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            linux_amd64: [os: :linux, cpu: :x86_64],
            linux_arm64: [os: :linux, cpu: :aarch64]
          ]
        ]
      ]
    ]
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
      {:burrito, "~> 1.0"},
      {:credo, "~> 1.0", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.5", only: [:test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:dev], runtime: false},
      {:hex, github: "hexpm/hex", runtime: false},
      {:jason, "~> 1.4"},
      {:optimus, "~> 0.2"},
      {:purl, "~> 0.2.0"},
      {:req, "~> 0.5.6"},
      {:styler, "~> 1.1", only: [:dev, :test], runtime: false}
    ]
  end
end
