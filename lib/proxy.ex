defmodule KuzuPyPortEx.Proxy do
  use GenServer
  use Export.Python

  # optional, omit if adding this to a supervision tree
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Open a connection to a KuzuDB database.

  ```elixir
  KuzuPyPortEx.Proxy.open("path/to/kuzu/db")
  KuzuPyPortEx.Proxy.open("path/to/kuzu/db", timeout: 5000) # with 5 second timeout
  ```
  """
  def open(path, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 5000)

    try do
      GenServer.call(__MODULE__, {:open, path}, timeout)
    catch
      :exit, {:timeout, _} ->
        {:error, :timeout}

      error ->
        {:error, error}
    end
  end

  @doc """
  Close a connection to a KuzuDB database.

  ```elixir
  KuzuPyPortEx.Proxy.close("path/to/kuzu/db")
  KuzuPyPortEx.Proxy.close("path/to/kuzu/db", timeout: 5000) # with 5 second timeout
  ```
  """
  def close(path, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 5000)

    try do
      GenServer.call(__MODULE__, {:close, path}, timeout)
    catch
      :exit, {:timeout, _} ->
        {:error, :timeout}

      error ->
        {:error, error}
    end
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

  def handle_call({:open, path}, _from, %{py: py} = state) do
    try do
      result = Python.call(py, "kuzu_proxy", "open", [path])
      {:reply, {:ok, result}, state}
    rescue
      error in [RuntimeError, ArgumentError] ->
        {:reply, {:error, error.message}, state}
      error ->
        {:reply, {:error, "Unexpected error: #{inspect(error)}"}, state}
    end
  end

  def handle_call({:close, path}, _from, %{py: py} = state) do
    try do
      result = Python.call(py, "kuzu_proxy", "close", [path])
      {:reply, {:ok, result}, state}
    rescue
      error in [RuntimeError, ArgumentError] ->
        {:reply, {:error, error.message}, state}
      error ->
        {:reply, {:error, "Unexpected error: #{inspect(error)}"}, state}
    end
  end

  def handle_call({:execute, path, query, parameters}, _from, %{py: py} = state) do
    try do
      result = Python.call(py, "kuzu_proxy", "execute", [path, query, parameters])
      {:reply, {:ok, result}, state}
    rescue
      error in [RuntimeError, ArgumentError] ->
        {:reply, {:error, error.message}, state}
      error ->
        {:reply, {:error, "Unexpected error: #{inspect(error)}"}, state}
    end
  end

  def terminate(_reason, %{py: py} = _state) do
    Python.stop(py)
    :ok
  end
end
