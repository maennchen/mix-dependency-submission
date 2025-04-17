defmodule MixDependencySubmission.SCM.Mix.SCM.Git do
  @moduledoc false

  @behaviour MixDependencySubmission.SCM

  alias MixDependencySubmission.SCM

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
