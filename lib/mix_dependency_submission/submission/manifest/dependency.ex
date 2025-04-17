defmodule MixDependencySubmission.Submission.Manifest.Dependency do
  @moduledoc false

  @type relationship() :: :direct | :indirect
  @type scope() :: :runtime | :development

  @type t :: %__MODULE__{
          package_url: Purl.t() | nil,
          metadata: %{optional(String.t()) => String.t() | integer() | float() | boolean()} | nil,
          relationship: relationship() | nil,
          scope: scope() | nil,
          dependencies: [Purl.t()] | nil
        }

  @enforce_keys []
  defstruct package_url: nil, metadata: nil, relationship: nil, scope: nil, dependencies: nil

  defimpl Jason.Encoder do
    @impl Jason.Encoder
    def encode(value, opts) do
      value
      |> Map.from_struct()
      |> update_in([:package_url], &purl_to_string/1)
      |> update_in([:dependencies], &List.wrap/1)
      |> update_in([:dependencies, Access.all()], &purl_to_string/1)
      |> Enum.reject(fn {_key, value} -> value in [nil, []] end)
      |> Map.new()
      |> Jason.Encode.map(opts)
    end

    @spec purl_to_string(purl :: Purl.t()) :: String.t()
    @spec purl_to_string(purl :: nil) :: nil
    defp purl_to_string(purl)
    defp purl_to_string(nil), do: nil
    defp purl_to_string(%Purl{} = purl), do: Purl.to_string(purl)
  end
end
