defmodule MixDependencySubmission.Submission.Job do
  @moduledoc false

  @type t :: %__MODULE__{
          id: String.t(),
          correlator: String.t(),
          html_url: URI.t() | nil
        }

  @enforce_keys [:id, :correlator]
  defstruct [:id, :correlator, html_url: nil]

  defimpl Jason.Encoder do
    def encode(value, opts) do
      value
      |> Map.from_struct()
      |> Enum.reject(&match?({_key, nil}, &1))
      |> Map.new()
      |> Jason.Encode.map(opts)
    end
  end
end
