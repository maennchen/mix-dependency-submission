defmodule MixDependencySubmission.SCM.Mix.SCM.Git do
  @moduledoc """
  SCM implementation for Git-based Mix dependencies.

  Handles conversion of Git dependencies declared in `mix.exs` or found in
  `mix.lock` into package URLs (purl). Falls back to a generic purl format if
  the repository URL does not represent a specific purl type like `pkg:github`.
  """

  @behaviour MixDependencySubmission.SCM

  alias MixDependencySubmission.SCM

  @doc """
  Creates a package URL (`purl`) from a Git-based Mix dependency.

  Attempts to infer the version from `:ref`, `:branch`, or `:tag`, or falls back
  to the requirement.

  ## Examples

      iex> MixDependencySubmission.SCM.Mix.SCM.Git.mix_dep_to_purl(
      ...>   {:my_app, nil, [git: "https://github.com/example/my_app.git", tag: "v1.0.0"]},
      ...>   nil
      ...> )
      %Purl{
        type: "github",
        name: "my_app",
        namespace: ["example"],
        version: "v1.0.0"
      }

  """
  @impl SCM
  def mix_dep_to_purl({app, requirement, opts}, version) do
    version = version || opts[:ref] || opts[:branch] || opts[:tag] || requirement

    case Purl.from_resource_uri(opts[:git]) do
      {:ok, purl} ->
        %{purl | version: version}

      :error ->
        Purl.new!(%Purl{
          type: "generic",
          name: Atom.to_string(app),
          version: version,
          qualifiers: %{"vcs_url" => opts[:git]}
        })
    end
  end

  @doc """
  Creates a package URL (`purl`) from a Git-based `mix.lock` entry.

  Uses the repository URL and Git revision as the version.

  ## Examples

      iex> MixDependencySubmission.SCM.Mix.SCM.Git.mix_lock_to_purl(
      ...>   :my_app,
      ...>   [:git, "https://github.com/example/my_app.git", "abc123"]
      ...> )
      %Purl{
        type: "github",
        name: "my_app",
        namespace: ["example"],
        version: "abc123"
      }

  """
  @impl SCM
  def mix_lock_to_purl(app, lock) do
    [:git, repo_url, revision | _rest] = lock

    case Purl.from_resource_uri(repo_url) do
      {:ok, purl} ->
        %{purl | version: revision}

      :error ->
        Purl.new!(%Purl{
          type: "generic",
          name: Atom.to_string(app),
          version: revision,
          qualifiers: %{"vcs_url" => repo_url}
        })
    end
  end
end
