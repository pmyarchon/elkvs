defmodule Storage do
  use GenServer
  require Logger

  @compile {:parse_transform, :ms_transform}  # Enable MatchSpec parse transform

  @init_interval 0
  @cleanup_interval 1000
  @db_file 'db.dets'
  @db_opts [{:file, @db_file}, {:type, :set}]
  @db_table :storage

  # API
  def lookup(key) do
    result = :dets.lookup(@db_table, key)
    case result do
      [entry|_] -> entry
      [] -> nil
      other -> other
    end
  end

  def create(key, value, ttl) do
    :dets.insert_new(@db_table, {key, value, ttl, Utils.timestamp() + ttl}) === true
  end

  def update(key, value, ttl) do
    case :dets.member(@db_table, key) do
      true -> :dets.insert(@db_table, {key, value, ttl, Utils.timestamp() + ttl}) === :ok
      _ -> false
    end
  end

  def delete(key) do
    case :dets.member(@db_table, key) do
      true -> :dets.delete(@db_table, key) === :ok
      _ -> false
    end
  end

  # GenServer API
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(init_arg) do
    Process.send_after(__MODULE__, :init, @init_interval)
    {:ok, init_arg}
  end

  # GenServer callbacks
  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  def handle_info(:init, state) do
    :dets.open_file(@db_table, @db_opts)
    Process.send_after(__MODULE__, :clean, @cleanup_interval)
    {:noreply, state}
  end

  def handle_info(:clean, state) do
    cleanup_expired()
    Process.send_after(__MODULE__, :clean, @cleanup_interval)
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def terminate(_msg, state) do
    :dets.close(@db_table)
    {:noreply, state}
  end

  # Internal functions
  defp cleanup_expired() do
    now = Utils.timestamp()

    match_spec = :ets.fun2ms(fn({_, _, _, valid_thru}) when valid_thru < now -> true end)
    num_deleted = :dets.select_delete(@db_table, match_spec)

    if num_deleted > 0 do
      Logger.debug("#{num_deleted} keys expired and cleaned...")
    end
  end
end
