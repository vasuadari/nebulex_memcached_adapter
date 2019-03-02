defmodule NebulexMemcachedAdapterTest do
  use ExUnit.Case
  doctest NebulexMemcachedAdapter

  test "greets the world" do
    assert NebulexMemcachedAdapter.hello() == :world
  end
end
