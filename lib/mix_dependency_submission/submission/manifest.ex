defmodule MixDependencySubmission.Submission.Manifest do
  @moduledoc false

  alias MixDependencySubmission.Submission.Manifest.File
  alias MixDependencySubmission.Submission.Manifest.Dependency

  @type t :: %__MODULE__{
          name: String.t(),
          file: File.t() | nil,
          metadata: %{optional(String.t()) => String.t() | integer() | float() | boolean()} | nil,
          resolved: %{optional(String.t()) => Dependency.t()} | nil
        }

  @enforce_keys [:name]
  defstruct [:name, file: nil, metadata: nil, resolved: nil]

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
