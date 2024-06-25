defmodule Todo.DatabaseWorkers do
  alias Exqlite.Sqlite3
  use GenServer
  defstruct conns: %{}

  def start_link({state, worker_id}) do
    GenServer.start_link(
      __MODULE__,
      state,
      name: via_tuple(worker_id)
    )
  end

  def store(worker_id, key, data) do
    GenServer.cast(via_tuple(worker_id), {:store, key, data})
  end

  def store_all(worker_id, key, data) do
    GenServer.cast(via_tuple(worker_id), {:store_all, key, data})
  end

  def get(worker_id, key) do
    GenServer.call(via_tuple(worker_id), {:get, key})
  end

  def via_tuple(worker_id) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, worker_id})
  end

  @impl GenServer
  def init(state) do
    {:ok, {state, %Todo.DatabaseWorkers{}}}
  end

  @impl GenServer
  def handle_cast({:store, key, data}, {folder, connections}) do
    new_connections = case check_connection({connections, key}) do
      {:error, nil} ->
        {:ok, conn} = Sqlite3.open("#{folder}/#{key}.sqlite")
        insert_into_db(conn, data)
        put_connection({connections, key, conn})

      {:ok, conn} ->
        insert_into_db(conn, data)
        connections
    end

    {:noreply, {folder, new_connections}}
  end
  
  @impl GenServer
  def handle_cast({:store_all, key, data}, {folder, connections}) do
    entries = data.entries

    # If the connection doesn't exists
    # I must create one
    # And append it to the connections.conn
    new_connections = case check_connection({connections, key}) do
      {:error, nil} ->
        {:ok, conn} = Sqlite3.open("#{folder}/#{key}.sqlite")
        bootstrap_db(conn)
        insert_all_into_db(conn, entries)
        put_connection({connections, key, conn})

      {:ok, conn} ->
        insert_into_db(conn, entries)
        connections
    end

    {:noreply, {folder, new_connections}}
  end

  @impl GenServer
  def handle_call({:get, key}, _, state) do
    IO.inspect(key)
    {folder, connections} = state
    
    {data, conns} =
      case check_connection({connections, key}) do
        {:error, nil} ->
          {:ok, conn} = Sqlite3.open("#{folder}/#{key}.sqlite")
          {
            get_data_from_sqlite(conn),
            put_connection({connections, key, conn})
          }

        {:ok, conn} ->
          {
            get_data_from_sqlite(conn),
            connections
          }
      end

    {:reply, data, {folder, conns}}
  end


  defp check_connection({connections, key}) do
    result = Map.get(connections.conns, key, :error)

    connection = case result do
      :error -> {:error, nil}
      conn -> {:ok, conn}
    end

    connection
  end

  defp get_data_from_sqlite(conn) do
    sql = "SELECT * FROM TODOLIST"
    {:ok, statement} = Sqlite3.prepare(conn, sql)
    {:ok, data} = Sqlite3.fetch_all(conn, statement)

    entries = parse_data(data)

    last_key =
      entries
      |> Map.keys()
      |> List.last(0)

    %Todo.List{next_id: last_key, entries: entries}
  end

  defp parse_data(data) do
    data
    |> Enum.map(fn entry ->
      [id, date, title] = entry
      {:ok, date} = Date.from_iso8601(date)
      %{id => %{id: id, date: date, title: title}}
    end)
    |> Enum.reduce(%{}, fn map, acc ->
      Map.merge(map, acc)
    end)
  end

  defp put_connection({connections, name, conn}) do
    Map.put(connections, :conns, Map.put(connections.conns, name, conn))
  end

  defp bootstrap_db(conn) do
    sql = """
    CREATE TABLE IF NOT EXISTS todolist (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    title TEXT NOT NULL
    );
    """

    Sqlite3.execute(conn, sql)
  end

  defp insert_all_into_db(conn, data) do
    Enum.each(data.entries, fn entry ->
      insert_into_db(conn, entry)
    end)
  end

  defp insert_into_db(conn, entry) do
    sql = """
    INSERT INTO todolist (date, title)
    VALUES (?1, ?2);
    """

    {:ok, statement} = Sqlite3.prepare(conn, sql)
    {_, %{id: _, date: date, title: title}} = entry
    Sqlite3.bind(conn, statement, [date, title])
    Sqlite3.step(conn, statement)
    Sqlite3.release(conn, statement)
  end
end
