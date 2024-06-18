defmodule Todo.Server do
  use GenServer

  def start(name) do
    GenServer.start(Todo.Server, name)
  end

  def get(pid, date) do
    GenServer.call(pid, {:get, date})
  end

  def put(pid, request) do
    GenServer.cast(pid, {:put, request})
  end

  def update(pid, key, value) do
    GenServer.cast(pid, {:update, key, value})
  end

  def delete(pid, key) do
    GenServer.cast(pid, {:delete, key})
  end

  @impl GenServer
  def init(list_name) do
    IO.puts("Starting Todo.Database process")
    {:ok, {list_name, nil}, {:continue, :init}}
  end

  @impl GenServer
  def handle_continue(:init, {name, nil}) do
    todo_list = Todo.Database.get(name) || Todo.List.new()
    {:noreply, {name, todo_list}}
  end

  @impl GenServer
  def handle_call({:get, date}, _, {name, todo_list}) do
    {
      :reply,
      Todo.List.entries(todo_list, date),
      {name, todo_list}
    }
  end

  @impl GenServer
  def handle_cast({:put, request}, {name, todo_list}) do
    new_list = Todo.List.add_entry(todo_list, request)
    Todo.Database.store(name, new_list)
    {:noreply, {name, new_list}}
  end

  @impl GenServer
  def handle_cast({:update, entry}, {name, todo_list}) do
    new_list = Todo.List.update_entry(todo_list, entry.id, &Map.put(&1, entry.key, entry.value))
    Todo.Database.store(name, new_list)
    {:noreply, {name, new_list}}
  end

  @impl GenServer
  def handle_cast({:delete, key}, {name, todo_list}) do
    new_list = Todo.List.delete_entry(todo_list, key)
    Todo.Database.store(name, new_list)
    {:noreply, {name, new_list}}
  end
end
