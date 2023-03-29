defmodule MixDependencySubmission.CLI do
  @moduledoc false

  @app Mix.Project.config()[:app]
  @description Mix.Project.config()[:description]
  @version Mix.Project.config()[:version]
  @url Mix.Project.config()[:source_url]

  def main(argv) do
    :ok = Mix.Local.append_archives()
    {:ok, _apps} = Application.ensure_all_started(@app)

    %Optimus.ParseResult{
      args: %{project_name: project_name},
      options: %{project_path: project_path}
    } =
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
          ]
        ]
      ]
      |> Optimus.new!()
      |> Optimus.parse!(argv)

    Application.ensure_all_started(:mix)

    Mix.Project.in_project(project_name, project_path, fn _module ->
      file_path =
        Path.relative_to(
          Path.join(project_path, "mix.exs"),
          System.fetch_env!("GITHUB_WORKSPACE")
        )

      deps = Mix.Dep.cached()

      Req.post!(
        System.fetch_env!("GITHUB_API_URL") <>
          "/repos/" <> System.fetch_env!("GITHUB_REPOSITORY") <> "/dependency-graph/snapshots",
        json: %MixDependencySubmission.Submission{
          version: 0,
          job: %MixDependencySubmission.Submission.Job{
            id: System.fetch_env!("GITHUB_JOB"),
            correlator: System.fetch_env!("GITHUB_WORKFLOW") <> System.fetch_env!("GITHUB_JOB")
          },
          sha: System.fetch_env!("GITHUB_SHA"),
          ref: System.fetch_env!("GITHUB_REF"),
          detector: %MixDependencySubmission.Submission.Detector{
            name: @app,
            version: @version,
            url: @url
          },
          metadata: %{},
          scanned: DateTime.utc_now(),
          manifests: %{
            file_path => %MixDependencySubmission.Submission.Manifest{
              name: file_path,
              file: %MixDependencySubmission.Submission.Manifest.File{
                source_location: file_path
              },
              metadata: %{},
              resolved:
                Map.new(
                  deps,
                  &{&1.app,
                   MixDependencySubmission.Submission.Manifest.Dependency.from_mix_dep(&1, deps)}
                )
            }
          }
        },
        headers: [
          accept: "application/vnd.github+json",
          authorization: "Bearer " <> System.fetch_env!("GITHUB_TOKEN"),
          "x-github-api-version": "2022-11-28"
        ],
        connect_options: [
          transport_opts: [cacerts: :public_key.cacerts_get()]
        ]
      )
      |> IO.inspect()
    end)
  end

  @spec parse_project_name(name :: String.t()) :: Optimus.parser_result()
  defp parse_project_name(name)
  defp parse_project_name(""), do: {:error, "invalid name"}
  defp parse_project_name(name), do: {:ok, String.to_atom(name)}

  @spec parse_project_name(path :: String.t()) :: Optimus.parser_result()
  defp parse_project_path(path) do
    with true <- File.dir?(path),
         true <- File.regular?(Path.join(path, "mix.exs")) do
      {:ok, Path.absname(path)}
    else
      false -> {:error, "invalid path"}
    end
  end
end
