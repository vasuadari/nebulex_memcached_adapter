defmodule NebulexMemcachedAdapterTest do
  use ExUnit.Case, async: true
  use NebulexMemcachedAdapter.CacheTest, cache: NebulexMemcachedAdapter.TestCache

  alias NebulexMemcachedAdapter.TestCache

  setup do
    {:ok, local} = TestCache.start_link()
    TestCache.flush()

    :ok

    on_exit(fn ->
      Process.sleep(100)
      Process.alive?(local) && TestCache.stop(local)
    end)
  end
end
