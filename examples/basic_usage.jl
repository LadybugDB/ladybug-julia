# Example usage of Ladybug.jl

using Ladybug

# First, download the native binaries:
# bash scripts/download-liblbug.sh

# Check library version
println("Ladybug library version: ", get_version())
println("Storage version: ", get_storage_version())

# Example 1: Basic database operations
open_database("test.db") do db
    connect(db) do conn
        # Create a node
        result = query(conn, "CREATE NODE TABLE Person(name STRING, age INT64, PRIMARY KEY(name))")
        println("Created Person table: ", is_success(result))
        
        # Insert data
        result = query(conn, "CREATE (:Person {name: 'Alice', age: 30})")
        result = query(conn, "CREATE (:Person {name: 'Bob', age: 25})")
        
        # Query data
        result = query(conn, "MATCH (p:Person) RETURN p.name, p.age")
        println("Number of rows: ", get_num_rows(result))
        println("Number of columns: ", get_num_columns(result))
        println("Column names: ", get_column_names(result))
        
        # Iterate over results
        for tuple in result
            name = convert(String, tuple[0])
            age = convert(Int64, tuple[1])
            println("Person: $name, age: $age")
        end
        
        # Get query summary
        summary = get_query_summary(result)
        println("Compilation time: ", get_compiling_time(summary), " ms")
        println("Execution time: ", get_execution_time(summary), " ms")
    end
end

# Example 2: Using prepared statements
open_database("test.db") do db
    connect(db) do conn
        # Prepare a parameterized query
        stmt = prepare(conn, "MATCH (p:Person) WHERE p.age > \$age RETURN p.name")
        
        # Bind parameter and execute
        bind!(stmt, "age", 25)
        result = execute(conn, stmt)
        
        println("People older than 25:")
        for tuple in result
            name = convert(String, tuple[0])
            println("  - $name")
        end
        
        # Reuse with different parameter
        bind!(stmt, "age", 20)
        result = execute(conn, stmt)
        
        println("People older than 20:")
        for tuple in result
            name = convert(String, tuple[0])
            println("  - $name")
        end
    end
end

# Example 3: Using values
open_database("test.db") do db
    connect(db) do conn
        # Create values
        val1 = create_string("Hello, World!")
        val2 = create_int64(42)
        val3 = create_bool(true)
        
        println("String value: ", convert(String, val1))
        println("Int64 value: ", convert(Int64, val2))
        println("Bool value: ", convert(Bool, val3))
        
        # Check if null
        null_val = create_null()
        println("Is null: ", is_null(null_val))
    end
end

# Example 4: Configuration options
config = SystemConfig(
    buffer_pool_size = 1024 * 1024 * 1024,  # 1GB
    max_num_threads = 4,
    enable_compression = true,
    read_only = false,
    max_db_size = 0  # Unlimited
)

open_database("test.db"; config=config) do db
    connect(db) do conn
        # Set query timeout (in milliseconds)
        set_timeout!(conn, 5000)  # 5 seconds
        
        # Set max threads for execution
        set_max_threads!(conn, 2)
        println("Max threads: ", get_max_threads(conn))
        
        # Execute query
        result = query(conn, "MATCH (p:Person) RETURN p.name")
        println("Results:")
        for tuple in result
            println("  ", tuple)
        end
    end
end

# Example 5: Converting results to native Julia types
open_database("test.db") do db
    connect(db) do conn
        result = query(conn, "MATCH (p:Person) RETURN p.name, p.age")
        
        # Convert to matrix
        mat = to_matrix(result)
        println("Result matrix:")
        println(mat)
        
        # Convert to NamedTuple (DataFrame-like)
        reset_iterator(result)
        nt = to_dataframe(result)
        println("Result as NamedTuple:")
        println(nt)
    end
end

# Example 6: Working with different data types
open_database("test.db") do db
    connect(db) do conn
        # Create a table with various types
        query(conn, """
            CREATE NODE TABLE TestTypes(
                int_field INT64,
                float_field DOUBLE,
                string_field STRING,
                bool_field BOOL,
                PRIMARY KEY(int_field)
            )
        """)
        
        # Insert data
        query(conn, """
            CREATE (:TestTypes {
                int_field: 100,
                float_field: 3.14159,
                string_field: 'Test',
                bool_field: true
            })
        """)
        
        # Query with type conversion
        result = query(conn, "MATCH (t:TestTypes) RETURN t.*")
        
        for tuple in result
            int_val = convert(Int64, tuple[0])
            float_val = convert(Float64, tuple[1])
            string_val = convert(String, tuple[2])
            bool_val = convert(Bool, tuple[3])
            
            println("Int: $int_val, Float: $float_val, String: $string_val, Bool: $bool_val")
        end
    end
end

# Example 7: Error handling
open_database("test.db") do db
    connect(db) do conn
        try
            # This query has a syntax error
            result = query(conn, "MATCH (p:NonExistent) RETURN p")
            if !is_success(result)
                println("Query failed: ", get_error_message(result))
            end
        catch e
            println("Error caught: ", e)
        end
    end
end

println("\nAll examples completed!")
