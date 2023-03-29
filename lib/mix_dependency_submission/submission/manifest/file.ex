defmodule MixDependencySubmission.Submission.Manifest.File do
  @moduledoc false

  @type t :: %__MODULE__{
          source_location: Path.t() | nil
        }

  @enforce_keys []
  defstruct source_location: nil

  defimpl Jason.Encoder do
    @impl Jason.Encoder
    def encode(value, opts) do
      value
      |> Map.from_struct()
      |> Enum.reject(&match?({_key, nil}, &1))
      |> Map.new()
      |> Jason.Encode.map(opts)
    end
  end
end
