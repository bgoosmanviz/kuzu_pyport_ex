defmodule KuzuPyPortEx.Proxy do
  use GenServer
  use Export.Python

  # optional, omit if adding this to a supervision tree
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Execute a query on a KuzuDB database.

  ```elixir
  KuzuPyPortEx.Proxy.execute("path/to/kuzu/db", "SELECT * FROM users")
  KuzuPyPortEx.Proxy.execute("path/to/kuzu/db", "SELECT * FROM users WHERE name = $name", %{name: "Adam"})
  KuzuPyPortEx.Proxy.execute("path/to/kuzu/db", "SELECT * FROM users", %{}, timeout: 5000) # with 5 second timeout
  ```
  """
  def execute(path, query, parameters \\ %{}, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 5000)

    try do
      GenServer.call(__MODULE__, {:execute, path, query, parameters}, timeout)
    catch
      :exit, {:timeout, _} ->
        {:error, :timeout}

      error ->
        {:error, error}
    end
  end

  # server
  def init(state) do
    priv_path = Path.join(:code.priv_dir(:kuzu_pyport_ex), "python")
    {:ok, py} = Python.start_link(python_path: priv_path)
    {:ok, Map.put(state, :py, py)}
  end

  def handle_call({:execute, path, query, parameters}, _from, %{py: py} = state) do
    result = Python.call(py, "kuzu_proxy", "execute", [path, query, parameters])
    {:reply, {:ok, result}, state}
  end

  def terminate(_reason, %{py: py} = _state) do
    Python.stop(py)
    :ok
  end
end
