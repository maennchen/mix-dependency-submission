defmodule MixDependencySubmission.SCM.Hex.SCM do
  @moduledoc false

  @behaviour MixDependencySubmission.SCM

  alias MixDependencySubmission.SCM

  @impl SCM
  def mix_dep_to_purl({_app, requirement, opts}, version) do
    qualifiers =
      case repository_url(opts[:repo]) do
        {:ok, url} -> %{"repository_url" => url}
        :error -> %{}
      end

    Purl.new!(%Purl{
      type: "hex",
      namespace: hex_namespace(opts[:repo]),
      name: opts |> Keyword.fetch!(:hex) |> to_string(),
      version: version || requirement,
      qualifiers: qualifiers
    })
  end

  @impl SCM
  def mix_lock_to_purl(_app, lock) do
    [:hex, package_name, version, _inner_checksum, _managers, _deps, repo, _outer_checksum | _rest] = lock

    qualifiers =
      case repository_url(repo) do
        {:ok, url} -> %{"repository_url" => url}
        :error -> %{}
      end

    Purl.new!(%Purl{
      type: "hex",
      namespace: hex_namespace(repo),
      name: Atom.to_string(package_name),
      version: version,
      qualifiers: qualifiers
    })
  end

  @impl SCM
  def mix_lock_deps(lock) do
    [:hex, _package_name, _version, _inner_checksum, _managers, deps, _repo, _outer_checksum | _rest] = lock

    Enum.map(deps, fn {app, _requirement, _opts} -> app end)
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
