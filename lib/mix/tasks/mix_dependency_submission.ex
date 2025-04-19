if Mix.env() == :dev do
  # Helpful for testing, use Burrito binary for prod

  defmodule Mix.Tasks.MixDependencySubmission do
    @shortdoc "Run mix_depdendency_submission"
    @moduledoc """
    #{@shortdoc}

    Only intented for development purposes. Use the burrito binary for
    production.
    """

    use Mix.Task

    alias MixDependencySubmission.CLI.Submit

    @requirements ["app.start"]

    @doc false
    @impl Mix.Task
    def run(args) do
      Submit.run(args)
    end
  end
end
