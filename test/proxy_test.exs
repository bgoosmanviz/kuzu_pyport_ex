defmodule KuzuPyPortExTest do
  use ExUnit.Case, async: false
  alias KuzuPyPortEx.Proxy

  @path "tmp"

  setup do
    # Start the GenServer
    {:ok, _} = Proxy.start_link([])
    # Clean up any existing database
    File.rm_rf(@path)
    # Create fresh database directory
    File.mkdir_p(@path)
    # Open the database
    Proxy.open(@path, timeout: :infinity)
    :ok
  end

  test "can set timeout" do
    assert {:error, :timeout} = Proxy.execute("tmp", "RETURN 1;", %{}, timeout: 1)
    Proxy.close(@path)
  end

  test "python errors do not crash the genserver" do
    assert {:error, _} =
             Proxy.execute(@path, "CALL DROP_VECTOR_INDEX('Book', 'title_vec_index');", %{},
               timeout: :infinity
             )

    assert {:ok, _} = Proxy.execute(@path, "RETURN 1;", %{}, timeout: :infinity)
    Proxy.close(@path)
  end

  test "can create vector index" do
    Proxy.execute(@path, "INSTALL VECTOR;", %{}, timeout: :infinity) |> dbg
    Proxy.execute(@path, "LOAD VECTOR;", %{}, timeout: :infinity) |> dbg

    Proxy.execute(
      @path,
      "CREATE NODE TABLE Book(id SERIAL PRIMARY KEY, title STRING, title_embedding FLOAT[384], published_year INT64);"
    )

    Proxy.execute(@path, "CREATE NODE TABLE Publisher(name STRING PRIMARY KEY);")
    Proxy.execute(@path, "CREATE REL TABLE PublishedBy(FROM Book TO Publisher);")

    Proxy.execute(@path, """
    CALL CREATE_VECTOR_INDEX(
        'Book',
        'title_vec_index',
        'title_embedding'
    );
    """)

    Proxy.execute(@path, "CALL DROP_VECTOR_INDEX('Book', 'title_vec_index');", %{},
      timeout: :infinity
    )
    |> dbg
    Proxy.close(@path)
  end

  test "execute/2 performs duplication of text" do
    assert {:ok, [[1]]} = Proxy.execute(@path, "RETURN 1;")
    Proxy.close(@path)
  end

  test "import demo-db" do
    # Create schema
    Proxy.execute(@path, "CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))")

    Proxy.execute(
      @path,
      "CREATE NODE TABLE City(name STRING, population INT64, PRIMARY KEY (name))"
    )

    Proxy.execute(@path, "CREATE REL TABLE Follows(FROM User TO User, since INT64)")
    Proxy.execute(@path, "CREATE REL TABLE LivesIn(FROM User TO City)")

    # Insert data
    Proxy.execute(@path, "COPY User FROM './priv/csv/user.csv'")
    Proxy.execute(@path, "COPY City FROM './priv/csv/city.csv'")
    Proxy.execute(@path, "COPY Follows FROM './priv/csv/follows.csv'")
    Proxy.execute(@path, "COPY LivesIn FROM './priv/csv/lives-in.csv'")

    # Execute Cypher query
    assert {:ok,
            [
              [~c"Adam", ~c"Karissa", 2020],
              [~c"Adam", ~c"Zhang", 2020],
              [~c"Karissa", ~c"Zhang", 2021],
              [~c"Zhang", ~c"Noura", 2022]
            ]} =
             Proxy.execute(
               @path,
               """
               MATCH (a:User)-[f:Follows]->(b:User)
               RETURN a.name, b.name, f.since
               ORDER BY a.name, b.name;
               """
             )

    assert {:ok, [[~c"Karissa"]]} =
             Proxy.execute(@path, "MATCH (a:User) WHERE a.name = $name RETURN a.name", %{
               "name" => "Karissa"
             })
    Proxy.close(@path)
  end
end
