defmodule MixDependencySubmission.Submission.Detector do
  @moduledoc false

  @type t :: %__MODULE__{
          name: String.t(),
          version: Version.t(),
          url: URI.t()
        }

  @derive Jason.Encoder
  @enforce_keys [:name, :version, :url]
  defstruct [:name, :version, :url]
end
