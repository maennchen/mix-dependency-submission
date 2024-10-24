defmodule MixDependencySubmission.CLI do
  @moduledoc false

  require Logger

  @app Mix.Project.config()[:app]
  @description Mix.Project.config()[:description]
  @version Mix.Project.config()[:version]

  @spec main(argv :: [String.t()]) :: :ok
  def main(argv) do
    prepare_run()

    %Optimus.ParseResult{
      args: %{project_name: project_name},
      options: %{
        project_path: project_path,
        paths_relative_to: paths_relative_to,
        github_api_url: github_api_url,
        github_repository: github_repository,
        github_token: github_token,
        github_job_id: github_job_id,
        github_workflow: github_workflow,
        sha: sha,
        ref: ref
      }
    } =
      cli_definition()
      |> Optimus.new!()
      |> Optimus.parse!(argv)

    Mix.Project.in_project(project_name, project_path, fn _module ->
      file_path = Path.relative_to(Path.join(project_path, "mix.exs"), paths_relative_to)

      submission =
        MixDependencySubmission.submission(%{
          github_job_id: github_job_id,
          github_workflow: github_workflow,
          sha: sha,
          ref: ref,
          file_path: file_path
        })

      Logger.info("Calculated Submission: #{Jason.encode!(submission, pretty: true)}")

      "#{github_api_url}/repos/#{github_repository}/dependency-graph/snapshots"
      |> Req.post!(
        json: submission,
        headers: [
          accept: "application/vnd.github+json",
          authorization: "Bearer #{github_token}",
          "x-github-api-version": "2022-11-28"
        ],
        connect_options: [
          transport_opts: [cacerts: :public_key.cacerts_get()]
        ]
      )
      |> case do
        %Req.Response{status: 201, body: body} ->
          Logger.info("Successfully submitted submission. Response: #{inspect(body, pretty: true)}")

        %Req.Response{} = response ->
          Logger.error("Unexpected response: #{inspect(response, pretty: true)}")
          System.stop(1)
      end
    end)

    :ok
  end

  @spec prepare_run :: :ok
  defp prepare_run do
    :ok = Mix.Local.append_archives()
    {:ok, _apps} = Application.ensure_all_started(@app)

    :ok
  end

  @spec cli_definition :: Optimus.spec()
  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  defp cli_definition do
    [
      name: Atom.to_string(@app),
      description: @description,
      version: @version,
      allow_unknown_args: false,
      args: [
        project_name: [
          value_name: "PROJECT_NAME",
          help: "Name of the project. (`app` in `mix.exs`)",
          required: true,
          parser: &parse_project_name/1
        ]
      ],
      options: [
        project_path: [
          value_name: "PROJECT_PATH",
          short: "-p",
          long: "--project-path",
          help: "Path to the project. (`directory` with `mix.exs`)",
          parser: &parse_project_path/1,
          default: &File.cwd!/0
        ],
        paths_relative_to: [
          value_name: "PATHS_RELATIVE_TO",
          long: "--paths-relative-to",
          help: "Path to the root of the project.",
          parser: &parse_directory/1,
          default: System.get_env("GITHUB_WORKSPACE", File.cwd!())
        ],
        github_api_url: [
          value_name: "GITHUB_API_URL",
          long: "--github-api-url",
          help: "GitHub API URL",
          parser: &parse_github_api_url/1,
          default: System.get_env("GITHUB_API_URL", "https://api.github.com")
        ],
        github_repository:
          optimus_options_with_env_default("GITHUB_REPOSITORY",
            value_name: "GITHUB_REPOSITORY",
            long: "--github-repository",
            help: ~S(GitHub repository name "owner/repository")
          ),
        github_job_id:
          optimus_options_with_env_default("GITHUB_JOB",
            value_name: "GITHUB_JOB",
            long: "--github-job-id",
            help: "GitHub Actions Job ID"
          ),
        github_workflow:
          optimus_options_with_env_default("GITHUB_WORKFLOW",
            value_name: "GITHUB_WORKFLOW",
            long: "--github-workflow",
            help: "GitHub Actions Workflow Name"
          ),
        sha:
          optimus_options_with_env_default("GITHUB_SHA",
            value_name: "SHA",
            long: "--sha",
            help: "Current Git SHA"
          ),
        ref:
          optimus_options_with_env_default("GITHUB_REF",
            value_name: "REF",
            long: "--ref",
            help: "Current Git Ref"
          ),
        github_token:
          optimus_options_with_env_default("GITHUB_TOKEN",
            value_name: "GITHUB_TOKEN",
            long: "--github-token",
            help: "GitHub Token"
          )
      ]
    ]
  end

  @spec parse_project_name(name :: String.t()) :: Optimus.parser_result()
  defp parse_project_name(name)
  defp parse_project_name(""), do: {:error, "invalid name"}
  # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
  defp parse_project_name(name), do: {:ok, String.to_atom(name)}

  @spec parse_project_path(path :: String.t()) :: Optimus.parser_result()
  defp parse_project_path(path) do
    with {:ok, path} <- parse_directory(path),
         true <- path |> Path.join("mix.exs") |> File.regular?() do
      {:ok, Path.absname(path)}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, "invalid path"}
    end
  end

  @spec parse_directory(path :: String.t()) :: Optimus.parser_result()
  defp parse_directory(path) do
    if File.dir?(path) do
      {:ok, Path.absname(path)}
    else
      {:error, "invalid path"}
    end
  end

  @spec parse_github_api_url(uri :: String.t()) :: Optimus.parser_result()
  defp parse_github_api_url(uri) do
    with {:ok, %URI{}} <- URI.new(uri) do
      uri
    end
  end

  @spec optimus_options_with_env_default(env :: String.t(), details :: Keyword.t()) :: Keyword.t()
  defp optimus_options_with_env_default(env, details) do
    case System.fetch_env(env) do
      {:ok, value} -> [default: value]
      :error -> [required: true]
    end ++ details
  end
end
