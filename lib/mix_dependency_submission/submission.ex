defmodule MixDependencySubmission.Submission do
  @moduledoc false

  alias MixDependencySubmission.Submission.Detector
  alias MixDependencySubmission.Submission.Job
  alias MixDependencySubmission.Submission.Manifest

  @type t :: %__MODULE__{
          version: non_neg_integer(),
          job: Job.t(),
          sha: <<_::320>>,
          ref: String.t(),
          detector: Detector.t(),
          metadata: %{optional(String.t()) => String.t() | integer() | float() | boolean()} | nil,
          scanned: DateTime.t(),
          manifests: %{String.t() => Manifest.t()} | nil
        }

  @derive Jason.Encoder
  @enforce_keys [:version, :job, :sha, :ref, :detector, :scanned]
  defstruct [:version, :job, :sha, :ref, :detector, :scanned, metadata: nil, manifests: nil]
end
