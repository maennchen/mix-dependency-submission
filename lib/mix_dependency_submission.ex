defmodule MixDependencySubmission do
  @moduledoc false

  alias MixDependencySubmission.Fetcher
  alias MixDependencySubmission.Submission
  alias MixDependencySubmission.Submission.Manifest
  alias MixDependencySubmission.Util

  @spec submission(
          options :: [
            {:github_job_id, String.t()}
            | {:github_workflow, String.t()}
            | {:ref, String.t()}
            | {:sha, String.t()}
            | {:project_path, Path.t()}
            | {:paths_relative_to, Path.t()}
            | {:install_deps?, boolean()}
            | {:ignore, [Path.t()]}
          ]
        ) :: Submission.t()
  def submission(options) do
    options =
      options
      |> Keyword.put_new(:project_path, &File.cwd!/0)
      |> Keyword.update!(:project_path, &Path.expand/1)

    options =
      options
      |> Keyword.put_new(:paths_relative_to, options[:project_path])
      |> Keyword.update!(:paths_relative_to, &Path.expand/1)

    manifests =
      options[:project_path]
      |> find_mix_projects(options[:ignore] || [], options[:paths_relative_to])
      |> Map.new(fn project_path ->
        manifest = manifest(project_path, Keyword.take(options, [:paths_relative_to, :install_deps?]))
        {manifest.file.source_location, manifest}
      end)

    Submission.new(%{
      github_job_id: Keyword.fetch!(options, :github_job_id),
      github_workflow: Keyword.fetch!(options, :github_workflow),
      sha: Keyword.fetch!(options, :sha),
      ref: Keyword.fetch!(options, :ref),
      manifests: manifests
    })
  end

  @spec manifest(project_path :: Path.t(), options :: [{:paths_relative_to, Path.t()} | {:install_deps?, boolean()}]) ::
          Manifest.t()
  def manifest(project_path, options) do
    Util.in_project(project_path, fn _mix_module ->
      if options[:install_deps?] do
        Mix.Task.run("deps.get")
      end

      make_manifest(Fetcher.fetch(), project_path, options[:paths_relative_to])
    end)
  end

  @spec find_mix_projects(project_path :: Path.t(), ignore :: [Path.t()], paths_relative_to :: Path.t()) :: [Path.t()]
  defp find_mix_projects(project_path, ignore, paths_relative_to) do
    ignore = Enum.map(ignore, &Path.expand(&1, paths_relative_to))

    project_path
    |> Path.join("**/mix.exs")
    |> Path.wildcard()
    |> Enum.map(&Path.dirname/1)
    |> Enum.map(&Path.expand/1)
    |> Enum.reject(fn path ->
      Enum.any?(ignore, &String.starts_with?(path, &1)) or
        path |> Path.split() |> Enum.member?("deps")
    end)
    # No more than 1000, otherwise something went wrong like scanning deps...
    |> Enum.take(1000)
  end

  @spec make_manifest(
          dependencies :: %{String.t() => Manifest.Dependency.t()} | nil,
          project_path :: Path.t(),
          paths_relative_to :: Path.t()
        ) :: Manifest.t()
  defp make_manifest(dependencies, project_path, paths_relative_to) do
    metadata =
      %{
        # GitHub 500, try again another time
        # "name" => Mix.Project.config()[:name],
        # "source_url" => Mix.Project.config()[:source_url],
        # "description" => Mix.Project.config()[:description],
        # "maintainers" => Enum.join(Mix.Project.config()[:package][:maintainers] || [], ", "),
        # "license_expression" => Enum.join(Mix.Project.config()[:package][:licenses] || [], " AND "),
        # "build_tools" => Enum.map_join(Mix.Project.config()[:package][:build_tools] || [], ", ", &inspect/1)
      }

    %Manifest{
      name: "mix.exs",
      file: %Manifest.File{
        source_location: project_path |> Path.join("mix.exs") |> Path.relative_to(paths_relative_to)
      },
      resolved: dependencies,
      metadata: drop_empty(metadata)
    }
  end

  @spec drop_empty(map :: %{key => value | nil}) :: %{key => value} when key: term(), value: term()
  defp drop_empty(map), do: map |> Enum.reject(fn {_key, value} -> value in [nil, ""] end) |> Map.new()
end
