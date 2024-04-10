defmodule Shrink.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  import Cachex.Spec

  @impl true
  def start(_type, _args) do
    children = [
      ShrinkWeb.Telemetry,
      Shrink.Repo,
      {DNSCluster, query: Application.get_env(:shrink, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Shrink.PubSub},
      {PartitionSupervisor, child_spec: Shrink.Stats.VisitDebouncer, name: Shrink.Stats.VisitDebouncers},
      {Cachex,
       interval: 15_000,
       limit: limit(size: 500, reclaim: 0.1),
       name: Shrink.Links,
       warmers: [warmer(module: Shrink.Links.CacheWarmer, state: Shrink.Repo)]},
      ShrinkWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Shrink.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ShrinkWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
