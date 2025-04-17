defmodule MixDependencySubmission.ApiClient do
  @moduledoc false
  alias MixDependencySubmission.Submission

  @spec submit(
          submission :: Submission.t(),
          github_api_url :: String.t(),
          github_repository :: String.t(),
          github_token :: String.t()
        ) :: {:ok, Req.Response.t()} | {:error, {:unexpected_response, Req.Response.t()}}
  def submit(submission, github_api_url, github_repository, github_token) do
    client()
    |> Req.request!(
      base_url: github_api_url,
      json: submission,
      headers: [
        accept: "application/vnd.github+json",
        authorization: "Bearer #{github_token}",
        "x-github-api-version": "2022-11-28"
      ],
      url: "/repos/#{github_repository}/dependency-graph/snapshots"
    )
    |> case do
      %Req.Response{status: 201} = response -> {:ok, response}
      %Req.Response{} = response -> {:error, {:unexpected_response, response}}
    end
  end

  @spec client() :: Keyword.t()
  defp client do
    Keyword.merge(
      [connect_options: [transport_opts: [cacerts: :public_key.cacerts_get()]], method: :post],
      Application.get_env(:mix_dependency_submission, __MODULE__, [])
    )
  end
end
