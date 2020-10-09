using Parquet
using Decimals
using Test

const decimal_encoding_testdata = [
    (
        precision=Int32(19),
        scale=Int32(0),
        datatype=Int128,
        byte_data=[
            UInt8[0,0,0,0,1],
            UInt8[0,0,0,1,1],
            UInt8[0,0,1,1,1],
            UInt8[0,1,1,1,1],
            UInt8[1,1,1,1,1],
        ],
        converted_data=Int128[1, 257, 65793, 16843009, 4311810305]
    ),
    (
        precision=Int32(10),
        scale=Int32(0),
        datatype=Int64,
        byte_data=[
            UInt8[0,0,0,0,1],
            UInt8[0,0,0,1,1],
            UInt8[0,0,1,1,1],
            UInt8[0,1,1,1,1],
            UInt8[1,1,1,1,1],
        ],
        converted_data=Int64[1, 257, 65793, 16843009, 4311810305]
    ),
    (
        precision=Int32(5),
        scale=Int32(0),
        datatype=Int32,
        byte_data=[
            UInt8[0,0,0,1],
            UInt8[0,0,1,1],
            UInt8[0,1,1,1],
        ],
        converted_data=Int32[1, 257, 65793]
    ),
    (
        precision=Int32(4),
        scale=Int32(0),
        datatype=Int16,
        byte_data=[
            UInt8[0,1],
            UInt8[1,1],
        ],
        converted_data=Int16[1, 257]
    ),
    (
        precision=Int32(4),
        scale=Int32(2),
        datatype=Decimal,
        byte_data=[
            UInt8[0,1],
            UInt8[1,1],
        ],
        converted_data=Decimal[Decimal(0, 1, -2), Decimal(0, 257, -2)]
    ),
    (
        precision=Int32(19),
        scale=Int32(5),
        datatype=Decimal,
        byte_data=[
            UInt8[0,0,0,0,1],
            UInt8[1,1,1,1,1],
        ],
        converted_data=Decimal[Decimal(0, 1, -5), Decimal(0, 4311810305, -5)]
    ),
    (
        precision=Int32(10),
        scale=Int32(-2),
        datatype=Decimal,
        byte_data=[
            UInt8[0,0,0,0,1],
            UInt8[0,0,0,1,1],
        ],
        converted_data=[Decimal(0, 1, 2), Decimal(0, 257, 2)]
    ),
]

function test_codec()
    println("testing reading bitpacked run (old scheme)...")
    let data = UInt8[0x05, 0x39, 0x77]
        byte_width = Parquet.@bit2bytewidth(UInt8(3))
        typ = Parquet.@byt2itype(byte_width)
        #arr = Array{typ}(undef, 8)
        inp = Parquet.InputState(data, 0)
        out = Parquet.OutputState(typ, 8)
        Parquet.read_bitpacked_run_old(inp, out, Int32(8), UInt8(3))
        @test out.data == Int32[0:7;]
    end
    println("passed.")

    println("testing reading bitpacked run...")
    let data = UInt8[0x88, 0xc6, 0xfa]
        byte_width = Parquet.@bit2bytewidth(UInt8(3))
        typ = Parquet.@byt2itype(byte_width)
        #arr = Array{typ}(undef, 8)
        inp = Parquet.InputState(data, 0)
        out = Parquet.OutputState(typ, 8)
        Parquet.read_bitpacked_run(inp, out, 8, UInt8(3), byte_width)
        @test out.data == Int32[0:7;]
    end
    println("passed.")

    println("testing decimal decoding...")    
    for data in decimal_encoding_testdata
        (d, f1) = Parquet.map_logical_decimal(Int32(data.precision), Int32(data.scale))
        f2 = (bytes)->Parquet.logical_decimal(bytes, data.precision, data.scale)
        f3 = (bytes)->Parquet.logical_decimal(bytes, data.precision, data.scale; use_float=true)
        @test d === data.datatype
        if isbitstype(d)
            @test all(map(f1, data.byte_data) .=== data.converted_data)
            @test all(map(f2, data.byte_data) .=== data.converted_data)
            @test all(map(f3, data.byte_data) .=== data.converted_data)
        else
            @test all(map(f1, data.byte_data) .== data.converted_data)
            @test all(map(f2, data.byte_data) .== data.converted_data)
            @test all(map(f3, data.byte_data) .== convert(Vector{Float64}, data.converted_data))
        end
    end

    println("passed.")
end

test_codec()
