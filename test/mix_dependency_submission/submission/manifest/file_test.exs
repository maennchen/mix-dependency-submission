defmodule MixDependencySubmission.Submission.Manifest.FileTest do
  use ExUnit.Case, async: true

  alias MixDependencySubmission.Submission.Manifest.File

  describe "Jason.Encoder" do
    test "encodes filled struct" do
      file = %File{
        source_location: "mix.exs"
      }

      assert %{"source_location" => "mix.exs"} = file |> Jason.encode!() |> Jason.decode!()
    end

    test "encodes empty struct" do
      file = %File{}

      assert %{} == file |> Jason.encode!() |> Jason.decode!()
    end
  end
end
