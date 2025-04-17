defmodule MixDependencySubmissionTest do
  use MixDependencySubmission.FixtureCase, async: false

  import ExUnit.CaptureIO

  alias MixDependencySubmission.Submission
  alias MixDependencySubmission.Submission.Manifest.Dependency
  alias MixDependencySubmission.Util

  doctest MixDependencySubmission

  describe inspect(&MixDependencySubmission.submission/1) do
    @tag :tmp_dir
    @tag fixture_app: "umbrella"
    test "generates valid submission for 'umbrella' fixture", %{app_path: app_path} do
      current_version =
        :mix_dependency_submission
        |> Application.spec(:vsn)
        |> List.to_string()
        |> Version.parse!()

      assert %Submission{
               version: 0,
               job: %Submission.Job{
                 id: "github_job_id",
                 correlator: "github_workflow github_job_id",
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
                   path: "/maennchen/mix-dependency-submission",
                   query: nil,
                   fragment: nil
                 }
               },
               scanned: %DateTime{},
               metadata: %{},
               manifests: %{
                 "mix.exs" => %Submission.Manifest{},
                 "apps/child_app_name_to_replace/mix.exs" => %Submission.Manifest{}
               }
             } =
               MixDependencySubmission.submission(
                 github_job_id: "github_job_id",
                 github_workflow: "github_workflow",
                 sha: "sha",
                 ref: "ref",
                 project_path: app_path,
                 paths_relative_to: app_path,
                 install_deps?: false
               )
    end

    @tag :tmp_dir
    test "empty submission for project without mix.exs", %{tmp_dir: tmp_dir} do
      Util.in_project(tmp_dir, fn _mix_module ->
        assert %Submission{manifests: manifests} =
                 MixDependencySubmission.submission(%{
                   github_job_id: "github_job_id",
                   github_workflow: "github_workflow",
                   sha: "sha",
                   ref: "ref",
                   project_path: tmp_dir,
                   paths_relative_to: tmp_dir
                 })

        assert manifests == %{}
      end)
    end
  end

  describe inspect(&MixDependencySubmission.manifest/2) do
    @tag :tmp_dir
    @tag fixture_app: "app_locked"
    test "generates valid manifest for 'app_locked' fixture", %{app_path: app_path} do
      assert %Submission.Manifest{
               name: "mix.exs",
               file: %Submission.Manifest.File{
                 source_location: "mix.exs"
               },
               resolved: resolved
             } = MixDependencySubmission.manifest(app_path, paths_relative_to: app_path)

      assert %{
               "expo" => %Dependency{
                 package_url: %Purl{
                   type: "github",
                   namespace: ["elixir-gettext"],
                   name: "expo",
                   version: "2ae85019d62288001bdc4a949d65bf650beee315"
                 },
                 relationship: :direct,
                 scope: :runtime,
                 dependencies: []
               },
               "credo" => %Dependency{
                 package_url: %Purl{type: "hex", name: "credo", version: "1.7.0"},
                 relationship: :direct,
                 scope: :runtime,
                 dependencies: [
                   %Purl{type: "hex", name: "bunt", version: "0.2.1"},
                   %Purl{type: "hex", name: "file_system", version: "0.2.10"},
                   %Purl{type: "hex", name: "jason", version: "1.4.0"}
                 ]
               }
             } = resolved
    end

    @tag :tmp_dir
    @tag fixture_app: "app_library"
    test "generates valid manifest for 'app_library' fixture", %{app_path: app_path} do
      assert %Submission.Manifest{
               name: "mix.exs",
               file: %Submission.Manifest.File{
                 source_location: "mix.exs"
               },
               resolved: resolved
               # GitHub 500, try again another time
               # metadata: %{"license_expression" => "Apache-2.0"}
             } = MixDependencySubmission.manifest(app_path, paths_relative_to: app_path)

      assert %{
               "credo" => %Dependency{
                 package_url: %Purl{type: "hex", name: "credo", version: "~> 1.7"},
                 relationship: :direct,
                 scope: :runtime,
                 dependencies: []
               },
               "path_dep" => %Dependency{
                 package_url: %Purl{type: "generic", name: "path_dep"},
                 relationship: :direct,
                 scope: :runtime,
                 dependencies: []
               }
             } = resolved
    end

    @tag :tmp_dir
    @tag fixture_app: "app_library"
    test "generates complete manifest for 'app_library' fixture", %{app_path: app_path} do
      capture_io(fn ->
        assert %Submission.Manifest{
                 name: "mix.exs",
                 file: %Submission.Manifest.File{
                   source_location: "mix.exs"
                 },
                 resolved: resolved
                 # GitHub 500, try again another time
                 # metadata: %{"license_expression" => "Apache-2.0"}
               } = MixDependencySubmission.manifest(app_path, paths_relative_to: app_path, install_deps?: true)

        assert %{
                 "credo" => %Dependency{
                   package_url: %Purl{type: "hex", name: "credo", version: "1.7.12"},
                   relationship: :direct,
                   scope: :runtime,
                   dependencies: [_credo_one | _credo_rest]
                 },
                 "path_dep" => %Dependency{
                   package_url: %Purl{type: "generic", name: "path_dep"},
                   relationship: :direct,
                   scope: :runtime,
                   dependencies: []
                 }
               } = resolved
      end)
    end

    @tag :tmp_dir
    @tag fixture_app: "app_installed"
    test "generates valid manifest for 'app_installed' fixture", %{app_path: app_path} do
      assert %Submission.Manifest{
               name: "mix.exs",
               file: %Submission.Manifest.File{
                 source_location: "mix.exs"
               },
               resolved: resolved
             } = MixDependencySubmission.manifest(app_path, paths_relative_to: app_path)

      assert %{
               "decimal" => %Dependency{
                 package_url: %Purl{type: "hex", name: "decimal", version: "2.3.0"},
                 relationship: :indirect,
                 scope: :runtime,
                 dependencies: [],
                 metadata:
                   %{
                     # GitHub 500, try again another time
                     # "description" => "Arbitrary precision decimal arithmetic.",
                     # "license_expression" => "Apache-2.0",
                     # "maintainers" => "Eric Meadows-Jönsson",
                     # "name" => "Decimal",
                     # "source_url" => "https://github.com/ericmj/decimal"
                   }
               },
               "number" => %Dependency{
                 package_url: %Purl{type: "hex", name: "number", version: "1.0.5"},
                 relationship: :direct,
                 scope: :runtime,
                 dependencies: [%Purl{type: "hex", name: "decimal", version: "2.3.0"}],
                 metadata:
                   %{
                     # GitHub 500, try again another time
                     # "description" => "Convert numbers to various string formats, such as currency",
                     # "license_expression" => "MIT",
                     # "maintainers" => "Daniel Berkompas"
                   }
               }
             } = resolved
    end

    @tag :tmp_dir
    @tag fixture_app: "umbrella"
    test "generates valid manifest for 'umbrella' fixture", %{app_path: app_path} do
      assert %Submission.Manifest{
               name: "mix.exs",
               file: %Submission.Manifest.File{
                 source_location: "mix.exs"
               },
               resolved: umbrella_resolved
             } = MixDependencySubmission.manifest(app_path, paths_relative_to: app_path)

      assert %Submission.Manifest{
               name: "mix.exs",
               file: %Submission.Manifest.File{
                 source_location: "apps/child_app_name_to_replace/mix.exs"
               },
               resolved: child_resolved
             } =
               app_path
               |> Path.join("apps/child_app_name_to_replace")
               |> MixDependencySubmission.manifest(paths_relative_to: app_path)

      assert %{
               "child_app_name_to_replace" => %Dependency{
                 package_url: %Purl{type: "generic", name: "child_app_name_to_replace", version: "0.0.0-dev"},
                 relationship: :direct,
                 scope: :runtime,
                 dependencies: [%Purl{type: "hex", name: "mime", version: "2.0.6"}]
               },
               "credo" => %Dependency{},
               "mime" => %Dependency{}
             } = umbrella_resolved

      assert %{
               "credo" => %Dependency{},
               "mime" => %Dependency{}
             } = child_resolved
    end
  end
end
