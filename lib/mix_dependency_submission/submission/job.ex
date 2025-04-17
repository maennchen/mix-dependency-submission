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
    @impl Jason.Encoder
    def encode(value, opts) do
      value
      |> Map.from_struct()
      |> Map.update!(:html_url, &uri_to_string/1)
      |> Enum.reject(&match?({_key, nil}, &1))
      |> Map.new()
      |> Jason.Encode.map(opts)
    end

    @spec uri_to_string(uri :: URI.t()) :: String.t()
    @spec uri_to_string(uri :: nil) :: nil
    defp uri_to_string(uri)
    defp uri_to_string(nil), do: nil
    defp uri_to_string(%URI{} = uri), do: URI.to_string(uri)
  end
end
