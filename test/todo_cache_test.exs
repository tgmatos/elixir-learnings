defmodule TodoCacheTest do
  use ExUnit.Case
  doctest TodoCache

  test "greets the world" do
    assert TodoCache.hello() == :world
  end
end
