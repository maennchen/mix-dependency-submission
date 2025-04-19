defmodule MixDependencySubmission.Submission.ManifestTest do
  use ExUnit.Case, async: true

  alias MixDependencySubmission.Submission.Manifest
  alias MixDependencySubmission.Submission.Manifest.File

  doctest Manifest

  describe "Jason.Encoder" do
    test "encodes filled struct" do
      manifest = %Manifest{
        name: "test",
        file: %File{source_location: "test"},
        metadata: %{"foo" => "bar"},
        resolved: %{}
      }

      assert %{
               "file" => %{"source_location" => "test"},
               "metadata" => %{"foo" => "bar"},
               "name" => "test",
               "resolved" => %{}
             } =
               manifest |> Jason.encode!() |> Jason.decode!()
    end

    test "encodes partial struct" do
      manifest = %Manifest{
        name: "test"
      }

      assert %{"name" => "test"} = manifest |> Jason.encode!() |> Jason.decode!()
    end
  end
end
