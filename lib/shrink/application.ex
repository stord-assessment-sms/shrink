defmodule Shrink.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  import Cachex.Spec

  require Logger

  @idle_interval Application.compile_env(:shrink, [:idle_shutdown_interval], :timer.seconds(60))

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
      ShrinkWeb.Endpoint,
      {Task, fn -> idle_shutdown(@idle_interval) end}
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

  def idle_shutdown(interval) do
    Process.sleep(interval)
    {:ok, bandit_supervisor} = Bandit.PhoenixAdapter.bandit_pid(ShrinkWeb.Endpoint)
    {:ok, conns} = ThousandIsland.connection_pids(bandit_supervisor)

    if conns == [] do
      Logger.info("No connections, shutting down...")
      ThousandIsland.suspend(bandit_supervisor)
      System.halt(0)
    else
      idle_shutdown(interval)
    end
  end
end
