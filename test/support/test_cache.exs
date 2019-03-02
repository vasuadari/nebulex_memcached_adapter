defmodule NebulexMemcachedAdapter.TestCache do
  use Nebulex.Cache,
    otp_app: :nebulex_memcached_adapter,
    adapter: NebulexMemcachedAdapter
end
