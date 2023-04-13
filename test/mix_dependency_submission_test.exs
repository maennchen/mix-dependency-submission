defmodule MixDependencySubmissionTest do
  use ExUnit.Case, async: false

  alias MixDependencySubmission.Submission

  doctest MixDependencySubmission

  describe inspect(&MixDependencySubmission.submission/1) do
    test "generates valid submission for 'app' fixture" do
      run_in_fixture(:app, fn ->
        current_version =
          :mix_dependency_submission
          |> Application.spec(:vsn)
          |> List.to_string()
          |> Version.parse!()

        assert %Submission{
                 version: 0,
                 job: %Submission.Job{
                   id: "github_job_id",
                   correlator: "github_workflowgithub_job_id",
                   html_url: nil
                 },
                 sha: "sha",
                 ref: "ref",
                 detector: %Submission.Detector{
                   name: "mix_dependency_submission",
                   version: ^current_version,
                   url: %URI{
                     scheme: "https",
                     userinfo: nil,
                     host: "github.com",
                     port: 443,
                     path: "/jshmrtn/mix-dependency-submission",
                     query: nil,
                     fragment: nil
                   }
                 },
                 scanned: %DateTime{},
                 metadata: %{},
                 manifests: %{
                   "mix.exs" => %Submission.Manifest{
                     name: "mix.exs",
                     file: %Submission.Manifest.File{
                       source_location: "mix.exs"
                     },
                     metadata: %{},
                     resolved: %{
                       # TODO: Add tests for child dependencies
                       credo: %Submission.Manifest.Dependency{
                         package_url: %Purl{type: "hex", name: "credo", version: "1.7.0"},
                         metadata: %{name: :credo},
                         relationship: :direct,
                         scope: :runtime
                       },
                       expo: %Submission.Manifest.Dependency{
                         package_url: %Purl{
                           type: "github",
                           name: "expo",
                           namespace: ["elixir-gettext"],
                           version: "2ae85019d62288001bdc4a949d65bf650beee315"
                         },
                         metadata: %{name: :expo},
                         relationship: :direct,
                         scope: :runtime
                       },
                       mime: %Submission.Manifest.Dependency{
                         # Version is empty because dependency is not locked
                         package_url: %Purl{type: "hex", name: "mime", version: nil},
                         metadata: %{name: :mime},
                         relationship: :direct,
                         scope: :runtime
                       }
                     }
                   }
                 }
               } =
                 MixDependencySubmission.submission(%{
                   github_job_id: "github_job_id",
                   github_workflow: "github_workflow",
                   sha: "sha",
                   ref: "ref",
                   file_path: "mix.exs"
                 })
      end)
    end
  end

  @spec run_in_fixture(fixture_app :: atom(), callback :: (() -> result)) :: result
        when result: term()
  defp run_in_fixture(fixture_app, callback) do
    Mix.ProjectStack.on_clean_slate(fn ->
      Mix.Project.in_project(
        :app,
        Application.app_dir(:mix_dependency_submission, "priv/test/fixtures/#{fixture_app}"),
        fn _module ->
          callback.()
        end
      )
    end)
  end
end
