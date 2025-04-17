defmodule MixDependencySubmission.SCM.Mix.SCM.Path do
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
          version: version
        })
    end
  end
end
