defmodule MixDependencySubmission.Fetcher.MixFileTest do
  use MixDependencySubmission.FixtureCase, async: false

  alias MixDependencySubmission.Fetcher.MixFile
  alias MixDependencySubmission.Util

  doctest MixDependencySubmission

  describe inspect(&MixFile.fetch/1) do
    @tag :tmp_dir
    @tag fixture_app: "app_locked"
    test "generates valid manifest for 'app_locked' fixture", %{app_path: app_path} do
      Util.in_project(app_path, fn _mix_module ->
        assert %{
                 credo: %{
                   scm: Hex.SCM,
                   mix_dep: {:credo, "~> 1.7", [hex: "credo", repo: "hexpm"]},
                   scope: :runtime,
                   relationship: :direct
                 },
                 expo: %{
                   scm: Mix.SCM.Git,
                   mix_dep: {:expo, nil, [git: "https://github.com/elixir-gettext/expo.git", checkout: nil]},
                   scope: :runtime,
                   relationship: :direct
                 },
                 mime: %{
                   scm: Hex.SCM,
                   mix_dep: {:mime, "~> 2.0", [hex: "mime", repo: "hexpm"]},
                   scope: :runtime,
                   relationship: :direct
                 }
               } = MixFile.fetch()
      end)
    end

    @tag :tmp_dir
    @tag fixture_app: "app_library"
    test "generates valid manifest for 'app_library' fixture", %{app_path: app_path} do
      Util.in_project(app_path, fn _mix_module ->
        assert %{
                 credo: %{
                   mix_dep: {:credo, "~> 1.7", [hex: "credo", repo: "hexpm"]},
                   relationship: :direct,
                   scm: Hex.SCM,
                   scope: :runtime
                 },
                 path_dep: %{
                   scope: :runtime,
                   scm: Mix.SCM.Path,
                   mix_dep: {:path_dep, nil, [dest: "/tmp", path: "/tmp"]},
                   relationship: :direct
                 }
               } = MixFile.fetch()
      end)
    end

    @tag :tmp_dir
    test "skips manifest for project without mix.exs", %{tmp_dir: tmp_dir} do
      Util.in_project(tmp_dir, fn _mix_module ->
        assert nil == MixFile.fetch()
      end)
    end
  end
end
