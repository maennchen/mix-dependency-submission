defmodule MixDependencySubmission.Submission.JobTest do
  use ExUnit.Case, async: true

  alias MixDependencySubmission.Submission.Job

  doctest Job

  describe "Jason.Encoder" do
    test "encodes filled struct" do
      job = %Job{
        id: "test",
        correlator: "test",
        html_url: URI.parse("http://example.com")
      }

      assert %{"correlator" => "test", "html_url" => "http://example.com", "id" => "test"} =
               job |> Jason.encode!() |> Jason.decode!()
    end

    test "encodes partial struct" do
      job = %Job{
        id: "test",
        correlator: "test"
      }

      assert %{"correlator" => "test", "id" => "test"} =
               job |> Jason.encode!() |> Jason.decode!()
    end
  end
end
