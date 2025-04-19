defmodule MixDependencySubmission.ApiClientTest do
  use ExUnit.Case, async: true

  alias MixDependencySubmission.ApiClient
  alias MixDependencySubmission.Submission

  doctest ApiClient, except: [submit: 4]

  describe inspect(&ApiClient.submit/4) do
    test "sends correct request" do
      Req.Test.stub(ApiClient, fn conn ->
        assert ["application/vnd.github+json"] = Plug.Conn.get_req_header(conn, "accept")
        assert ["Bearer token"] = Plug.Conn.get_req_header(conn, "authorization")
        assert ["application/json"] = Plug.Conn.get_req_header(conn, "content-type")
        assert ["2022-11-28"] = Plug.Conn.get_req_header(conn, "x-github-api-version")

        assert %Plug.Conn{
                 path_info: ["repos", "erlef", "mix-dependency-submission", "dependency-graph", "snapshots"],
                 host: "api.github.com",
                 method: "POST"
               } = conn

        conn
        |> Plug.Conn.put_status(:created)
        |> Req.Test.json(%{"ok" => true})
      end)

      assert {:ok, %Req.Response{status: 201, body: %{"ok" => true}}} =
               %{
                 github_job_id: "1",
                 github_workflow: "workflow.yml",
                 ref: "main",
                 sha: "asdbn12312",
                 manifests: %{}
               }
               |> Submission.new()
               |> ApiClient.submit(
                 "https://api.github.com",
                 "erlef/mix-dependency-submission",
                 "token"
               )
    end

    test "handles error" do
      Req.Test.stub(ApiClient, fn conn ->
        conn
        |> Plug.Conn.put_status(:bad_request)
        |> Req.Test.json(%{"ok" => false})
      end)

      assert {:error, {:unexpected_response, %Req.Response{status: 400, body: %{"ok" => false}}}} =
               %{
                 github_job_id: "1",
                 github_workflow: "workflow.yml",
                 ref: "main",
                 sha: "asdbn12312",
                 manifests: %{}
               }
               |> Submission.new()
               |> ApiClient.submit(
                 "https://api.github.com",
                 "erlef/mix-dependency-submission",
                 "token"
               )
    end
  end
end
