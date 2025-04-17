defmodule MixDependencySubmission.SCM do
  @moduledoc false

  @typedoc """
  Lock for the dependency as a list.

  **Always only match the start of the list. The list can be extended to include
  further contents in the future at the end of the list.**

  ## Examples

      [
        :hex,
        :jason,
        "1.4.0",
        "e855647bc964a44e2f67df589ccf49105ae039d4179db7f6271dfd3843dc27e6",
        [:mix],
        [
          {:decimal, "~> 1.0 or ~> 2.0",
          [hex: :decimal, repo: "hexpm", optional: true]}
        ],
        "hexpm",
        "79a3791085b2a0f743ca04cec0f7be26443738779d09302e01318f97bdb82121"
      ]

  """
  @type lock :: list()

  @type app_name() :: atom()
  @type dep() :: {app_name(), requirement :: String.t() | nil, opts :: Keyword.t()}

  @doc """
  Create a package url for the given `dep`.

  """
  @callback mix_dep_to_purl(dep(), version :: String.t() | nil) :: Purl.t()

  @doc """
  Create a package url for the given `dep`.

  ## Examples

        iex> MixDependencySubmission.SCM.Hex.SCM.mix_dependency_to_package_url(:credo)
        {:ok, Purl.parse!("pkg:hex/credo@1.7.0")}

        iex> MixDependencySubmission.SCM.Hex.SCM.mix_dependency_to_package_url(:invalid)
        :error

  """
  @callback mix_lock_to_purl(app :: atom(), lock :: lock()) :: Purl.t()

  @callback mix_lock_deps(lock :: lock()) :: [app_name()]

  @optional_callbacks mix_lock_deps: 1, mix_lock_to_purl: 2

  @spec implementation(module()) :: module() | nil
  def implementation(scm) when is_atom(scm) do
    if scm in Mix.SCM.available() do
      # We're looking for this module, safe_concat can't be used
      # Security Impact is negligeble since the SCM has to be registered with
      # Mix.SCM.available()
      # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
      scm_impl = Module.concat(__MODULE__, scm)

      case Code.ensure_loaded(scm_impl) do
        {:module, ^scm_impl} ->
          scm_impl

        # SCM not implemented
        {:error, _reason} ->
          nil
      end
    end
  end
end
