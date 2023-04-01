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

  @spec from_mix_dep(dep :: Mix.Dep.t(), all_deps :: [Mix.Dep.t()]) :: t() | nil
  def from_mix_dep(
        %Mix.Dep{app: app, top_level: top_level, opts: opts, deps: deps} = dep,
        all_deps
      ) do
    %__MODULE__{
      package_url: package_url(dep, all_deps),
      metadata: %{name: app},
      relationship: if(top_level, do: :direct, else: :indirect),
      scope: if(Keyword.get(opts, :runtime, true), do: :runtime, else: :development),
      dependencies: deps |> Enum.map(&package_url(&1, all_deps)) |> Enum.reject(&is_nil/1)
    }
  end

  @spec package_url(dep :: Mix.Dep.t(), all_deps :: [Mix.Dep.t()]) :: String.t() | nil
  defp package_url(dep, all_deps)

  defp package_url(%Mix.Dep{scm: Hex.SCM, opts: opts} = dep, all_deps) do
    Purl.new!(%Purl{
      type: "hex",
      namespace:
        case opts[:repo] do
          nil -> []
          "hexpm" -> []
          "hexpm/" <> team -> [team]
          other -> [other]
        end,
      name: opts[:hex],
      version: package_version(dep, all_deps)
    })
  end

  defp package_url(%Mix.Dep{app: app, scm: Mix.SCM.Git, opts: opts} = dep, all_deps) do
    case Purl.from_resource_uri(opts[:git]) do
      {:ok, purl} ->
        %Purl{purl | version: package_version(dep, all_deps)}

      :error ->
        Purl.new!(%Purl{
          type: "generic",
          name: app,
          version: package_version(dep, all_deps),
          qualifiers: %{"vcs_url" => opts[:git]}
        })
    end
  end

  defp package_url(_dep, _all_deps), do: nil

  @spec package_version(dep :: Mix.Dep.t(), all_deps :: [Mix.Dep.t()]) :: String.t() | nil
  defp package_version(%Mix.Dep{app: app}, all_deps) do
    %Mix.Dep{} = dep = Enum.find(all_deps, &match?(%Mix.Dep{app: ^app}, &1))

    case package_version_from_lock(dep) do
      {:ok, version} -> version
      :error -> package_version_from_dep(dep)
    end
  end

  @spec package_version_from_lock(dep :: Mix.Dep.t()) :: {:ok, String.t()} | :error
  defp package_version_from_lock(%Mix.Dep{opts: opts}) do
    with {:ok, lock} <- Keyword.fetch(opts, :lock) do
      case Tuple.to_list(lock) do
        [:hex, _hex_package_name, version | _rest] -> {:ok, version}
        [:git, _repo_url, ref | _rest] -> {:ok, ref}
      end
    end
  end

  @spec package_version_from_dep(dep :: Mix.Dep.t()) :: String.t()
  defp package_version_from_dep(%Mix.Dep{status: {:ok, version}}), do: version

  defimpl Jason.Encoder do
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
