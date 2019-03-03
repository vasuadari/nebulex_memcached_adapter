defmodule NebulexMemcachedAdapter do
  @moduledoc """
  Nebulex adapter for Memcached..

  This adapter is implemented by means of `Memcachex`, a Memcached driver for
  Elixir.

  This adapter supports multiple connection pools against different memcached
  nodes in a cluster. This feature enables resiliency, be able to survive in
  case any node(s) gets unreachable.

  ## Adapter Options

  In addition to `Nebulex.Cache` shared options, this adapters supports the
  following options:

    * `:pools` - The list of connection pools for Memcached. Each element (pool)
      holds the same options as `Memcachex` (including connection options), and
      the `:pool_size` (number of connections to keep in the pool).

  ## Memcachex Options (for each pool)

  Since this adapter is implemented by means of `Memachex`, it inherits the same
  options (including connection options). These are some of the main ones:

    * `:hostname` - (string) hostname of the memcached server. Defaults to "localhost".

    * `:port` - (integer) port on which the memcached server is listening.  Defaults to
      11211.

    * `:auth` - (tuple) only plain authentication method is supported.It is specified
      using the following format {:plain, "username", "password"}. Defaults to nil.

    * `ttl` - (integer) a default expiration time in seconds. This value will be used
      if the :ttl value is not specified for a operation. Defaults to 0(means forever).

    * `:namespace` - (string) prepend each key with the given value.

    * `:backoff_initial` - (integer) initial backoff (in milliseconds) to be used in
      case of connection failure. Defaults to 500.

    * `:backoff_max` - (integer) maximum allowed interval between two connection attempt.
      Defaults to 30_000.

  For more information about the options (Memcache and connection options), please
  checkout `Memcachex` docs.

  In addition to `Memcachex` options, it supports:

    * `:pool_size` - The number of connections to keep in the pool
      (default: `System.schedulers_online()`).

  ## Example

  We can define our cache to use Memcached adapter as follows:

      defmodule MyApp.MemachedCache do
        use Nebulex.Cache,
          otp_app: :nebulex,
          adapter: NebulexMemcachedAdapter
      end

  The configuration for the cache must be in your application environment,
  usually defined in your `config/config.exs`:

      config :my_app, MyApp.MemachedCache,
        pools: [
          primary: [
            hostname: "127.0.0.1",
            port: 11211
          ],
          secondary: [
            hostname: "127.0.0.1",
            port: 11211,
            pool_size: 2
          ]
        ]

  For more information about the usage, check out `Nebulex.Cache` as well.
  """

  # Inherit default transaction implementation
  use Nebulex.Adapter.Transaction

  # Provide Cache Implementation
  @behaviour Nebulex.Adapter

  alias Nebulex.Object
  alias NebulexMemcachedAdapter.Command

  @default_pool_size System.schedulers_online()

  ## Adapter

  @impl true
  defmacro __before_compile__(%{module: module}) do
    otp_app = Module.get_attribute(module, :otp_app)
    config = Module.get_attribute(module, :config)

    pool_size =
      config
      |> Keyword.get(:pools)
      |> pool_size(module, otp_app)

    quote do
      def __pool_size__, do: unquote(pool_size)
    end
  end

  defp pool_size(nil, module, otp_app) do
    raise ArgumentError,
          "missing :pools configuration in " <> "config #{inspect(otp_app)}, #{inspect(module)}"
  end

  defp pool_size([], _module, _otp_app), do: 0

  defp pool_size([{_, pool} | other_pools], module, otp_app) do
    pool_size(pool) + pool_size(other_pools, module, otp_app)
  end

  defp pool_size(pool), do: Keyword.get(pool, :pool_size, @default_pool_size)

  @impl true
  def init(opts) do
    cache = Keyword.fetch!(opts, :cache)

    children =
      opts
      |> Keyword.fetch!(:pools)
      |> children(cache)

    {:ok, children}
  end

  defp children(pools, cache, offset \\ 0)

  defp children([], _cache, _offset), do: []

  defp children([{_, pool} | other_pools], cache, offset) do
    pool_size = pool_size(pool)
    next_offset = offset + pool_size

    for index <- offset..(offset + pool_size - 1) do
      pool
      |> Keyword.delete(:pool_size)
      |> child_spec(index, cache)
    end ++ children(other_pools, cache, next_offset)
  end

  defp child_spec(opts, index, cache) do
    Supervisor.child_spec(
      {Memcache, [opts, [name: :"#{cache}_memcache_#{index}"]]},
      id: {Memcache, index}
    )
  end

  @impl true
  def get(cache, key, opts) do
    opts
    |> Keyword.get(:return)
    |> do_get(cache, key)
  end

  @impl true
  def get_many(cache, keys, _opts) do
    key_values =
      Enum.map(keys, fn key ->
        {key, get(cache, key, [])}
      end)

    key_values
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  @impl true
  def set(cache, %Object{key: key} = object, opts) do
    action = Keyword.get(opts, :action, :set)
    ttl = Keyword.get(opts, :ttl, 0)
    do_set(action, cache, encode(key), encode(object), ttl)
  end

  @impl true
  def set_many(cache, objects, opts) do
    ttl = opts |> Keyword.get(:ttl, 0)

    key_values =
      objects
      |> Enum.map(fn %Object{key: key} = object ->
        {encode(key), encode(object)}
      end)

    case Command.multi_set(cache, key_values, ttl: ttl) do
      {:ok, _} -> :ok
      _ -> :error
    end
  end

  @impl true
  def take(cache, key, _opts) do
    with {:ok, value, cas} <- Command.get(cache, encoded_key = encode(key), cas: true) do
      _ = Command.delete_cas(cache, encoded_key, cas)

      value
      |> decode()
      |> object(key, -1)
    else
      _ -> nil
    end
  end

  defp do_set(:set, cache, key, value, ttl) do
    case Command.set(cache, key, value, ttl: ttl) do
      {:ok} -> true
      _ -> false
    end
  end

  defp do_set(:add, cache, key, value, ttl) do
    case Command.add(cache, key, value, ttl: ttl) do
      {:ok} -> true
      _ -> false
    end
  end

  defp do_set(:replace, cache, key, value, ttl) do
    case Command.replace(cache, key, value, ttl: ttl) do
      {:ok} -> true
      _ -> false
    end
  end

  @impl true
  def expire(cache, key, :infinity) do
    expire(cache, encode(key), nil)
  end

  def expire(cache, key, ttl) do
    with {:ok, value, cas} <- Command.get(cache, encode(key), cas: true),
         {:ok} <- set_cas(cache, key, decode(value), cas, ttl) do
      Object.expire_at(ttl) || :infinity
    else
      _ -> nil
    end
  end

  defp set_cas(cache, key, %Object{} = object, cas, ttl) do
    value = object(object, key, ttl)
    set_cas(cache, key, encode(value), cas, ttl)
  end

  defp set_cas(cache, key, value, cas, ttl) do
    Command.set_cas(
      cache,
      encode(key),
      value,
      cas,
      ttl: ttl || 0
    )
  end

  @impl true
  def update_counter(cache, key, incrby, _opts) when is_integer(incrby) do
    case Command.incr(cache, encode(key), incrby) do
      {:ok, value} -> value
      _ -> nil
    end
  end

  @impl true
  def delete(cache, key, _opts) do
    _ = Command.delete(cache, encode(key))
    :ok
  end

  @impl true
  def has_key?(cache, key) do
    case get(cache, key, []) do
      nil -> false
      _ -> true
    end
  end

  @impl true
  def object_info(cache, key, :ttl) do
    case get(cache, key, []) do
      nil -> nil
      object -> Object.remaining_ttl(object.expire_at)
    end
  end

  def object_info(cache, key, :version) do
    case get(cache, key, []) do
      nil -> nil
      object -> object.version
    end
  end

  @impl true
  def size(cache) do
    Command.size(cache)
  end

  @impl true
  def flush(cache) do
    _ = Command.flush(cache)
    :ok
  end

  defp do_get(:object, cache, key) do
    case Command.get(cache, encode(key)) do
      {:ok, value} ->
        value
        |> decode()
        |> object(key, -1)

      {:error, _} ->
        nil
    end
  end

  defp do_get(_, cache, key) do
    case Command.get(cache, encode(key)) do
      {:ok, value} ->
        value
        |> decode()
        |> object(key, -1)

      {:error, _} ->
        nil
    end
  end

  defp encode(data) do
    to_string(data)
  rescue
    _e ->
      :erlang.term_to_binary(data)
  end

  defp decode(nil), do: nil

  defp decode(data) do
    if String.printable?(data) do
      data
    else
      :erlang.binary_to_term(data)
    end
  end

  defp object(nil, _key, _ttl), do: nil
  defp object(%Object{} = object, _key, -1), do: object

  defp object(%Object{} = object, _key, ttl) do
    %{object | expire_at: Object.expire_at(ttl)}
  end

  defp object(value, key, -1) do
    %Object{key: key, value: value}
  end
end
