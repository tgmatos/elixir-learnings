defmodule Todo.Database do
  @db_folder "./persist"
  @pool_size 3

  def start_link do
    IO.puts("Starting database server.")
    File.mkdir_p!(@db_folder)
    
    children = Enum.map(1..@pool_size, &worker_spec/1)
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def store(key, data) do
    key
    |> choose_worker
    |> Todo.DatabaseWorkers.store(key, data)
  end

  def get(key) do
    key
    |> choose_worker
    |> Todo.DatabaseWorkers.get(key)
  end

  def worker_spec(worker_id) do
    default_worker_spec = {Todo.DatabaseWorkers, {@db_folder, worker_id}}
    a = Supervisor.child_spec(default_worker_spec, id: worker_id)
    IO.inspect(a)
    a
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end
  
  defp choose_worker(key) do
    :erlang.phash2(key, @pool_size) + 1
  end
end
