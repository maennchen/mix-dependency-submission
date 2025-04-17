defmodule MixDependencySubmission.Fetcher.MixFile do
  @moduledoc """
  Fetch Dependencies from mix.exs directly.
  """

  @behaviour MixDependencySubmission.Fetcher

  alias MixDependencySubmission.Fetcher

  @impl Fetcher
  def fetch do
    Mix.Project.config()[:deps] |> List.wrap() |> Map.new(&normalize_dep/1)
  end

  @spec normalize_dep(
          dep ::
            {Fetcher.app_name(), String.t()}
            | {Fetcher.app_name(), Keyword.t()}
            | {Fetcher.app_name(), String.t() | nil, Keyword.t()}
        ) :: {Fetcher.app_name(), Fetcher.dependency()}
  defp normalize_dep(dep)

  defp normalize_dep({app, requirement}) when is_atom(app) and is_binary(requirement),
    do: normalize_dep({app, requirement, []})

  defp normalize_dep({app, opts}) when is_atom(app) and is_list(opts), do: normalize_dep({app, nil, opts})

  defp normalize_dep({app, requirement, opts})
       when is_atom(app) and (is_binary(requirement) or is_nil(requirement)) and is_list(opts) do
    {scm, opts} =
      Enum.find_value(Mix.SCM.available(), {nil, opts}, fn scm ->
        case scm.accepts_options(app, opts) do
          nil -> false
          opts -> {scm, opts}
        end
      end)

    {app,
     %{
       scm: scm,
       mix_dep: {app, requirement, opts},
       relationship: :direct,
       scope: dependency_scope(opts)
     }}
  end

  @spec dependency_scope(opts :: Keyword.t()) :: :runtime | :development
  defp dependency_scope(opts) do
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
end
