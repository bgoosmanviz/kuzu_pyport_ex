import kuzu

def execute(path, query, parameters={}):
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
