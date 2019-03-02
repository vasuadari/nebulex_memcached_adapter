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
      deps: deps()
    ] ++ hex() ++ docs()
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
      {:ex_doc, "~> 0.19", only: :doc}
    ]
  end

  defp nebulex_opts do
    case Mix.env() do
      :test ->
        [github: "cabol/nebulex", tag: "v1.0.0"]

      _ ->
        "~> 1.0"
    end
  end
end
