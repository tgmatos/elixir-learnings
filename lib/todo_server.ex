defmodule TodoServer do
  def init do
      TodoList.new()
  end

  def handle_call({:get, date}, state) do
    {TodoList.entries(state, date), state}
  end

  def handle_cast({:put, request}, state) do
    TodoList.add_entry(state, request)
  end
  
  def handle_cast({:update, entry}, state) do
    TodoList.update_entry(state, entry.id, &Map.put(&1, entry.key, entry.value))
  end

  def handle_cast({:delete, key}, state) do
    TodoList.delete_entry(state, key)
  end

  def start do
    ServerProcess.start(TodoServer)
  end

  def get(pid, date) do
    ServerProcess.call(pid, {:get, date})
  end

  def put(pid, request) do
    ServerProcess.cast(pid, {:put, request})
  end

  def update(pid, key, value) do
    ServerProcess.cast(pid, {:update, key, value})
  end

  def delete(pid, key) do
    ServerProcess.cast(pid, {:delete, key})
  end

end

