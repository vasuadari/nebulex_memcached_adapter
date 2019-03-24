# Nebulex adapter for Memcached

[![Build Status](https://circleci.com/gh/vasuadari/nebulex_memcached_adapter.svg?style=svg)](https://circleci.com/gh/vasuadari/nebulex_memcached_adapter)
[![Coverage Status](https://coveralls.io/repos/github/vasuadari/nebulex_memcached_adapter/badge.svg?branch=task%2Fsetup_ci)](https://coveralls.io/github/vasuadari/nebulex_memcached_adapter?branch=task%2Fsetup_ci)

This adapter is implemented using [Memcachex](https://github.com/ananthakumaran/memcachex),
a Memcached driver for Elixir.

This adapter supports multiple connection pools against different Memcached nodes
in a cluster. This feature enables resiliency and also be able to survive
in case any node(s) gets unreachable.

## Installation

Add `nebulex_memcached_adapter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nebulex_memcached_adapter, "~> 0.1.0"}
  ]
end
```

## Usage

After installing, we can define our cache to use Memcached adapter as follows:

```elixir
defmodule MyApp.MemcachedCache do
  use Nebulex.Cache,
    otp_app: :nebulex,
    adapter: NebulexMemcachedAdapter
end
```

The rest of Memcached configuration is set in our application environment, usually
defined in your `config/config.exs`:

```elixir
config :my_app, MyApp.MemcachedCache,
  pools: [
    primary: [
      host: "127.0.0.1",
      port: 11211,
      pool_size: 10
    ],
    #=> maybe more pools
  ]
```

Since this adapter is implemented by means of `Memcachex`, it inherits the same
options, including regular Memcached options and connection options as well. For
more information about the options, please check out `NebulexMemcachedAdapter`
module and also [Memcachex](https://github.com/ananthakumaran/memcachex).

## Testing

### Docker

```
docker-compose run test
```

### Without Docker

Ensure you have Memcached up and running on **localhost**(default host) and
**11211**(default port).

Since `NebulexMemcachedAdapter` uses the support modules and shared tests from
Nebulex and by default its `test` folder is not included within the `hex`
dependency, it is necessary to fetch `:nebulex` dependency directly from GtiHub.

Fetch deps:

```
$ MIX_ENV=test mix deps.get
```

Now we can run the tests:

```
$ mix test
```

Running tests with coverage:

```
$ mix coveralls.html
```

You can find the coverage report within `cover/excoveralls.html`.

## Benchmarks

Benchmarks were added using [benchee](https://github.com/PragTob/benchee);
to learn more, see the [benchmarks](./benchmarks) directory.

To run the benchmarks:

```
$ mix deps.get && mix run benchmarks/benchmark.exs
```

## Contributing

Contributions to Nebulex are very welcome and appreciated!

Use the [issue tracker](https://github.com/vasuadari/nebulex_memcached_adapter/issues)
for bug reports or feature requests. Open a
[pull request](https://github.com/vasuadari/nebulex_memcached_adapter/pulls)
when you are ready to contribute.

When submitting a pull request you should not update the [CHANGELOG.md](CHANGELOG.md),
and also make sure you test your changes thoroughly, include unit tests
alongside new or changed code.

Before to submit a PR it is highly recommended to run:

 * `mix test` to run tests
 * `mix coveralls.html && open cover/excoveralls.html` to run tests and check
   out code coverage (expected 100%).
 * `mix format && mix credo --strict` to format your code properly and find code
   style issues
 * `mix dialyzer` to run dialyzer for type checking; might take a while on the
   first invocation

## Copyright and License

Copyright (c) 2018, Vasu Adari.

NebulexMemcachedAdapter source code is licensed under the [MIT License](LICENSE).
