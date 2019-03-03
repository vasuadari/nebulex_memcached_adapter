use Mix.Config

config :nebulex_memcached_adapter, NebulexMemcachedAdapter.TestCache,
  version_generator: Nebulex.Version.Timestamp,
  pools: [
    primary: [
      hostname: System.get_env("NEBULEX_MEMCACHED_HOST") || "localhost",
      port: System.get_env("NEBULEX_MEMCACHED_PORT") || 11211
    ],
    secondary: [
      hostname: System.get_env("NEBULEX_MEMCACHED_HOST") || "localhost",
      port: System.get_env("NEBULEX_MEMCACHED_PORT") || 11211,
      pool_size: 2
    ]
  ]
