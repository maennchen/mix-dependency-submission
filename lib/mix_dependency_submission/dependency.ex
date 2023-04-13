defmodule MixDependencySubmission.Dependency do
  @moduledoc """
  Behaviour for implementing dependency details for custom `Mix.SCM`
  implementations.

  ## Usage

  To define the SCM in a way so that it is recognized by this library, define a
  module called `MixDependencySubmission.Dependency.[SCM Module Name]` and
  it will be automatically be picked up.

  ## Examples

  For a fictional `ASDF.SCM` `Mix.SCM` implementation:

      defmodule MixDependencySubmission.Dependency.ASDF.SCM do
        @behaviour MixDependencySubmission.Dependency

        @impl MixDependencySubmission.Dependency
        def mix_dependency_to_package_url(dep) do
          {:ok, Purl.parse!("pkg:generic/\#{dep}")}
        end
      end
  """

  alias MixDependencySubmission.Submission.Manifest.Dependency

  @typep deps_lock :: %{optional(atom()) => lock()}

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

  @doc """
  Create a package url for the given `dep`.

  ## Examples

        iex> MixDependencySubmission.Dependency.Hex.SCM.mix_dependency_to_package_url(:credo)
        {:ok, Purl.parse!("pkg:hex/credo@1.7.0")}

        iex> MixDependencySubmission.Dependency.Hex.SCM.mix_dependency_to_package_url(:invalid)
        :error

  """
  @callback mix_dependency_to_package_url(dep :: atom(), lock :: lock() | nil) ::
              {:ok, Purl.t()} | :error

  @doc false
  @spec mix_dependency_to_manifest({dep :: atom(), scm :: module()}, lock :: deps_lock()) ::
          {:ok, MixDependencySubmission.Submission.Manifest.Dependency.t()} | :error
  def mix_dependency_to_manifest({dep, scm}, lock \\ read_package_lock()) do
    dep_lock =
      case lock do
        %{^dep => dep_lock} -> Tuple.to_list(dep_lock)
        %{} -> nil
      end

    with {:ok, scm_module} <- scm_impl_module(scm),
         {:ok, purl} <- scm_module.mix_dependency_to_package_url(dep, dep_lock) do
      {:ok,
       %Dependency{
         package_url: purl,
         metadata: %{name: dep},
         relationship: if(dep in child_apps(), do: :direct, else: :indirect),
         scope: mix_dependency_scope(dep),
         dependencies: get_resolved_child_dependencies(dep, lock)
       }}
    end
  end

  @spec scm_impl_module(scm :: atom()) :: {:ok, atom()} | :error
  defp scm_impl_module(scm) do
    {:ok, Module.safe_concat(__MODULE__, scm)}
  rescue
    ArgumentError -> :error
  end

  @spec get_resolved_child_dependencies(dep :: atom(), lock :: deps_lock()) :: [Purl.t()]
  defp get_resolved_child_dependencies(dep, lock) do
    dep
    |> deps_scms()
    |> Map.delete(dep)
    |> Enum.map(&mix_dependency_to_manifest(&1, lock))
    |> Enum.filter(&match?({:ok, _dep}, &1))
    |> Enum.map(fn {:ok, %Dependency{package_url: package_url}} -> package_url end)
  end

  @spec mix_dependency_scope(dep :: atom()) :: :runtime | :development
  defp mix_dependency_scope(dep) do
    opts =
      case dependency_install_options(dep) do
        {:ok, opts} -> opts
        :error -> []
      end

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

  @spec read_package_lock :: deps_lock()
  defp read_package_lock do
    lockfile =
      Path.absname(Mix.Project.config()[:lockfile], Path.dirname(Mix.Project.project_file()))

    opts = [file: lockfile, warn_on_unnecessary_quotes: false]

    with {:ok, contents} <- File.read(lockfile),
         {:ok, quoted} <- Code.string_to_quoted(contents, opts),
         {%{} = lock, _binding} <- Code.eval_quoted(quoted, [], opts) do
      lock
    else
      _other -> %{}
    end
  end

  @spec dependency_install_options(dep :: atom()) :: {:ok, Keyword.t()} | :error
  defp dependency_install_options(dep) do
    with {:ok, deps} <- Keyword.fetch(Mix.Project.config(), :deps) do
      Enum.find_value(deps, :error, fn
        {^dep, _version_requirement, opts} when is_list(opts) -> {:ok, opts}
        {^dep, opts} when is_list(opts) -> {:ok, opts}
        {^dep, version_requirement} when is_binary(version_requirement) -> {:ok, []}
        _other -> false
      end)
    end
  end

  @doc """
  Get Dependency Options from `mix.exs` / `deps/0`

  ## Examples

      iex> MixDependencySubmission.Dependency.dependency_scm_options(:credo)
      [hex: "credo", only: [:dev], runtime: false, repo: "hexpm"]

      iex> MixDependencySubmission.Dependency.dependency_scm_options(:invalid)
      []

  """
  @spec dependency_scm_options(dep :: atom()) :: Keyword.t()
  def dependency_scm_options(dep) do
    %{^dep => scm} = Mix.Project.deps_scms(parents: [dep], depth: 1)

    opts =
      case dependency_install_options(dep) do
        {:ok, opts} -> opts
        :error -> []
      end

    scm.accepts_options(dep, opts)
  end

  @spec child_apps :: [atom()]
  if function_exported?(Mix.Project, :deps_tree, 1) do
    defp child_apps do
      %{^dep => child_apps} = Mix.Project.deps_tree(depth: 1)
    end
  else
    # TODO: Remove when only supporting Elixir >= 1.15
    defp child_apps do
      Mix.Dep.cached()
      |> Enum.filter(&match?(%Mix.Dep{top_level: true}, &1))
      |> Enum.map(& &1.app)
    end
  end

  @spec deps_scms(dep :: atom()) :: %{optional(atom) => module()}
  if Version.match?(System.version(), "~> 1.15") do
    defp deps_scms(dep), do: Mix.Project.deps_scms(parents: [dep], depth: 2)
  else
    # TODO: Remove when only supporting Elixir >= 1.15
    defp deps_scms(dep) do
      %Mix.Dep{deps: deps} = Enum.find(Mix.Dep.cached(), &match?(%Mix.Dep{app: ^dep}, &1))

      Map.new(deps, &{&1.app, &1.scm})
    end
  end
end

defmodule MixDependencySubmission.Dependency.Mix.SCM.Git do
  @moduledoc false

  @behaviour MixDependencySubmission.Dependency

  alias MixDependencySubmission.Dependency

  @impl Dependency
  def mix_dependency_to_package_url(dep, lock) do
    opts = Dependency.dependency_scm_options(dep)

    version =
      case lock do
        [:git, _repo_url, ref | _rest] -> ref
        _other -> nil
      end

    case Purl.from_resource_uri(opts[:git]) do
      {:ok, purl} ->
        {:ok, %Purl{purl | version: version}}

      :error ->
        {:ok,
         Purl.new!(%Purl{
           type: "generic",
           name: Atom.to_string(dep),
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
  def mix_dependency_to_package_url(dep, lock) do
    opts = Dependency.dependency_scm_options(dep)

    version =
      case lock do
        [:hex, _hex_package_name, version | _rest] -> version
        _other -> nil
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
       name: Keyword.get(opts, :hex, Atom.to_string(dep)),
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
