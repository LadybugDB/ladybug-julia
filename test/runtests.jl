using Test
using Ladybug

@testset "Ladybug.jl" begin
    @testset "Module loading" begin
        @test isdefined(Main, :Ladybug)
        @test Ladybug.LBUG_VERSION == "0.14.1"
    end
    
    @testset "Library loading" begin
        # The library handle should be defined
        @test isdefined(Ladybug, :LIBLBUG)
        # It should be a Ref to C_NULL when library isn't loaded
        @test Ladybug.LIBLBUG isa Base.RefValue{Ptr{Cvoid}}
    end
    
    @testset "Type definitions" begin
        @test isdefined(Ladybug, :Database)
        @test isdefined(Ladybug, :Connection)
        @test isdefined(Ladybug, :QueryResult)
        @test isdefined(Ladybug, :PreparedStatement)
        @test isdefined(Ladybug, :LBUGValue)
        @test isdefined(Ladybug, :DataTypeID)
    end
    
    @testset "DataTypeID enum values" begin
        # Enum values are prefixed with LBUG_
        @test isdefined(Ladybug, :LBUG_BOOL)
        @test isdefined(Ladybug, :LBUG_INT64)
        @test isdefined(Ladybug, :LBUG_STRING)
        @test isdefined(Ladybug, :LBUG_NODE)
        @test isdefined(Ladybug, :LBUG_REL)
    end
    
    @testset "API function exports" begin
        @test isdefined(Ladybug, :open_database)
        @test isdefined(Ladybug, :close_database)
        @test isdefined(Ladybug, :connect)
        @test isdefined(Ladybug, :disconnect)
        @test isdefined(Ladybug, :query)
        @test isdefined(Ladybug, :prepare)
        @test isdefined(Ladybug, :execute)
    end
end
