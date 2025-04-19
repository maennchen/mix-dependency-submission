# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule MixDependencySubmission.MixProject do
  use Mix.Project

  @version "1.0.0-beta.8"
  @source_url "https://github.com/erlef/mix-dependency-submission"
  @description "Calculates dependencies for Mix and submits the list to the GitHub Dependency Submission API"

  def project do
    [
      app: :mix_dependency_submission,
      version: @version,
      elixir: "1.17.3",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [
        tool: ExCoveralls,
        ignore_modules: [MixDependencySubmission.CLI, MixDependencySubmission.CLI.Submit]
      ],
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
    [
      mod: {MixDependencySubmission.Application, []},
      extra_applications: [:logger, :mix]
    ]
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
      {:plug, "~> 1.0", only: [:test]},
      {:purl, "~> 0.2.0"},
      {:req, "~> 0.5.6"},
      {:styler, "~> 1.1", only: [:dev, :test], runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]
end
