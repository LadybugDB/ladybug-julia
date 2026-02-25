module Ladybug

using Libdl

# Include submodules
include("types.jl")
include("api.jl")
include("wrapper.jl")

# Export main types and functions
export LBUG_VERSION

# Types
export Database, Connection, QueryResult, PreparedStatement
export LBUGValue, DataType, DataTypeID, FlatTuple, QuerySummary

# High-level API
export open_database, close_database
export connect, disconnect
export query, prepare, execute
export get_column_names, get_num_rows, get_num_columns
export get_value, to_dataframe
export is_success, get_error_message

# Value creation functions
export create_null, create_value
export create_bool, create_int64, create_int32, create_int16, create_int8
export create_uint64, create_uint32, create_uint16, create_uint8
export create_float, create_double
export create_string, create_date, create_timestamp

# Version
export get_version, get_storage_version

const LBUG_VERSION = "0.14.1"

# Library handle - initialized in __init__
const LIBLBUG = Ref{Ptr{Cvoid}}(C_NULL)

# Find and load the shared library
function __init__()
    lib_dir = joinpath(dirname(@__DIR__), "lib")
    
    # Determine library name based on platform
    lib_name = if Sys.isapple()
        "liblbug.dylib"
    elseif Sys.islinux()
        "liblbug.so"
    elseif Sys.iswindows()
        "liblbug.dll"
    else
        error("Unsupported platform: $(Sys.KERNEL)")
    end
    
    lib_path = joinpath(lib_dir, lib_name)
    
    if !isfile(lib_path)
        @warn """
        Ladybug library not found at $lib_path
        
        Please run the download script:
        bash scripts/download-liblbug.sh
        """
        LIBLBUG[] = C_NULL
    else
        try
            LIBLBUG[] = Libdl.dlopen(lib_path)
            @info "Loaded Ladybug library from $lib_path"
        catch e
            @warn """
            Failed to load Ladybug library from $lib_path
            
            Error: $e
            
            Please ensure the library is compatible with your system.
            Run: bash scripts/download-liblbug.sh
            """
            LIBLBUG[] = C_NULL
        end
    end
end

end # module
