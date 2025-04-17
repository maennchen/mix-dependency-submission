if Mix.env() == :dev do
  # Helpful for testing, use Burrito binary for prod

  defmodule Mix.Tasks.MixDependencySubmission do
    @shortdoc "Run mix_depdendency_submission"
    @moduledoc @shortdoc

    use Mix.Task

    alias MixDependencySubmission.CLI.Submit

    @requirements ["app.start"]

    @impl Mix.Task
    def run(args) do
      Submit.run(args)
    end
  end
end
