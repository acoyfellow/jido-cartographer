defmodule JidoCartographer.ResultStore do
  use GenServer

  @max_active 2
  @max_results 100

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def create(id, input), do: GenServer.call(__MODULE__, {:create, id, input})

  def running(id), do: GenServer.call(__MODULE__, {:update, id, %{status: "running"}})

  def complete(id, result),
    do: GenServer.call(__MODULE__, {:update, id, %{status: "complete", result: result}})

  def fail(id, reason),
    do: GenServer.call(__MODULE__, {:update, id, %{status: "failed", error: reason}})

  def get(id), do: GenServer.call(__MODULE__, {:get, id})

  def init(_), do: {:ok, %{}}

  def handle_call({:create, id, input}, _from, state) do
    active = Enum.count(state, fn {_id, result} -> result.status in ["queued", "running"] end)

    if active >= @max_active do
      {:reply, {:error, :busy}, state}
    else
      value = %{status: "queued", input: input, created_at: System.monotonic_time()}
      {:reply, :ok, state |> evict_oldest() |> Map.put(id, value)}
    end
  end

  def handle_call({:update, id, patch}, _from, state) do
    next = Map.update(state, id, patch, &Map.merge(&1, patch))
    {:reply, :ok, next}
  end

  def handle_call({:get, id}, _from, state), do: {:reply, Map.fetch(state, id), state}

  defp evict_oldest(state) when map_size(state) < @max_results, do: state

  defp evict_oldest(state) do
    state
    |> Enum.reject(fn {_id, result} -> result.status in ["queued", "running"] end)
    |> Enum.min_by(fn {_id, result} -> result.created_at end, fn -> nil end)
    |> case do
      {id, _result} -> Map.delete(state, id)
      nil -> state
    end
  end
end
