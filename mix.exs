defmodule NebulexMemcachedAdapter.MixProject do
  use Mix.Project

  @package_name :nebulex_memcached_adapter
  @github_url "https://github.com/vasuadari/nebulex_memcached_adapter"
  @version "0.1.0"

  def project do
    [
      app: @package_name,
      version: @version,
      elixir: "~> 1.6",
      deps: deps(),
      dialyzer: dialyzer()
    ] ++ coverage() ++ hex() ++ docs()
  end

  defp coverage do
    [
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp hex do
    [
      package: package(),
      description: "Nebulex adapter for Memcached"
    ]
  end

  defp package do
    [
      name: @package_name,
      maintainers: ["Vasu Adari"],
      licenses: ["MIT"],
      links: %{"Github" => @github_url}
    ]
  end

  defp docs do
    [
      name: "NebulexMemcachedAdapter",
      docs: [
        main: "NebulexMemcachedAdapter",
        source_ref: "v#{@version}",
        source_url: @github_url
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:memcachex, "~> 0.4"},
      # This is because the adapter tests need some support modules and shared
      # tests from nebulex dependency, and the hex dependency doesn't include
      # the test folder. Hence, to run the tests it is necessary to fetch
      # nebulex dependency directly from Github.
      {:nebulex, nebulex_opts()},

      # Test
      {:excoveralls, "~> 0.10.5", only: :test},
      {:benchee, "~> 0.14", optional: true, only: :dev},
      {:benchee_html, "~> 0.6", optional: true, only: :dev},

      # Code Analysis
      {:dialyxir, "~> 0.5", optional: true, only: [:dev, :test], runtime: false},
      {:credo, "~> 0.10", optional: true, only: [:dev, :test]},

      # Docs
      {:ex_doc, "~> 0.19", only: :docs}
    ]
  end

  defp nebulex_opts do
    case Mix.env() do
      :test ->
        [github: "cabol/nebulex"]

      _ ->
        "~> 1.0"
    end
  end

  defp dialyzer do
    [
      plt_add_apps: [:nebulex, :nebulex_memcached_adapter, :shards, :mix, :eex],
      flags: [
        :unmatched_returns,
        :error_handling,
        :race_conditions,
        :no_opaque,
        :unknown,
        :no_return
      ]
    ]
  end
end
