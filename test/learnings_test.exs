defmodule LearningsTest do
  use ExUnit.Case
  doctest Learnings

  test "greets the world" do
    assert Learnings.hello() == :world
  end
end
