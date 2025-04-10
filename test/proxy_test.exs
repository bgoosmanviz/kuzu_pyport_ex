defmodule KuzuPyPortExTest do
  use ExUnit.Case, async: false
  alias KuzuPyPortEx.Proxy

  setup do
    # Start the GenServer
    {:ok, _} = Proxy.start_link([])
    :ok
  end

  test "can set timeout" do
    assert {:error, :timeout} = Proxy.execute("tmp", "RETURN 1;", %{}, timeout: 1)
  end

  test "can create vector index" do
    # We have to open a long lived connection, otherwise the VECTOR extension will go out of scope immediately after it's loaded.
    path = "/tmp/demo-db"
    Proxy.open(path, timeout: :infinity)
    Proxy.execute(path, "INSTALL VECTOR;", %{}, timeout: :infinity) |> dbg
    Proxy.execute(path, "LOAD VECTOR;", %{}, timeout: :infinity) |> dbg
    Proxy.execute(path, "CREATE NODE TABLE Book(id SERIAL PRIMARY KEY, title STRING, title_embedding FLOAT[384], published_year INT64);")
    Proxy.execute(path, "CREATE NODE TABLE Publisher(name STRING PRIMARY KEY);")
    Proxy.execute(path, "CREATE REL TABLE PublishedBy(FROM Book TO Publisher);")
    Proxy.execute(path, """
    CALL CREATE_VECTOR_INDEX(
        'Book',
        'title_vec_index',
        'title_embedding'
    );
    """)
    Proxy.execute(path, "CALL DROP_VECTOR_INDEX('Book', 'title_vec_index');", %{}, timeout: :infinity) |> dbg
    Proxy.close(path)
  end

  test "execute/2 performs duplication of text" do
    File.rm_rf!("tmp")
    assert {:ok, [[1]]} = Proxy.execute("tmp", "RETURN 1;")
  end

  test "import demo-db" do
    path = "/tmp/demo-db"
    File.rm_rf!(path)

    # Create schema
    Proxy.execute(path, "CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))")

    Proxy.execute(
      path,
      "CREATE NODE TABLE City(name STRING, population INT64, PRIMARY KEY (name))"
    )

    Proxy.execute(path, "CREATE REL TABLE Follows(FROM User TO User, since INT64)")
    Proxy.execute(path, "CREATE REL TABLE LivesIn(FROM User TO City)")

    # Insert data
    Proxy.execute(path, "COPY User FROM './priv/csv/user.csv'")
    Proxy.execute(path, "COPY City FROM './priv/csv/city.csv'")
    Proxy.execute(path, "COPY Follows FROM './priv/csv/follows.csv'")
    Proxy.execute(path, "COPY LivesIn FROM './priv/csv/lives-in.csv'")

    # Execute Cypher query
    assert {:ok,
            [
              [~c"Adam", ~c"Karissa", 2020],
              [~c"Adam", ~c"Zhang", 2020],
              [~c"Karissa", ~c"Zhang", 2021],
              [~c"Zhang", ~c"Noura", 2022]
            ]} =
             Proxy.execute(
               path,
               """
               MATCH (a:User)-[f:Follows]->(b:User)
               RETURN a.name, b.name, f.since;
               """
             )

    assert {:ok, [[~c"Karissa"]]} =
             Proxy.execute(path, "MATCH (a:User) WHERE a.name = $name RETURN a.name", %{
               "name" => "Karissa"
             })
  end
end
