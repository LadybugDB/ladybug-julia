# Low-level FFI bindings to liblbug C API
# These functions directly wrap the C library functions

# Helper function for ccall
macro lbugcall(func, ret_type, arg_types, args...)
    # Build the ccall expression programmatically
    ccall_expr = Expr(:call, :ccall)
    
    # First argument: (func_name, lib)
    func_tuple = Expr(:tuple, esc(func), :(LIBLBUG[]))
    push!(ccall_expr.args, func_tuple)
    
    # Second argument: return type
    push!(ccall_expr.args, esc(ret_type))
    
    # Third argument: argument types tuple
    push!(ccall_expr.args, esc(arg_types))
    
    # Remaining arguments: the actual arguments
    for arg in args
        push!(ccall_expr.args, esc(arg))
    end
    
    quote
        if LIBLBUG[] == C_NULL
            error("Ladybug library not loaded. Run: bash scripts/download-liblbug.sh")
        end
        $ccall_expr
    end
end

# Database functions
function lbug_database_init(database_path::String, system_config::SystemConfig, out_database::Ref{DatabasePtr})
    @lbugcall(
        :lbug_database_init,
        LBUGState,
        (Cstring, SystemConfig, Ref{DatabasePtr}),
        database_path, system_config, out_database
    )
end

function lbug_database_destroy(database::DatabasePtr)
    @lbugcall(:lbug_database_destroy, Cvoid, (DatabasePtr,), database)
end

function lbug_default_system_config()
    config_ref = Ref{SystemConfig}()
    @lbugcall(:lbug_default_system_config, SystemConfig, ())
end

# Connection functions
function lbug_connection_init(database::DatabasePtr, out_connection::Ref{ConnectionPtr})
    @lbugcall(
        :lbug_connection_init,
        LBUGState,
        (DatabasePtr, Ref{ConnectionPtr}),
        database, out_connection
    )
end

function lbug_connection_destroy(connection::ConnectionPtr)
    @lbugcall(:lbug_connection_destroy, Cvoid, (ConnectionPtr,), connection)
end

function lbug_connection_set_max_num_thread_for_exec(connection::ConnectionPtr, num_threads::UInt64)
    @lbugcall(
        :lbug_connection_set_max_num_thread_for_exec,
        LBUGState,
        (ConnectionPtr, UInt64),
        connection, num_threads
    )
end

function lbug_connection_get_max_num_thread_for_exec(connection::ConnectionPtr, out_result::Ref{UInt64})
    @lbugcall(
        :lbug_connection_get_max_num_thread_for_exec,
        LBUGState,
        (ConnectionPtr, Ref{UInt64}),
        connection, out_result
    )
end

function lbug_connection_query(connection::ConnectionPtr, query::String, out_query_result::Ref{QueryResultPtr})
    @lbugcall(
        :lbug_connection_query,
        LBUGState,
        (ConnectionPtr, Cstring, Ref{QueryResultPtr}),
        connection, query, out_query_result
    )
end

function lbug_connection_prepare(connection::ConnectionPtr, query::String, out_prepared_statement::Ref{PreparedStatementPtr})
    @lbugcall(
        :lbug_connection_prepare,
        LBUGState,
        (ConnectionPtr, Cstring, Ref{PreparedStatementPtr}),
        connection, query, out_prepared_statement
    )
end

function lbug_connection_execute(connection::ConnectionPtr, prepared_statement::PreparedStatementPtr, out_query_result::Ref{QueryResultPtr})
    @lbugcall(
        :lbug_connection_execute,
        LBUGState,
        (ConnectionPtr, PreparedStatementPtr, Ref{QueryResultPtr}),
        connection, prepared_statement, out_query_result
    )
end

function lbug_connection_interrupt(connection::ConnectionPtr)
    @lbugcall(:lbug_connection_interrupt, Cvoid, (ConnectionPtr,), connection)
end

function lbug_connection_set_query_timeout(connection::ConnectionPtr, timeout_in_ms::UInt64)
    @lbugcall(
        :lbug_connection_set_query_timeout,
        LBUGState,
        (ConnectionPtr, UInt64),
        connection, timeout_in_ms
    )
end

# Prepared statement functions
function lbug_prepared_statement_destroy(prepared_statement::PreparedStatementPtr)
    @lbugcall(:lbug_prepared_statement_destroy, Cvoid, (PreparedStatementPtr,), prepared_statement)
end

function lbug_prepared_statement_is_success(prepared_statement::PreparedStatementPtr)
    @lbugcall(:lbug_prepared_statement_is_success, Bool, (PreparedStatementPtr,), prepared_statement)
end

function lbug_prepared_statement_get_error_message(prepared_statement::PreparedStatementPtr)
    msg_ptr = @lbugcall(:lbug_prepared_statement_get_error_message, Ptr{Cchar}, (PreparedStatementPtr,), prepared_statement)
    msg_ptr == C_NULL ? "" : unsafe_string(msg_ptr)
end

# Binding functions for prepared statements
function lbug_prepared_statement_bind_bool(prepared_statement::PreparedStatementPtr, param_name::String, value::Bool)
    @lbugcall(
        :lbug_prepared_statement_bind_bool,
        LBUGState,
        (PreparedStatementPtr, Cstring, Bool),
        prepared_statement, param_name, value
    )
end

function lbug_prepared_statement_bind_int64(prepared_statement::PreparedStatementPtr, param_name::String, value::Int64)
    @lbugcall(
        :lbug_prepared_statement_bind_int64,
        LBUGState,
        (PreparedStatementPtr, Cstring, Int64),
        prepared_statement, param_name, value
    )
end

function lbug_prepared_statement_bind_int32(prepared_statement::PreparedStatementPtr, param_name::String, value::Int32)
    @lbugcall(
        :lbug_prepared_statement_bind_int32,
        LBUGState,
        (PreparedStatementPtr, Cstring, Int32),
        prepared_statement, param_name, value
    )
end

function lbug_prepared_statement_bind_double(prepared_statement::PreparedStatementPtr, param_name::String, value::Float64)
    @lbugcall(
        :lbug_prepared_statement_bind_double,
        LBUGState,
        (PreparedStatementPtr, Cstring, Float64),
        prepared_statement, param_name, value
    )
end

function lbug_prepared_statement_bind_float(prepared_statement::PreparedStatementPtr, param_name::String, value::Float32)
    @lbugcall(
        :lbug_prepared_statement_bind_float,
        LBUGState,
        (PreparedStatementPtr, Cstring, Float32),
        prepared_statement, param_name, value
    )
end

function lbug_prepared_statement_bind_string(prepared_statement::PreparedStatementPtr, param_name::String, value::String)
    @lbugcall(
        :lbug_prepared_statement_bind_string,
        LBUGState,
        (PreparedStatementPtr, Cstring, Cstring),
        prepared_statement, param_name, value
    )
end

function lbug_prepared_statement_bind_value(prepared_statement::PreparedStatementPtr, param_name::String, value::ValuePtr)
    @lbugcall(
        :lbug_prepared_statement_bind_value,
        LBUGState,
        (PreparedStatementPtr, Cstring, ValuePtr),
        prepared_statement, param_name, value
    )
end

# Query result functions
function lbug_query_result_destroy(query_result::QueryResultPtr)
    @lbugcall(:lbug_query_result_destroy, Cvoid, (QueryResultPtr,), query_result)
end

function lbug_query_result_is_success(query_result::QueryResultPtr)
    @lbugcall(:lbug_query_result_is_success, Bool, (QueryResultPtr,), query_result)
end

function lbug_query_result_get_error_message(query_result::QueryResultPtr)
    msg_ptr = @lbugcall(:lbug_query_result_get_error_message, Ptr{Cchar}, (QueryResultPtr,), query_result)
    msg_ptr == C_NULL ? "" : unsafe_string(msg_ptr)
end

function lbug_query_result_get_num_columns(query_result::QueryResultPtr)
    @lbugcall(:lbug_query_result_get_num_columns, UInt64, (QueryResultPtr,), query_result)
end

function lbug_query_result_get_num_tuples(query_result::QueryResultPtr)
    @lbugcall(:lbug_query_result_get_num_tuples, UInt64, (QueryResultPtr,), query_result)
end

function lbug_query_result_get_column_name(query_result::QueryResultPtr, index::UInt64)
    out_name = Ref{Ptr{Cchar}}()
    state = @lbugcall(
        :lbug_query_result_get_column_name,
        LBUGState,
        (QueryResultPtr, UInt64, Ref{Ptr{Cchar}}),
        query_result, index, out_name
    )
    state == LbugSuccess || error("Failed to get column name")
    unsafe_string(out_name[])
end

function lbug_query_result_get_column_data_type(query_result::QueryResultPtr, index::UInt64)
    out_type = Ref{DataTypePtr}()
    state = @lbugcall(
        :lbug_query_result_get_column_data_type,
        LBUGState,
        (QueryResultPtr, UInt64, Ref{DataTypePtr}),
        query_result, index, out_type
    )
    state == LbugSuccess || error("Failed to get column data type")
    DataType(out_type[])
end

function lbug_query_result_get_query_summary(query_result::QueryResultPtr)
    out_summary = Ref{QuerySummaryPtr}()
    state = @lbugcall(
        :lbug_query_result_get_query_summary,
        LBUGState,
        (QueryResultPtr, Ref{QuerySummaryPtr}),
        query_result, out_summary
    )
    state == LbugSuccess || error("Failed to get query summary")
    QuerySummary(out_summary[])
end

function lbug_query_result_has_next(query_result::QueryResultPtr)
    @lbugcall(:lbug_query_result_has_next, Bool, (QueryResultPtr,), query_result)
end

function lbug_query_result_get_next(query_result::QueryResultPtr, out_flat_tuple::Ref{FlatTuplePtr})
    @lbugcall(
        :lbug_query_result_get_next,
        LBUGState,
        (QueryResultPtr, Ref{FlatTuplePtr}),
        query_result, out_flat_tuple
    )
end

function lbug_query_result_has_next_query_result(query_result::QueryResultPtr)
    @lbugcall(:lbug_query_result_has_next_query_result, Bool, (QueryResultPtr,), query_result)
end

function lbug_query_result_get_next_query_result(query_result::QueryResultPtr, out_next::Ref{QueryResultPtr})
    @lbugcall(
        :lbug_query_result_get_next_query_result,
        LBUGState,
        (QueryResultPtr, Ref{QueryResultPtr}),
        query_result, out_next
    )
end

function lbug_query_result_to_string(query_result::QueryResultPtr)
    str_ptr = @lbugcall(:lbug_query_result_to_string, Ptr{Cchar}, (QueryResultPtr,), query_result)
    str_ptr == C_NULL ? "" : unsafe_string(str_ptr)
end

function lbug_query_result_reset_iterator(query_result::QueryResultPtr)
    @lbugcall(:lbug_query_result_reset_iterator, Cvoid, (QueryResultPtr,), query_result)
end

function lbug_query_result_get_arrow_schema(query_result::QueryResultPtr, out_schema::Ref{ArrowSchema})
    @lbugcall(
        :lbug_query_result_get_arrow_schema,
        LBUGState,
        (QueryResultPtr, Ref{ArrowSchema}),
        query_result, out_schema
    )
end

function lbug_query_result_get_next_arrow_chunk(query_result::QueryResultPtr, chunk_size::Int64, out_arrow_array::Ref{ArrowArray})
    @lbugcall(
        :lbug_query_result_get_next_arrow_chunk,
        LBUGState,
        (QueryResultPtr, Int64, Ref{ArrowArray}),
        query_result, chunk_size, out_arrow_array
    )
end

# Flat tuple functions
function lbug_flat_tuple_destroy(flat_tuple::FlatTuplePtr)
    @lbugcall(:lbug_flat_tuple_destroy, Cvoid, (FlatTuplePtr,), flat_tuple)
end

function lbug_flat_tuple_get_value(flat_tuple::FlatTuplePtr, index::UInt64, out_value::Ref{ValuePtr})
    @lbugcall(
        :lbug_flat_tuple_get_value,
        LBUGState,
        (FlatTuplePtr, UInt64, Ref{ValuePtr}),
        flat_tuple, index, out_value
    )
end

function lbug_flat_tuple_to_string(flat_tuple::FlatTuplePtr)
    str_ptr = @lbugcall(:lbug_flat_tuple_to_string, Ptr{Cchar}, (FlatTuplePtr,), flat_tuple)
    str_ptr == C_NULL ? "" : unsafe_string(str_ptr)
end

# Data type functions
function lbug_data_type_create(id::DataTypeID, child_type::DataTypePtr, num_elements::UInt64, out_type::Ref{DataTypePtr})
    @lbugcall(
        :lbug_data_type_create,
        Cvoid,
        (DataTypeID, DataTypePtr, UInt64, Ref{DataTypePtr}),
        id, child_type, num_elements, out_type
    )
end

function lbug_data_type_clone(data_type::DataTypePtr, out_type::Ref{DataTypePtr})
    @lbugcall(:lbug_data_type_clone, Cvoid, (DataTypePtr, Ref{DataTypePtr}), data_type, out_type)
end

function lbug_data_type_destroy(data_type::DataTypePtr)
    @lbugcall(:lbug_data_type_destroy, Cvoid, (DataTypePtr,), data_type)
end

function lbug_data_type_equals(data_type1::DataTypePtr, data_type2::DataTypePtr)
    @lbugcall(:lbug_data_type_equals, Bool, (DataTypePtr, DataTypePtr), data_type1, data_type2)
end

function lbug_data_type_get_id(data_type::DataTypePtr)
    @lbugcall(:lbug_data_type_get_id, DataTypeID, (DataTypePtr,), data_type)
end

function lbug_data_type_get_num_elements_in_array(data_type::DataTypePtr, out_result::Ref{UInt64})
    @lbugcall(
        :lbug_data_type_get_num_elements_in_array,
        LBUGState,
        (DataTypePtr, Ref{UInt64}),
        data_type, out_result
    )
end

# Value creation functions
function lbug_value_create_null()
    ptr = @lbugcall(:lbug_value_create_null, ValuePtr, ())
    LBUGValue(ptr)
end

function lbug_value_create_null_with_data_type(data_type::DataTypePtr)
    ptr = @lbugcall(:lbug_value_create_null_with_data_type, ValuePtr, (DataTypePtr,), data_type)
    LBUGValue(ptr)
end

function lbug_value_create_bool(val::Bool)
    ptr = @lbugcall(:lbug_value_create_bool, ValuePtr, (Bool,), val)
    LBUGValue(ptr)
end

function lbug_value_create_int8(val::Int8)
    ptr = @lbugcall(:lbug_value_create_int8, ValuePtr, (Int8,), val)
    LBUGValue(ptr)
end

function lbug_value_create_int16(val::Int16)
    ptr = @lbugcall(:lbug_value_create_int16, ValuePtr, (Int16,), val)
    LBUGValue(ptr)
end

function lbug_value_create_int32(val::Int32)
    ptr = @lbugcall(:lbug_value_create_int32, ValuePtr, (Int32,), val)
    LBUGValue(ptr)
end

function lbug_value_create_int64(val::Int64)
    ptr = @lbugcall(:lbug_value_create_int64, ValuePtr, (Int64,), val)
    LBUGValue(ptr)
end

function lbug_value_create_uint8(val::UInt8)
    ptr = @lbugcall(:lbug_value_create_uint8, ValuePtr, (UInt8,), val)
    LBUGValue(ptr)
end

function lbug_value_create_uint16(val::UInt16)
    ptr = @lbugcall(:lbug_value_create_uint16, ValuePtr, (UInt16,), val)
    LBUGValue(ptr)
end

function lbug_value_create_uint32(val::UInt32)
    ptr = @lbugcall(:lbug_value_create_uint32, ValuePtr, (UInt32,), val)
    LBUGValue(ptr)
end

function lbug_value_create_uint64(val::UInt64)
    ptr = @lbugcall(:lbug_value_create_uint64, ValuePtr, (UInt64,), val)
    LBUGValue(ptr)
end

function lbug_value_create_int128(val::LBUGInt128)
    ptr = @lbugcall(:lbug_value_create_int128, ValuePtr, (LBUGInt128,), val)
    LBUGValue(ptr)
end

function lbug_value_create_float(val::Float32)
    ptr = @lbugcall(:lbug_value_create_float, ValuePtr, (Float32,), val)
    LBUGValue(ptr)
end

function lbug_value_create_double(val::Float64)
    ptr = @lbugcall(:lbug_value_create_double, ValuePtr, (Float64,), val)
    LBUGValue(ptr)
end

function lbug_value_create_internal_id(val::InternalID)
    ptr = @lbugcall(:lbug_value_create_internal_id, ValuePtr, (InternalID,), val)
    LBUGValue(ptr)
end

function lbug_value_create_date(val::LBUGDate)
    ptr = @lbugcall(:lbug_value_create_date, ValuePtr, (LBUGDate,), val)
    LBUGValue(ptr)
end

function lbug_value_create_timestamp_ns(val::LBUGTimestampNS)
    ptr = @lbugcall(:lbug_value_create_timestamp_ns, ValuePtr, (LBUGTimestampNS,), val)
    LBUGValue(ptr)
end

function lbug_value_create_timestamp_ms(val::LBUGTimestampMS)
    ptr = @lbugcall(:lbug_value_create_timestamp_ms, ValuePtr, (LBUGTimestampMS,), val)
    LBUGValue(ptr)
end

function lbug_value_create_timestamp_sec(val::LBUGTimestampSec)
    ptr = @lbugcall(:lbug_value_create_timestamp_sec, ValuePtr, (LBUGTimestampSec,), val)
    LBUGValue(ptr)
end

function lbug_value_create_timestamp_tz(val::LBUGTimestampTZ)
    ptr = @lbugcall(:lbug_value_create_timestamp_tz, ValuePtr, (LBUGTimestampTZ,), val)
    LBUGValue(ptr)
end

function lbug_value_create_timestamp(val::LBUGTimestamp)
    ptr = @lbugcall(:lbug_value_create_timestamp, ValuePtr, (LBUGTimestamp,), val)
    LBUGValue(ptr)
end

function lbug_value_create_interval(val::LBUGInterval)
    ptr = @lbugcall(:lbug_value_create_interval, ValuePtr, (LBUGInterval,), val)
    LBUGValue(ptr)
end

function lbug_value_create_string(val::String)
    ptr = @lbugcall(:lbug_value_create_string, ValuePtr, (Cstring,), val)
    LBUGValue(ptr)
end

function lbug_value_clone(value::ValuePtr)
    ptr = @lbugcall(:lbug_value_clone, ValuePtr, (ValuePtr,), value)
    LBUGValue(ptr)
end

function lbug_value_copy(value::ValuePtr, other::ValuePtr)
    @lbugcall(:lbug_value_copy, Cvoid, (ValuePtr, ValuePtr), value, other)
end

function lbug_value_destroy(value::ValuePtr)
    @lbugcall(:lbug_value_destroy, Cvoid, (ValuePtr,), value)
end

# Value getter functions
function lbug_value_is_null(value::ValuePtr)
    @lbugcall(:lbug_value_is_null, Bool, (ValuePtr,), value)
end

function lbug_value_set_null(value::ValuePtr, is_null::Bool)
    @lbugcall(:lbug_value_set_null, Cvoid, (ValuePtr, Bool), value, is_null)
end

function lbug_value_get_data_type(value::ValuePtr, out_type::Ref{DataTypePtr})
    @lbugcall(:lbug_value_get_data_type, Cvoid, (ValuePtr, Ref{DataTypePtr}), value, out_type)
end

function lbug_value_get_bool(value::ValuePtr, out_result::Ref{Bool})
    @lbugcall(
        :lbug_value_get_bool,
        LBUGState,
        (ValuePtr, Ref{Bool}),
        value, out_result
    )
end

function lbug_value_get_int64(value::ValuePtr, out_result::Ref{Int64})
    @lbugcall(
        :lbug_value_get_int64,
        LBUGState,
        (ValuePtr, Ref{Int64}),
        value, out_result
    )
end

function lbug_value_get_int32(value::ValuePtr, out_result::Ref{Int32})
    @lbugcall(
        :lbug_value_get_int32,
        LBUGState,
        (ValuePtr, Ref{Int32}),
        value, out_result
    )
end

function lbug_value_get_int16(value::ValuePtr, out_result::Ref{Int16})
    @lbugcall(
        :lbug_value_get_int16,
        LBUGState,
        (ValuePtr, Ref{Int16}),
        value, out_result
    )
end

function lbug_value_get_int8(value::ValuePtr, out_result::Ref{Int8})
    @lbugcall(
        :lbug_value_get_int8,
        LBUGState,
        (ValuePtr, Ref{Int8}),
        value, out_result
    )
end

function lbug_value_get_uint64(value::ValuePtr, out_result::Ref{UInt64})
    @lbugcall(
        :lbug_value_get_uint64,
        LBUGState,
        (ValuePtr, Ref{UInt64}),
        value, out_result
    )
end

function lbug_value_get_uint32(value::ValuePtr, out_result::Ref{UInt32})
    @lbugcall(
        :lbug_value_get_uint32,
        LBUGState,
        (ValuePtr, Ref{UInt32}),
        value, out_result
    )
end

function lbug_value_get_uint16(value::ValuePtr, out_result::Ref{UInt16})
    @lbugcall(
        :lbug_value_get_uint16,
        LBUGState,
        (ValuePtr, Ref{UInt16}),
        value, out_result
    )
end

function lbug_value_get_uint8(value::ValuePtr, out_result::Ref{UInt8})
    @lbugcall(
        :lbug_value_get_uint8,
        LBUGState,
        (ValuePtr, Ref{UInt8}),
        value, out_result
    )
end

function lbug_value_get_int128(value::ValuePtr, out_result::Ref{LBUGInt128})
    @lbugcall(
        :lbug_value_get_int128,
        LBUGState,
        (ValuePtr, Ref{LBUGInt128}),
        value, out_result
    )
end

function lbug_value_get_float(value::ValuePtr, out_result::Ref{Float32})
    @lbugcall(
        :lbug_value_get_float,
        LBUGState,
        (ValuePtr, Ref{Float32}),
        value, out_result
    )
end

function lbug_value_get_double(value::ValuePtr, out_result::Ref{Float64})
    @lbugcall(
        :lbug_value_get_double,
        LBUGState,
        (ValuePtr, Ref{Float64}),
        value, out_result
    )
end

function lbug_value_get_internal_id(value::ValuePtr, out_result::Ref{InternalID})
    @lbugcall(
        :lbug_value_get_internal_id,
        LBUGState,
        (ValuePtr, Ref{InternalID}),
        value, out_result
    )
end

function lbug_value_get_date(value::ValuePtr, out_result::Ref{LBUGDate})
    @lbugcall(
        :lbug_value_get_date,
        LBUGState,
        (ValuePtr, Ref{LBUGDate}),
        value, out_result
    )
end

function lbug_value_get_timestamp(value::ValuePtr, out_result::Ref{LBUGTimestamp})
    @lbugcall(
        :lbug_value_get_timestamp,
        LBUGState,
        (ValuePtr, Ref{LBUGTimestamp}),
        value, out_result
    )
end

function lbug_value_get_timestamp_ns(value::ValuePtr, out_result::Ref{LBUGTimestampNS})
    @lbugcall(
        :lbug_value_get_timestamp_ns,
        LBUGState,
        (ValuePtr, Ref{LBUGTimestampNS}),
        value, out_result
    )
end

function lbug_value_get_timestamp_ms(value::ValuePtr, out_result::Ref{LBUGTimestampMS})
    @lbugcall(
        :lbug_value_get_timestamp_ms,
        LBUGState,
        (ValuePtr, Ref{LBUGTimestampMS}),
        value, out_result
    )
end

function lbug_value_get_timestamp_sec(value::ValuePtr, out_result::Ref{LBUGTimestampSec})
    @lbugcall(
        :lbug_value_get_timestamp_sec,
        LBUGState,
        (ValuePtr, Ref{LBUGTimestampSec}),
        value, out_result
    )
end

function lbug_value_get_timestamp_tz(value::ValuePtr, out_result::Ref{LBUGTimestampTZ})
    @lbugcall(
        :lbug_value_get_timestamp_tz,
        LBUGState,
        (ValuePtr, Ref{LBUGTimestampTZ}),
        value, out_result
    )
end

function lbug_value_get_interval(value::ValuePtr, out_result::Ref{LBUGInterval})
    @lbugcall(
        :lbug_value_get_interval,
        LBUGState,
        (ValuePtr, Ref{LBUGInterval}),
        value, out_result
    )
end

function lbug_value_get_string(value::ValuePtr, out_result::Ref{Ptr{Cchar}})
    @lbugcall(
        :lbug_value_get_string,
        LBUGState,
        (ValuePtr, Ref{Ptr{Cchar}}),
        value, out_result
    )
end

function lbug_value_get_blob(value::ValuePtr, out_result::Ref{Ptr{UInt8}})
    @lbugcall(
        :lbug_value_get_blob,
        LBUGState,
        (ValuePtr, Ref{Ptr{UInt8}}),
        value, out_result
    )
end

function lbug_value_to_string(value::ValuePtr)
    str_ptr = @lbugcall(:lbug_value_to_string, Ptr{Cchar}, (ValuePtr,), value)
    str_ptr == C_NULL ? "" : unsafe_string(str_ptr)
end

# Utility functions
function lbug_destroy_string(str::Ptr{Cchar})
    @lbugcall(:lbug_destroy_string, Cvoid, (Ptr{Cchar},), str)
end

function lbug_destroy_blob(blob::Ptr{UInt8})
    @lbugcall(:lbug_destroy_blob, Cvoid, (Ptr{UInt8},), blob)
end

# Query summary functions
function lbug_query_summary_destroy(query_summary::QuerySummaryPtr)
    @lbugcall(:lbug_query_summary_destroy, Cvoid, (QuerySummaryPtr,), query_summary)
end

function lbug_query_summary_get_compiling_time(query_summary::QuerySummaryPtr)
    @lbugcall(:lbug_query_summary_get_compiling_time, Cdouble, (QuerySummaryPtr,), query_summary)
end

function lbug_query_summary_get_execution_time(query_summary::QuerySummaryPtr)
    @lbugcall(:lbug_query_summary_get_execution_time, Cdouble, (QuerySummaryPtr,), query_summary)
end

# Version functions
function lbug_get_version()
    str_ptr = @lbugcall(:lbug_get_version, Ptr{Cchar}, ())
    str_ptr == C_NULL ? "" : unsafe_string(str_ptr)
end

function lbug_get_storage_version()
    @lbugcall(:lbug_get_storage_version, UInt64, ())
end
