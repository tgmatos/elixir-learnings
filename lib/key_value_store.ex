defmodule KeyValueStore do
  use GenServer

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:get, key}, _, state) do
    {:reply, Map.get(state, key), state}
  end

  
  def handle_cast({:put, key, value}, state) do
   {:noreply, Map.put(state, key, value)}
  end

  def handle_cast({:delete, key}, state) do
    {:noreply, Map.delete(state, key), state}
  end

  def handle_cast({:update, key, new_value}, state) do
    {:noreply, Map.put(state, key, new_value), state}
  end

  def start do
    GenServer.start(KeyValueStore, nil, name: KeyValueStore)
  end

  def put(key, value) do
    GenServer.cast(KeyValueStore, {:put, key, value})
  end

  def get(key) do
    GenServer.call(KeyValueStore, {:get, key})
  end

  def delete(key) do
    GenServer.cast(KeyValueStore, key)
  end

  def update(key, new_value) do
    GenServer.cast(KeyValueStore, {:update, key, new_value})
  end

  def stop do
    GenServer.stop(KeyValueStore)
  end
  
end
