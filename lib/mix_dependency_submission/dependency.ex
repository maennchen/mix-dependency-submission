defmodule MixDependencySubmission.Dependency do
  @moduledoc """
  Behaviour for implementing dependency details for custom `Mix.SCM`
  implementations.

  ## Usage

  To define the SCM in a way so that it is recognized by this library, define a
  module called `MixDependencySubmission.Dependency.[SCM Module Name]` and
  it will be automatically be picked up.
  """

  alias MixDependencySubmission.Submission.Manifest.Dependency

  @callback mix_dependency_to_package_url(dep :: Mix.Dep.t()) ::
              {:ok, Purl.t()} | :error

  @doc false
  @spec mix_dependency_to_manifest(dep :: Mix.Dep.t(), all_deps :: [Mix.Dep.t()]) ::
          {:ok, MixDependencySubmission.Submission.Manifest.Dependency.t()} | :error
  def mix_dependency_to_manifest(
        %Mix.Dep{app: app, scm: scm, top_level: top_level} = dep,
        all_deps
      ) do
    with {:ok, scm_module} <- scm_impl_module(scm),
         {:ok, purl} <- scm_module.mix_dependency_to_package_url(dep) do
      {:ok,
       %Dependency{
         package_url: purl,
         metadata: %{name: app},
         relationship: if(top_level, do: :direct, else: :indirect),
         scope: mix_dependency_scope(dep),
         dependencies: get_resolved_child_dependencies(dep, all_deps)
       }}
    end
  end

  @spec resolve_version(
          dep :: Mix.Dep.t(),
          lock_callback :: (list() -> {:ok, Purl.version()} | :error)
        ) :: {:ok, Purl.version()} | :error
  def resolve_version(%Mix.Dep{} = dep, lock_callback \\ fn _lock -> :error end) do
    case package_version_from_lock(dep, lock_callback) do
      {:ok, version} -> {:ok, version}
      :error -> package_version_from_dep(dep)
    end
  end

  @spec scm_impl_module(scm :: atom()) :: {:ok, atom()} | :error
  defp scm_impl_module(scm) do
    {:ok, Module.safe_concat(__MODULE__, scm)}
  rescue
    ArgumentError -> :error
  end

  # Child Dependencies do not have version resolved. Therefore matching with
  # the dependencies on the root level.
  @spec get_resolved_child_dependencies(dep :: Mix.Dep.t(), all_deps :: [Mix.Dep.t()]) :: [
          Mix.Dep.t()
        ]
  defp get_resolved_child_dependencies(%Mix.Dep{deps: deps}, all_deps) do
    all_deps
    |> Enum.filter(fn %Mix.Dep{app: app} ->
      Enum.any?(deps, &match?(%Mix.Dep{app: ^app}, &1))
    end)
    |> Enum.map(&mix_dependency_to_manifest(&1, all_deps))
    |> Enum.filter(&match?({:ok, _package_url}, &1))
    |> Enum.map(fn {:ok, package_url} -> package_url end)
  end

  @spec mix_dependency_scope(dep :: Mix.Dep.t()) :: :runtime | :development
  defp mix_dependency_scope(%Mix.Dep{opts: opts}) do
    runtime = Keyword.get(opts, :runtime, true)

    only =
      case Keyword.get(opts, :only, [:prod]) do
        list when is_list(list) -> list
        entry -> [entry]
      end

    cond do
      !runtime -> :development
      :prod not in only -> :development
      true -> :runtime
    end
  end

  @spec package_version_from_lock(dep :: Mix.Dep.t(), callback :: (list() -> result)) :: result
        when result: {:ok, Purl.version()} | :error
  defp package_version_from_lock(%Mix.Dep{opts: opts}, callback) do
    with {:ok, lock} <- Keyword.fetch(opts, :lock) do
      lock |> Tuple.to_list() |> callback.()
    end
  end

  @spec package_version_from_dep(dep :: Mix.Dep.t()) :: {:ok, Purl.version()} | :error
  defp package_version_from_dep(dep)
  defp package_version_from_dep(%Mix.Dep{status: {:ok, version}}), do: {:ok, version}
  defp package_version_from_dep(%Mix.Dep{}), do: :error
end

defmodule MixDependencySubmission.Dependency.Mix.SCM.Git do
  @moduledoc false

  @behaviour MixDependencySubmission.Dependency

  alias MixDependencySubmission.Dependency

  @impl Dependency
  def mix_dependency_to_package_url(%Mix.Dep{app: app, scm: Mix.SCM.Git, opts: opts} = dep) do
    version =
      dep
      |> Dependency.resolve_version(fn
        [:git, _repo_url, ref | _rest] -> {:ok, ref}
        _other -> :error
      end)
      |> case do
        {:ok, version} -> version
        :error -> nil
      end

    case Purl.from_resource_uri(opts[:git]) do
      {:ok, purl} ->
        {:ok, %Purl{purl | version: version}}

      :error ->
        {:ok,
         Purl.new!(%Purl{
           type: "generic",
           name: app,
           version: version,
           qualifiers: %{"vcs_url" => opts[:git]}
         })}
    end
  end
end

defmodule MixDependencySubmission.Dependency.Hex.SCM do
  @moduledoc false

  @behaviour MixDependencySubmission.Dependency

  alias MixDependencySubmission.Dependency

  @impl Dependency
  def mix_dependency_to_package_url(%Mix.Dep{scm: Hex.SCM, opts: opts} = dep) do
    version =
      dep
      |> Dependency.resolve_version(fn
        [:hex, _hex_package_name, version | _rest] -> {:ok, version}
        _other -> :error
      end)
      |> case do
        {:ok, version} -> version
        :error -> nil
      end

    qualifiers =
      case repository_url(opts[:repo]) do
        {:ok, url} -> %{"repository_url" => url}
        :error -> %{}
      end

    {:ok,
     Purl.new!(%Purl{
       type: "hex",
       namespace: hex_namespace(opts[:repo]),
       name: opts[:hex],
       version: version,
       qualifiers: qualifiers
     })}
  end

  @spec hex_namespace(repo :: String.t() | nil) :: Purl.namespace()
  defp hex_namespace(repo)
  defp hex_namespace(nil), do: []
  defp hex_namespace("hexpm"), do: []
  defp hex_namespace("hexpm:" <> organisation), do: [organisation]
  defp hex_namespace(repo), do: String.split(repo, ":")

  @spec repository_url(repo :: String.t() | nil) :: {:ok, Purl.qualifier_value()} | :error
  defp repository_url(repo)
  defp repository_url(nil), do: :error
  defp repository_url("hexpm"), do: :error
  defp repository_url("hexpm:" <> _organisation), do: :error

  defp repository_url(repo) do
    with {:ok, %{url: url}} <- Hex.Repo.fetch_repo(repo) do
      {:ok, url}
    end
  end
end
