defmodule NebulexMemcachedAdapter.Command do
  # Memcachex command executor
  def get(cache, key, opts \\ []) do
    cache
    |> get_conn()
    |> Memcache.get(key, opts)
  end

  def multi_get(cache, keys, opts \\ []) do
    cache
    |> get_conn()
    |> Memcache.multi_get(keys, opts)
  end

  def set(cache, key, value, opts \\ []) do
    cache
    |> get_conn()
    |> Memcache.set(key, value, opts)
  end

  def set_cas(cache, key, value, cas, opts \\ []) do
    cache
    |> get_conn()
    |> Memcache.set_cas(key, value, cas, opts)
  end

  def multi_set(cache, array, opts \\ []) do
    cache
    |> get_conn()
    |> Memcache.multi_set(array, opts)
  end

  def add(cache, key, value, opts \\ []) do
    cache
    |> get_conn()
    |> Memcache.add(key, value, opts)
  end

  def replace(cache, key, value, opts \\ []) do
    cache
    |> get_conn()
    |> Memcache.replace(key, value, opts)
  end

  def delete(cache, key) do
    cache
    |> get_conn()
    |> Memcache.delete(key)
  end

  def delete_cas(cache, key, cas) do
    cache
    |> get_conn()
    |> Memcache.delete_cas(key, cas)
  end

  def incr(cache, key, incrby) do
    cache
    |> get_conn()
    |> Memcache.incr(key, by: incrby, default: 1)
  end

  def size(cache) do
    {:ok, %{"curr_items" => size}} =
      cache
      |> get_conn()
      |> Memcache.stat()
    String.to_integer(size)
  end

  def flush(cache) do
    cache
    |> get_conn()
    |> Memcache.flush()
  end

  defp get_conn(cache) do
    index = rem(System.unique_integer([:positive]), cache.__pool_size__)
    :"#{cache}_memcache_#{index}"
  end
end
