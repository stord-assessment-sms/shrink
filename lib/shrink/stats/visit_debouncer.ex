defmodule Shrink.Stats.VisitDebouncer do
  @moduledoc false
  use GenServer

  import Ecto.Query

  alias Ecto.Multi
  alias Shrink.Links.Link
  alias Shrink.Links.Visit
  alias Shrink.Repo

  require Logger

  @debounce_interval_ms Application.compile_env(:shrink, [__MODULE__, :debounce_interval_ms], 5000)

  def init(_opts), do: {:ok, %{}}

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  def handle_call(:flush, state) do
    :ok = flush_counts(state)
    {:reply, :ok, %{}}
  end

  # This technically does not preserve any timing information from the callee
  def handle_cast({:visit, slug}, state) do
    {:noreply, Map.update(state, slug, 1, &(&1 + 1)), @debounce_interval_ms}
  end

  def handle_info(:timeout, state) do
    :ok = flush_counts(state)

    {:noreply, %{}}
  end

  defp flush_counts(visits) when visits == %{}, do: :ok

  # NOTE: This function assumes that visits never contains an invalid slug that
  # doesn't have a corresponding DB row.
  defp flush_counts(visits) do
    slugs = Map.keys(visits)
    slugs_query = from(l in Link, where: l.slug in ^slugs, select: {l.slug, l.id})
    multi = Multi.all(Multi.new(), :slugs, slugs_query)

    visits
    |> Enum.reduce(multi, fn {slug, count}, multi ->
      Multi.insert(
        multi,
        {:visit, slug},
        fn %{slugs: slugs} ->
          link_id = slugs |> Enum.find(&(elem(&1, 0) == slug)) |> elem(1)
          %Visit{link_id: link_id, date: Date.utc_today(), hour: Time.utc_now().hour, count: count}
        end,
        conflict_target: [:link_id, :date, :hour],
        on_conflict: [inc: [count: count]]
      )
    end)
    |> Repo.transaction()
    |> report_multi_res()
  end

  defp report_multi_res({:ok, changes}) do
    {_slugs, counts} = Map.pop(changes, :slugs)
    # counts = changes |> Enum.reject(&(elem(&1, 0) == :slugs)) |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)
    # total = counts |> Map.values() |> Enum.sum()
    Logger.info("Flushed update visit counts across #{map_size(counts)} slugs")
    :ok
  end

  defp report_multi_res({:error, _step, _changeset, _changes_so_far}) do
    Logger.error("Failed to flush in-memory visit counts")
    :ok
  end

  def flush(server) do
    GenServer.call(server, :flush)
  end

  def visit(slug) do
    GenServer.cast({:via, PartitionSupervisor, {Shrink.Stats.VisitDebouncers, slug}}, {:visit, slug})
  end
end
