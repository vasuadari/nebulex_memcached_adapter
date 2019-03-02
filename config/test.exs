use Mix.Config

config :nebulex_memcached_adapter, NebulexMemcachedAdapter.TestCache,
  version_generator: Nebulex.Version.Timestamp,
  pools: [
    primary: [
      hostname: System.get_env("MEMCACHED_HOST") || "127.0.0.1",
      port: System.get_env("MEMCACHED_PORT") || 11211
    ],
    secondary: [
      hostname: System.get_env("MEMCACHED_HOST") || "127.0.0.1",
      port: System.get_env("MEMCACHED_PORT") || 11211,
      pool_size: 2
    ]
  ]
