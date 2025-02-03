import kuzu

def execute(path, query, parameters={}):
    db = kuzu.Database(path)
    conn = kuzu.Connection(db)

    # Execute Cypher query
    query = fix_query(query)
    parameters = fix_parameters(parameters)
    response = conn.execute(query, parameters=parameters)
    
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
