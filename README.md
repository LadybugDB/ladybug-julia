# Ladybug.jl

Julia bindings for [LadybugDB](https://github.com/LadybugDB/ladybug), a high-performance graph database.

## Installation

First, download the native Ladybug library binaries:

```bash
bash scripts/download-liblbug.sh
```

Then add the package to your Julia environment:

```julia
using Pkg
Pkg.add(path="path/to/ladybug-julia")
```

## Quick Start

```julia
using Ladybug

# Open a database
open_database("mygraph.db") do db
    # Create a connection
    connect(db) do conn
        # Create a node table
        query(conn, "CREATE NODE TABLE Person(name STRING, age INT64, PRIMARY KEY(name))")
        
        # Insert data
        query(conn, "CREATE (:Person {name: 'Alice', age: 30})")
        query(conn, "CREATE (:Person {name: 'Bob', age: 25})")
        
        # Query data
        result = query(conn, "MATCH (p:Person) RETURN p.name, p.age")
        
        # Iterate over results
        for tuple in result
            name = convert(String, tuple[0])
            age = convert(Int64, tuple[1])
            println("$name is $age years old")
        end
    end
end
```

## Features

- **Direct C API bindings**: Full access to the Ladybug C API through Julia's `ccall`
- **High-level API**: Idiomatic Julia wrappers with automatic memory management
- **Type safety**: Strongly typed value handling with automatic type conversion
- **Prepared statements**: Support for parameterized queries
- **Multiple data types**: Support for all Ladybug data types (integers, floats, strings, dates, timestamps, etc.)
- **Result conversion**: Convert query results to Julia matrices or DataFrame-like structures
- **Resource management**: Automatic cleanup with finalizers and do-block syntax

## Running tests

```
docker run -v .:/app --rm julia:bookworm julia --project=/app -e 'using Pkg; Pkg.instantiate(); include("/app/test/runtests.jl")'
```

## API Overview

### Database Operations

```julia
# Open a database
db = open_database("path/to/db")
close_database(db)

# Or use do-block syntax
open_database("path/to/db") do db
    # Use db here
end
```

### Connections

```julia
# Create a connection
conn = connect(db)
disconnect(conn)

# Or use do-block syntax
connect(db) do conn
    # Use conn here
end
```

### Queries

```julia
# Execute a query
result = query(conn, "MATCH (p:Person) RETURN p.name")

# Check if successful
is_success(result)  # true/false

# Get error message if failed
msg = get_error_message(result)

# Get metadata
n_rows = get_num_rows(result)
n_cols = get_num_columns(result)
columns = get_column_names(result)

# Iterate over results
for tuple in result
    # Process each tuple
end
```

### Prepared Statements

```julia
# Prepare a parameterized query
stmt = prepare(conn, "MATCH (p:Person) WHERE p.age > \$min_age RETURN p.name")

# Bind parameters
bind!(stmt, "min_age", 25)

# Execute
result = execute(conn, stmt)

# Reuse with different parameters
bind!(stmt, "min_age", 30)
result = execute(conn, stmt)
```

### Values

```julia
# Create values
val1 = create_string("Hello")
val2 = create_int64(42)
val3 = create_double(3.14)
val4 = create_bool(true)

# Check if null
is_null(val)

# Extract values
str = convert(String, val1)
int_val = convert(Int64, val2)
float_val = convert(Float64, val3)
bool_val = convert(Bool, val4)
```

### Configuration

```julia
# Create custom configuration
config = SystemConfig(
    buffer_pool_size = 1024 * 1024 * 1024,  # 1GB
    max_num_threads = 4,
    enable_compression = true,
    read_only = false,
    max_db_size = 0  # Unlimited
)

# Open database with configuration
db = open_database("path/to/db"; config=config)

# Set connection options
set_max_threads!(conn, 8)
set_timeout!(conn, 5000)  # 5 seconds timeout
```

## Supported Data Types

- **Primitive types**: `BOOL`, `INT8/16/32/64/128`, `UINT8/16/32/64`, `FLOAT`, `DOUBLE`
- **String types**: `STRING`, `BLOB`
- **Temporal types**: `DATE`, `TIMESTAMP`, `TIMESTAMP_NS`, `TIMESTAMP_MS`, `TIMESTAMP_SEC`, `TIMESTAMP_TZ`, `INTERVAL`
- **Graph types**: `NODE`, `REL`, `RECURSIVE_REL`, `INTERNAL_ID`
- **Complex types**: `LIST`, `ARRAY`, `STRUCT`, `MAP`, `UNION`, `DECIMAL`, `UUID`, `SERIAL`

## Examples

See the `examples/` directory for more comprehensive examples:

- `examples/basic_usage.jl` - Basic CRUD operations and queries

## Architecture

The package consists of three main layers:

1. **Low-level API** (`src/api.jl`): Direct FFI bindings to the C library functions
2. **Types** (`src/types.jl`): Julia struct definitions mirroring C structs and opaque pointer types
3. **High-level API** (`src/wrapper.jl`): User-friendly Julia wrappers with automatic memory management

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

This package is a Julia binding for the [LadybugDB](https://github.com/LadybugDB/ladybug) graph database developed by the LadybugDB team.
