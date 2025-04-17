defmodule MixDependencySubmission.CLI.Submit do
  @moduledoc false
  alias MixDependencySubmission.ApiClient
  alias MixDependencySubmission.CLI

  require Logger

  @spec run(argv :: [String.t()]) :: no_return()
  def run(argv) do
    %Optimus.ParseResult{
      options: %{
        project_path: project_path,
        paths_relative_to: paths_relative_to,
        github_api_url: github_api_url,
        github_repository: github_repository,
        github_token: github_token,
        github_job_id: github_job_id,
        github_workflow: github_workflow,
        sha: sha,
        ref: ref,
        ignore: ignore
      },
      flags: %{
        install_deps: install_deps?
      }
    } = CLI.parse!(argv)

    submission =
      MixDependencySubmission.submission(
        github_job_id: github_job_id,
        github_workflow: github_workflow,
        sha: sha,
        ref: ref,
        project_path: project_path,
        paths_relative_to: paths_relative_to,
        install_deps?: install_deps?,
        ignore: ignore
      )

    Logger.info("Calculated Submission: #{Jason.encode!(submission, pretty: true)}")

    submission
    |> ApiClient.submit(github_api_url, github_repository, github_token)
    |> case do
      {:ok, %Req.Response{body: body}} ->
        Logger.info("Successfully submitted submission")
        Logger.debug("Success Response: #{inspect(body, pretty: true)}")

        System.halt(0)

      {:error, {:unexpected_response, response}} ->
        Logger.error("Unexpected response: #{inspect(response, pretty: true)}")
        System.stop(1)
    end
  end
end
