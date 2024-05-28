defmodule TodoServer do
  use GenServer
  
  def init do
      {:ok, TodoList.new()}
  end

  def handle_call({:get, date}, _, state) do
    {:reply, TodoList.entries(state, date), state}
  end

  def handle_cast({:put, request}, state) do
    {:noreply, TodoList.add_entry(state, request)}
  end
  
  def handle_cast({:update, entry}, state) do
    {:noreply, TodoList.update_entry(state, entry.id, &Map.put(&1, entry.key, entry.value)), state}
  end

  def handle_cast({:delete, key}, state) do
    {:noreply, TodoList.delete_entry(state, key), state}
  end

  def start do
    GenServer.start(TodoServer, nil, name: TodoServer)
  end

  def get(date) do
    GenServer.call(TodoServer, {:get, date})
  end

  def put(request) do
    GenServer.cast(TodoServer, {:put, request})
  end

  def update(key, value) do
    GenServer.cast(TodoServer, {:update, key, value})
  end

  def delete(key) do
    GenServer.cast(TodoServer, {:delete, key})
  end

end

