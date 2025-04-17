defmodule MixDependencySubmission.Submission do
  @moduledoc false

  alias MixDependencySubmission.Submission.Detector
  alias MixDependencySubmission.Submission.Job
  alias MixDependencySubmission.Submission.Manifest

  @type manifests() :: %{String.t() => Manifest.t()}
  @type t :: %__MODULE__{
          version: non_neg_integer(),
          job: Job.t(),
          sha: <<_::320>>,
          ref: String.t(),
          detector: Detector.t(),
          metadata: %{optional(String.t()) => String.t() | integer() | float() | boolean()} | nil,
          scanned: DateTime.t(),
          manifests: manifests() | nil
        }

  @derive Jason.Encoder
  @enforce_keys [:version, :job, :sha, :ref, :detector, :scanned]
  defstruct [:version, :job, :sha, :ref, :detector, :scanned, metadata: nil, manifests: nil]

  @app Mix.Project.config()[:app]
  @version Mix.Project.config()[:version]
  @url Mix.Project.config()[:source_url]

  @detector %Detector{
    name: Atom.to_string(@app),
    version: Version.parse!(@version),
    url: URI.new!(@url)
  }

  @spec new(
          options :: %{
            github_job_id: String.t(),
            github_workflow: String.t(),
            ref: String.t(),
            sha: String.t(),
            manifests: manifests()
          }
        ) :: t()

  def new(%{github_job_id: github_job_id, github_workflow: github_workflow, sha: sha, ref: ref, manifests: manifests}) do
    %__MODULE__{
      version: 0,
      job: %Job{
        id: github_job_id,
        correlator: "#{github_workflow} #{github_job_id}"
      },
      sha: sha,
      ref: ref,
      detector: @detector,
      metadata: %{},
      scanned: DateTime.utc_now(),
      manifests: manifests
    }
  end
end
