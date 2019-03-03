defmodule NebulexMemcachedAdapterTest do
  use ExUnit.Case, async: true
  use NebulexMemcachedAdapter.CacheTest, cache: NebulexMemcachedAdapter.TestCache

  alias NebulexMemcachedAdapter.TestCache, as: Cache

  setup do
    {:ok, local} = Cache.start_link()
    Cache.flush()

    :ok

    on_exit(fn ->
      Process.sleep(100)
      Process.alive?(local) && Cache.stop(local)
    end)
  end

  test "fail on __before_compile__ because missing pool_size in config" do
    assert_raise ArgumentError, ~r"missing :pools configuration", fn ->
      defmodule WrongCache do
        use Nebulex.Cache,
          otp_app: :nebulex,
          adapter: NebulexMemcachedAdapter
      end
    end
  end
end
