# Type definitions for Ladybug C API bindings

# Enum for return state
@enum LBUGState::Cint begin
    LbugSuccess = 0
    LbugError = 1
end

# Data type IDs
@enum DataTypeID::Cint begin
    LBUG_ANY = 0
    LBUG_NODE = 10
    LBUG_REL = 11
    LBUG_RECURSIVE_REL = 12
    LBUG_SERIAL = 13
    LBUG_BOOL = 22
    LBUG_INT64 = 23
    LBUG_INT32 = 24
    LBUG_INT16 = 25
    LBUG_INT8 = 26
    LBUG_UINT64 = 27
    LBUG_UINT32 = 28
    LBUG_UINT16 = 29
    LBUG_UINT8 = 30
    LBUG_INT128 = 31
    LBUG_DOUBLE = 32
    LBUG_FLOAT = 33
    LBUG_DATE = 34
    LBUG_TIMESTAMP = 35
    LBUG_TIMESTAMP_SEC = 36
    LBUG_TIMESTAMP_MS = 37
    LBUG_TIMESTAMP_NS = 38
    LBUG_TIMESTAMP_TZ = 39
    LBUG_INTERVAL = 40
    LBUG_DECIMAL = 41
    LBUG_INTERNAL_ID = 42
    LBUG_STRING = 50
    LBUG_BLOB = 51
    LBUG_LIST = 52
    LBUG_ARRAY = 53
    LBUG_STRUCT = 54
    LBUG_MAP = 55
    LBUG_UNION = 56
    LBUG_POINTER = 58
    LBUG_UUID = 59
end

# Opaque pointer types
const DatabasePtr = Ptr{Cvoid}
const ConnectionPtr = Ptr{Cvoid}
const PreparedStatementPtr = Ptr{Cvoid}
const QueryResultPtr = Ptr{Cvoid}
const FlatTuplePtr = Ptr{Cvoid}
const DataTypePtr = Ptr{Cvoid}
const ValuePtr = Ptr{Cvoid}
const QuerySummaryPtr = Ptr{Cvoid}

# System configuration struct
struct SystemConfig
    buffer_pool_size::UInt64
    max_num_threads::UInt64
    enable_compression::Bool
    read_only::Bool
    max_db_size::UInt64
    
    function SystemConfig(;
        buffer_pool_size::UInt64 = 0,  # 0 means default
        max_num_threads::UInt64 = 0,   # 0 means all available
        enable_compression::Bool = true,
        read_only::Bool = false,
        max_db_size::UInt64 = 0,       # 0 means unlimited
    )
        new(buffer_pool_size, max_num_threads, enable_compression, read_only, max_db_size)
    end
end

# Internal ID type
struct InternalID
    table_id::UInt64
    offset::UInt64
end

# Date type - days since 1970-01-01
struct LBUGDate
    days::Int32
end

# Timestamp types
struct LBUGTimestamp
    micros::Int64
end

struct LBUGTimestampNS
    nanos::Int64
end

struct LBUGTimestampMS
    millis::Int64
end

struct LBUGTimestampSec
    seconds::Int64
end

struct LBUGTimestampTZ
    micros::Int64
end

# Interval type
struct LBUGInterval
    months::Int32
    days::Int32
    micros::Int64
end

# Int128 type
struct LBUGInt128
    low::UInt64
    high::Int64
end

# Wrapper types for Julia-friendly API
mutable struct Database
    ptr::DatabasePtr
    path::String
    
    function Database(ptr::DatabasePtr, path::String)
        db = new(ptr, path)
        finalizer(close_database, db)
        return db
    end
end

mutable struct Connection
    ptr::ConnectionPtr
    database::Database
    
    function Connection(ptr::ConnectionPtr, database::Database)
        conn = new(ptr, database)
        finalizer(disconnect, conn)
        return conn
    end
end

mutable struct PreparedStatement
    ptr::PreparedStatementPtr
    connection::Connection
    query::String
    
    function PreparedStatement(ptr::PreparedStatementPtr, connection::Connection, query::String)
        stmt = new(ptr, connection, query)
        finalizer(destroy_prepared_statement, stmt)
        return stmt
    end
end

mutable struct QueryResult
    ptr::QueryResultPtr
    connection::Connection
    query::String
    
    function QueryResult(ptr::QueryResultPtr, connection::Connection, query::String)
        result = new(ptr, connection, query)
        finalizer(destroy_query_result, result)
        return result
    end
end

mutable struct FlatTuple
    ptr::FlatTuplePtr
    
    function FlatTuple(ptr::FlatTuplePtr)
        tuple = new(ptr)
        finalizer(destroy_flat_tuple, tuple)
        return tuple
    end
end

mutable struct DataType
    ptr::DataTypePtr
    
    function DataType(ptr::DataTypePtr)
        dt = new(ptr)
        finalizer(destroy_data_type, dt)
        return dt
    end
end

mutable struct LBUGValue
    ptr::ValuePtr
    
    function LBUGValue(ptr::ValuePtr)
        val = new(ptr)
        finalizer(destroy_value, val)
        return val
    end
end

mutable struct QuerySummary
    ptr::QuerySummaryPtr
    
    function QuerySummary(ptr::QuerySummaryPtr)
        summary = new(ptr)
        finalizer(destroy_query_summary, summary)
        return summary
    end
end

# Arrow C Data Interface structures
struct ArrowSchema
    format::Ptr{Cchar}
    name::Ptr{Cchar}
    metadata::Ptr{Cchar}
    flags::Int64
    n_children::Int64
    children::Ptr{Ptr{ArrowSchema}}
    dictionary::Ptr{ArrowSchema}
    release::Ptr{Cvoid}
    private_data::Ptr{Cvoid}
end

struct ArrowArray
    length::Int64
    null_count::Int64
    offset::Int64
    n_buffers::Int64
    n_children::Int64
    buffers::Ptr{Ptr{Cvoid}}
    children::Ptr{Ptr{ArrowArray}}
    dictionary::Ptr{ArrowArray}
    release::Ptr{Cvoid}
    private_data::Ptr{Cvoid}
end

# Constants for Arrow flags
const ARROW_FLAG_DICTIONARY_ORDERED = 1
const ARROW_FLAG_NULLABLE = 2
const ARROW_FLAG_MAP_KEYS_SORTED = 4
