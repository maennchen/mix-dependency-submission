defmodule MixDependencySubmissionTest do
  use ExUnit.Case, async: false
  doctest MixDependencySubmission

  test "greets the world" do
    assert MixDependencySubmission.hello() == :world
  end
end
