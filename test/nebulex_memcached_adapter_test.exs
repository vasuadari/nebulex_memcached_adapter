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
