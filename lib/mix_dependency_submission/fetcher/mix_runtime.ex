defmodule MixDependencySubmission.Fetcher.MixRuntime do
  @moduledoc """
  Fetch Dependencies from Mix Runtime.
  """

  @behaviour MixDependencySubmission.Fetcher

  alias MixDependencySubmission.Fetcher

  @impl Fetcher
  def fetch do
    root_deps = [depth: 1] |> Mix.Project.deps_tree() |> Map.keys()
    deps_paths = Mix.Project.deps_paths()
    deps_scms = Mix.Project.deps_scms()

    Map.new(Mix.Project.deps_tree(), &resolve_dep(&1, root_deps, deps_paths, deps_scms))
  end

  @spec resolve_dep(
          dep :: {Fetcher.app_name(), [Fetcher.app_name()]},
          root_deps :: [Fetcher.app_name()],
          deps_paths :: %{Fetcher.app_name() => Path.t()},
          deps_scms :: %{Fetcher.app_name() => module()}
        ) :: {Fetcher.app_name(), Fetcher.dependency()}
  defp resolve_dep({app, dependencies}, root_deps, deps_paths, deps_scms) do
    dep_path = Map.fetch!(deps_paths, app)
    dep_scm = Map.fetch!(deps_scms, app)

    config =
      if Elixir.File.exists?(dep_path) do
        Mix.Project.in_project(app, Map.fetch!(deps_paths, app), fn _module -> Mix.Project.config() end)
      else
        []
      end

    relationship = if(app in root_deps, do: :direct, else: :indirect)

    {app,
     %{
       scm: dep_scm,
       version: config[:version],
       scope: :runtime,
       relationship: relationship,
       dependencies: dependencies,
       mix_config: config
     }}
  end
end
