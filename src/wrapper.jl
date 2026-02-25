# High-level Julia API wrappers for Ladybug
# These provide a more idiomatic Julia interface to the C API

# Database management
function open_database(path::String; config::SystemConfig = SystemConfig())
    out_db = Ref{DatabasePtr}()
    state = lbug_database_init(path, config, out_db)
    
    if state != LbugSuccess
        error("Failed to open database at $path")
    end
    
    Database(out_db[], path)
end

function close_database(db::Database)
    if db.ptr != C_NULL
        lbug_database_destroy(db.ptr)
        db.ptr = C_NULL
    end
    nothing
end

# Connection management
function connect(database::Database)
    out_conn = Ref{ConnectionPtr}()
    state = lbug_connection_init(database.ptr, out_conn)
    
    if state != LbugSuccess
        error("Failed to connect to database")
    end
    
    Connection(out_conn[], database)
end

function disconnect(conn::Connection)
    if conn.ptr != C_NULL
        lbug_connection_destroy(conn.ptr)
        conn.ptr = C_NULL
    end
    nothing
end

# Query execution
function query(connection::Connection, query_string::String)
    out_result = Ref{QueryResultPtr}()
    state = lbug_connection_query(connection.ptr, query_string, out_result)
    
    if state != LbugSuccess
        error("Query failed: $query_string")
    end
    
    QueryResult(out_result[], connection, query_string)
end

# Prepared statements
function prepare(connection::Connection, query_string::String)
    out_stmt = Ref{PreparedStatementPtr}()
    state = lbug_connection_prepare(connection.ptr, query_string, out_stmt)
    
    if state != LbugSuccess
        error("Failed to prepare statement: $query_string")
    end
    
    stmt = PreparedStatement(out_stmt[], connection, query_string)
    
    if !lbug_prepared_statement_is_success(stmt.ptr)
        msg = lbug_prepared_statement_get_error_message(stmt.ptr)
        error("Failed to prepare statement: $msg")
    end
    
    stmt
end

function execute(connection::Connection, prepared::PreparedStatement)
    out_result = Ref{QueryResultPtr}()
    state = lbug_connection_execute(connection.ptr, prepared.ptr, out_result)
    
    if state != LbugSuccess
        error("Failed to execute prepared statement")
    end
    
    QueryResult(out_result[], connection, prepared.query)
end

function destroy_prepared_statement(stmt::PreparedStatement)
    if stmt.ptr != C_NULL
        lbug_prepared_statement_destroy(stmt.ptr)
        stmt.ptr = C_NULL
    end
    nothing
end

# Query result handling
function destroy_query_result(result::QueryResult)
    if result.ptr != C_NULL
        lbug_query_result_destroy(result.ptr)
        result.ptr = C_NULL
    end
    nothing
end

function is_success(result::QueryResult)
    lbug_query_result_is_success(result.ptr)
end

function get_error_message(result::QueryResult)
    lbug_query_result_get_error_message(result.ptr)
end

function get_num_columns(result::QueryResult)
    Int(lbug_query_result_get_num_columns(result.ptr))
end

function get_num_rows(result::QueryResult)
    Int(lbug_query_result_get_num_tuples(result.ptr))
end

function get_column_names(result::QueryResult)
    n_cols = get_num_columns(result)
    names = Vector{String}(undef, n_cols)
    for i in 0:(n_cols-1)
        names[i+1] = lbug_query_result_get_column_name(result.ptr, UInt64(i))
    end
    names
end

function get_column_data_type(result::QueryResult, index::Integer)
    lbug_query_result_get_column_data_type(result.ptr, UInt64(index))
end

function get_query_summary(result::QueryResult)
    lbug_query_result_get_query_summary(result.ptr)
end

function has_next(result::QueryResult)
    lbug_query_result_has_next(result.ptr)
end

function get_next(result::QueryResult)
    out_tuple = Ref{FlatTuplePtr}()
    state = lbug_query_result_get_next(result.ptr, out_tuple)
    
    if state != LbugSuccess
        error("Failed to get next tuple")
    end
    
    FlatTuple(out_tuple[])
end

function reset_iterator(result::QueryResult)
    lbug_query_result_reset_iterator(result.ptr)
end

function Base.iterate(result::QueryResult, state=nothing)
    if !has_next(result)
        return nothing
    end
    
    tuple = get_next(result)
    (tuple, nothing)
end

Base.IteratorSize(::Type{QueryResult}) = Base.SizeUnknown()

# Flat tuple handling
function destroy_flat_tuple(tuple::FlatTuple)
    if tuple.ptr != C_NULL
        lbug_flat_tuple_destroy(tuple.ptr)
        tuple.ptr = C_NULL
    end
    nothing
end

function get_value(tuple::FlatTuple, index::Integer)
    out_value = Ref{ValuePtr}()
    state = lbug_flat_tuple_get_value(tuple.ptr, UInt64(index), out_value)
    
    if state != LbugSuccess
        error("Failed to get value at index $index")
    end
    
    LBUGValue(out_value[])
end

function Base.getindex(tuple::FlatTuple, index::Integer)
    get_value(tuple, index)
end

function Base.length(tuple::FlatTuple)
    # Note: FlatTuple doesn't have a direct length function in the C API
    # This would need to be tracked by the QueryResult
    error("Use get_num_columns on the QueryResult to get the number of columns")
end

# Data type handling
function destroy_data_type(dt::DataType)
    if dt.ptr != C_NULL
        lbug_data_type_destroy(dt.ptr)
        dt.ptr = C_NULL
    end
    nothing
end

function get_id(dt::DataType)
    lbug_data_type_get_id(dt.ptr)
end

function Base.:(==)(dt1::DataType, dt2::DataType)
    lbug_data_type_equals(dt1.ptr, dt2.ptr)
end

# Value handling
function destroy_value(val::LBUGValue)
    if val.ptr != C_NULL
        lbug_value_destroy(val.ptr)
        val.ptr = C_NULL
    end
    nothing
end

function is_null(val::LBUGValue)
    lbug_value_is_null(val.ptr)
end

function set_null!(val::LBUGValue, is_null::Bool)
    lbug_value_set_null(val.ptr, is_null)
end

function get_data_type(val::LBUGValue)
    out_type = Ref{DataTypePtr}()
    lbug_value_get_data_type(val.ptr, out_type)
    DataType(out_type[])
end

# Value extraction
function get_bool(val::LBUGValue)
    out = Ref{Bool}()
    state = lbug_value_get_bool(val.ptr, out)
    state == LbugSuccess || error("Value is not a boolean")
    out[]
end

function get_int64(val::LBUGValue)
    out = Ref{Int64}()
    state = lbug_value_get_int64(val.ptr, out)
    state == LbugSuccess || error("Value is not an Int64")
    out[]
end

function get_int32(val::LBUGValue)
    out = Ref{Int32}()
    state = lbug_value_get_int32(val.ptr, out)
    state == LbugSuccess || error("Value is not an Int32")
    out[]
end

function get_int16(val::LBUGValue)
    out = Ref{Int16}()
    state = lbug_value_get_int16(val.ptr, out)
    state == LbugSuccess || error("Value is not an Int16")
    out[]
end

function get_int8(val::LBUGValue)
    out = Ref{Int8}()
    state = lbug_value_get_int8(val.ptr, out)
    state == LbugSuccess || error("Value is not an Int8")
    out[]
end

function get_uint64(val::LBUGValue)
    out = Ref{UInt64}()
    state = lbug_value_get_uint64(val.ptr, out)
    state == LbugSuccess || error("Value is not a UInt64")
    out[]
end

function get_uint32(val::LBUGValue)
    out = Ref{UInt32}()
    state = lbug_value_get_uint32(val.ptr, out)
    state == LbugSuccess || error("Value is not a UInt32")
    out[]
end

function get_uint16(val::LBUGValue)
    out = Ref{UInt16}()
    state = lbug_value_get_uint16(val.ptr, out)
    state == LbugSuccess || error("Value is not a UInt16")
    out[]
end

function get_uint8(val::LBUGValue)
    out = Ref{UInt8}()
    state = lbug_value_get_uint8(val.ptr, out)
    state == LbugSuccess || error("Value is not a UInt8")
    out[]
end

function get_float(val::LBUGValue)
    out = Ref{Float32}()
    state = lbug_value_get_float(val.ptr, out)
    state == LbugSuccess || error("Value is not a Float")
    out[]
end

function get_double(val::LBUGValue)
    out = Ref{Float64}()
    state = lbug_value_get_double(val.ptr, out)
    state == LbugSuccess || error("Value is not a Double")
    out[]
end

function get_string(val::LBUGValue)
    out = Ref{Ptr{Cchar}}()
    state = lbug_value_get_string(val.ptr, out)
    state == LbugSuccess || error("Value is not a String")
    str = unsafe_string(out[])
    lbug_destroy_string(out[])
    str
end

function get_date(val::LBUGValue)
    out = Ref{LBUGDate}()
    state = lbug_value_get_date(val.ptr, out)
    state == LbugSuccess || error("Value is not a Date")
    out[]
end

function get_timestamp(val::LBUGValue)
    out = Ref{LBUGTimestamp}()
    state = lbug_value_get_timestamp(val.ptr, out)
    state == LbugSuccess || error("Value is not a Timestamp")
    out[]
end

function get_internal_id(val::LBUGValue)
    out = Ref{InternalID}()
    state = lbug_value_get_internal_id(val.ptr, out)
    state == LbugSuccess || error("Value is not an InternalID")
    out[]
end

# Generic value extraction
function Base.convert(::Type{Bool}, val::LBUGValue)
    get_bool(val)
end

function Base.convert(::Type{Int64}, val::LBUGValue)
    get_int64(val)
end

function Base.convert(::Type{Int32}, val::LBUGValue)
    get_int32(val)
end

function Base.convert(::Type{Float64}, val::LBUGValue)
    get_double(val)
end

function Base.convert(::Type{Float32}, val::LBUGValue)
    get_float(val)
end

function Base.convert(::Type{String}, val::LBUGValue)
    get_string(val)
end

function Base.show(io::IO, val::LBUGValue)
    if is_null(val)
        print(io, "NULL")
    else
        str = lbug_value_to_string(val.ptr)
        print(io, str)
        lbug_destroy_string(pointer(str))
    end
end

# Query summary handling
function destroy_query_summary(summary::QuerySummary)
    if summary.ptr != C_NULL
        lbug_query_summary_destroy(summary.ptr)
        summary.ptr = C_NULL
    end
    nothing
end

function get_compiling_time(summary::QuerySummary)
    lbug_query_summary_get_compiling_time(summary.ptr)
end

function get_execution_time(summary::QuerySummary)
    lbug_query_summary_get_execution_time(summary.ptr)
end

# Prepared statement binding
function bind!(stmt::PreparedStatement, param_name::String, value::Bool)
    lbug_prepared_statement_bind_bool(stmt.ptr, param_name, value)
end

function bind!(stmt::PreparedStatement, param_name::String, value::Int64)
    lbug_prepared_statement_bind_int64(stmt.ptr, param_name, value)
end

function bind!(stmt::PreparedStatement, param_name::String, value::Int32)
    lbug_prepared_statement_bind_int32(stmt.ptr, param_name, value)
end

function bind!(stmt::PreparedStatement, param_name::String, value::Float64)
    lbug_prepared_statement_bind_double(stmt.ptr, param_name, value)
end

function bind!(stmt::PreparedStatement, param_name::String, value::Float32)
    lbug_prepared_statement_bind_float(stmt.ptr, param_name, value)
end

function bind!(stmt::PreparedStatement, param_name::String, value::String)
    lbug_prepared_statement_bind_string(stmt.ptr, param_name, value)
end

function bind!(stmt::PreparedStatement, param_name::String, value::LBUGValue)
    lbug_prepared_statement_bind_value(stmt.ptr, param_name, value.ptr)
end

# Version functions
function get_version()
    lbug_get_version()
end

function get_storage_version()
    lbug_get_storage_version()
end

# Result conversion
function to_matrix(result::QueryResult)
    n_cols = get_num_columns(result)
    n_rows = get_num_rows(result)
    
    # Reset iterator to start
    reset_iterator(result)
    
    # Collect all rows
    data = Vector{Vector{Any}}(undef, n_rows)
    row_idx = 1
    
    for tuple in result
        row = Vector{Any}(undef, n_cols)
        for col_idx in 1:n_cols
            val = tuple[col_idx - 1]  # 0-indexed in C API
            if is_null(val)
                row[col_idx] = missing
            else
                dt = get_data_type(val)
                type_id = get_id(dt)
                row[col_idx] = convert_value(val, type_id)
            end
        end
        data[row_idx] = row
        row_idx += 1
    end
    
    # Convert to matrix
    if n_rows == 0
        return Matrix{Any}(undef, 0, n_cols)
    end
    
    mat = Matrix{Any}(undef, n_rows, n_cols)
    for i in 1:n_rows
        for j in 1:n_cols
            mat[i, j] = data[i][j]
        end
    end
    
    mat
end

function to_dataframe(result::QueryResult)
    n_cols = get_num_columns(result)
    n_rows = get_num_rows(result)
    columns = get_column_names(result)
    
    # Reset iterator
    reset_iterator(result)
    
    # Initialize columns
    data = Dict{String, Vector{Any}}()
    for col in columns
        data[col] = Vector{Any}()
    end
    
    # Collect data
    for tuple in result
        for (i, col) in enumerate(columns)
            val = tuple[i - 1]  # 0-indexed in C API
            if is_null(val)
                push!(data[col], missing)
            else
                dt = get_data_type(val)
                type_id = get_id(dt)
                push!(data[col], convert_value(val, type_id))
            end
        end
    end
    
    # Create DataFrame-like structure
    NamedTuple{Tuple(Symbol.(columns))}(Tuple(data[col] for col in columns))
end

# Helper function to convert values based on type
function convert_value(val::LBUGValue, type_id::DataTypeID)
    if type_id == LBUG_BOOL
        return get_bool(val)
    elseif type_id == LBUG_INT64 || type_id == LBUG_SERIAL
        return get_int64(val)
    elseif type_id == LBUG_INT32
        return get_int32(val)
    elseif type_id == LBUG_INT16
        return get_int16(val)
    elseif type_id == LBUG_INT8
        return get_int8(val)
    elseif type_id == LBUG_UINT64
        return get_uint64(val)
    elseif type_id == LBUG_UINT32
        return get_uint32(val)
    elseif type_id == LBUG_UINT16
        return get_uint16(val)
    elseif type_id == LBUG_UINT8
        return get_uint8(val)
    elseif type_id == LBUG_DOUBLE
        return get_double(val)
    elseif type_id == LBUG_FLOAT
        return get_float(val)
    elseif type_id == LBUG_STRING
        return get_string(val)
    elseif type_id == LBUG_DATE
        return get_date(val)
    elseif type_id == LBUG_TIMESTAMP
        return get_timestamp(val)
    elseif type_id == LBUG_INTERNAL_ID
        return get_internal_id(val)
    else
        # Fallback: convert to string
        str = lbug_value_to_string(val.ptr)
        result = unsafe_string(pointer(str))
        lbug_destroy_string(pointer(str))
        return result
    end
end

# Connection configuration
function set_max_threads!(conn::Connection, num_threads::Integer)
    lbug_connection_set_max_num_thread_for_exec(conn.ptr, UInt64(num_threads))
end

function get_max_threads(conn::Connection)
    out = Ref{UInt64}()
    state = lbug_connection_get_max_num_thread_for_exec(conn.ptr, out)
    state == LbugSuccess || error("Failed to get max threads")
    Int(out[])
end

function set_timeout!(conn::Connection, timeout_ms::Integer)
    lbug_connection_set_query_timeout(conn.ptr, UInt64(timeout_ms))
end

function interrupt!(conn::Connection)
    lbug_connection_interrupt(conn.ptr)
end

# Convenience do-block syntax
function open_database(f::Function, path::String; config::SystemConfig = SystemConfig())
    db = open_database(path; config=config)
    try
        f(db)
    finally
        close_database(db)
    end
end

function connect(f::Function, database::Database)
    conn = connect(database)
    try
        f(conn)
    finally
        disconnect(conn)
    end
end

function query(f::Function, connection::Connection, query_string::String)
    result = query(connection, query_string)
    try
        f(result)
    finally
        destroy_query_result(result)
    end
end
