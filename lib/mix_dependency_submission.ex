defmodule MixDependencySubmission do
  @moduledoc false

  alias MixDependencySubmission.Dependency
  alias MixDependencySubmission.Submission

  @app Mix.Project.config()[:app]
  @version Mix.Project.config()[:version]
  @url Mix.Project.config()[:source_url]

  @detector %Submission.Detector{
    name: Atom.to_string(@app),
    version: Version.parse!(@version),
    url: URI.new!(@url)
  }

  @spec submission(
          options :: %{
            :github_job_id => String.t(),
            :github_workflow => String.t(),
            :ref => String.t(),
            :sha => String.t(),
            :file_path => String.t()
          }
        ) :: Submission.t()
  def submission(%{
        github_job_id: github_job_id,
        github_workflow: github_workflow,
        sha: sha,
        ref: ref,
        file_path: file_path
      }) do
    %Submission{
      version: 0,
      job: %Submission.Job{
        id: github_job_id,
        correlator: "#{github_workflow} #{github_job_id}"
      },
      sha: sha,
      ref: ref,
      detector: @detector,
      metadata: %{},
      scanned: DateTime.utc_now(),
      manifests: %{file_path => manifest(file_path)}
    }
  end

  @spec manifest(file_path :: String.t()) :: Submission.Manifest.t()
  defp manifest(file_path) do
    %Submission.Manifest{
      name: file_path,
      file: %Submission.Manifest.File{
        source_location: file_path
      },
      metadata: %{},
      resolved:
        Mix.Project.deps_scms()
        |> Enum.map(fn {app, _scm} = dep ->
          with {:ok, dependency} <- Dependency.mix_dependency_to_manifest(dep) do
            {:ok, {app, dependency}}
          end
        end)
        |> Enum.filter(&match?({:ok, {_app, _dependency}}, &1))
        |> Map.new(fn {:ok, {app, dependency}} -> {app, dependency} end)
    }
  end
end
