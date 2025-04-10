import kuzu

# Store active connections and their databases
_connections = {}

def open(path):
    if path in _connections:
        return _connections[path]['conn']
    db = kuzu.Database(path)
    conn = kuzu.Connection(db)
    _connections[path] = {'db': db, 'conn': conn}
    return conn

def close(path):
    if path in _connections:
        # Close the connection first
        _connections[path]['conn'].close()
        # Then close the database
        _connections[path]['db'].close()
        del _connections[path]

def execute(path, query, parameters={}, use_existing_connection=True):
    if use_existing_connection and path in _connections:
        conn = _connections[path]['conn']
    else:
        db = kuzu.Database(path)
        conn = kuzu.Connection(db)

    # Execute Cypher query
    query = fix_query(query)
    parameters = fix_parameters(parameters)
    response = conn.execute(query, parameters=parameters)
    
    if isinstance(response, kuzu.QueryResult):
        return consume_query_result(response)
    elif isinstance(response, list) and len(response) > 0 and isinstance(response[0], kuzu.query_result.QueryResult):
        # Assume it's a list of QueryResults
        return [consume_query_result(r) for r in response]
    else:
        raise ValueError(f"Unexpected response type: {type(response)}")


def consume_query_result(response):
    results = []
    while response.has_next():
        results.append(response.get_next())
    return results


def fix_query(query):
    return query.decode('utf-8')


def fix_parameters(parameters):
    return {k.decode('utf-8'): fix_parameter_value(v) for k, v in parameters.items()}


def fix_parameter_value(value):
    if isinstance(value, bytes):
        return value.decode('utf-8')
    return value
