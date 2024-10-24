defmodule MixDependencySubmission.Submission.Detector do
  @moduledoc false

  @type t :: %__MODULE__{
          name: String.t(),
          version: Version.t(),
          url: URI.t()
        }

  @enforce_keys [:name, :version, :url]
  defstruct [:name, :version, :url]

  defimpl Jason.Encoder do
    @impl Jason.Encoder
    def encode(value, opts) do
      value
      |> Map.from_struct()
      |> Map.update!(:version, &Version.to_string/1)
      |> Map.update!(:url, &URI.to_string/1)
      |> Jason.Encode.map(opts)
    end
  end
end
