defmodule MixDependencySubmission.Submission.Manifest.Dependency do
  @moduledoc false

  @type t :: %__MODULE__{
          package_url: Purl.t() | nil,
          metadata: %{optional(String.t()) => String.t() | integer() | float() | boolean()} | nil,
          relationship: :direct | :indirect | nil,
          scope: :runtime | :development | nil,
          dependencies: [Purl.t()] | nil
        }

  @enforce_keys []
  defstruct package_url: nil, metadata: nil, relationship: nil, scope: nil, dependencies: nil

  defimpl Jason.Encoder do
    @impl Jason.Encoder
    def encode(value, opts) do
      value
      |> Map.from_struct()
      |> Enum.reject(&match?({_key, nil}, &1))
      |> Map.new()
      |> update_in([:package_url], &Purl.to_string/1)
      |> update_in([:dependencies, Access.all()], &Purl.to_string/1)
      |> Jason.Encode.map(opts)
    end
  end
end
