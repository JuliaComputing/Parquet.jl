const PAR_MAGIC = "PAR1"
const SZ_PAR_MAGIC = length(PAR_MAGIC)
const SZ_FOOTER = 4
const SZ_VALID_PAR = 2*SZ_PAR_MAGIC + SZ_FOOTER

# page is the unit of compression
mutable struct Page
    colchunk::ColumnChunk
    hdr::PageHeader
    pos::Int
    data::Vector{UInt8}
end

mutable struct PageLRU
    refs::Dict{ColumnChunk,DRef}
    function PageLRU()
        new(Dict{ColumnChunk,DRef}())
    end
end

function cacheget(lru::PageLRU, chunk::ColumnChunk, nf)
    if chunk in keys(lru.refs)
        poolget(lru.refs[chunk])
    else
        data = nf(chunk)
        lru.refs[chunk] = poolset(data)
        data
    end
end

"""
    ParFile(path; map_logical_types) => ParFile

Represents a Parquet file at `path` open for reading. Options to map logical types can be provided via `map_logical_types`.

`map_logical_types` can be one of:

- `false`: no mapping is done (default)
- `true`: default mappings are attempted on all columns (bytearray => String, int96 => DateTime)
- A user supplied dict mapping column names to a tuple of type and a converter function

Returns a `ParFile` type that keeps a handle to the open file and the file metadata and also holds a LRU cache of raw bytes of the pages read.
"""
mutable struct ParFile
    path::String
    handle::IOStream
    meta::FileMetaData
    schema::Schema
    page_cache::PageLRU
end

function ParFile(path::AbstractString; map_logical_types::Union{Bool,Dict}=false)
    f = open(path)
    try
        return ParFile(path, f; map_logical_types=map_logical_types)
    catch ex
        close(f)
        rethrow(ex)
    end
end

function ParFile(path::AbstractString, handle::IOStream; map_logical_types::Union{Bool,Dict}=false)
    is_par_file(handle) || error("Not a parquet format file: $path")
    meta_len = metadata_length(handle)
    meta = metadata(handle, path, meta_len)

    typemap = map_logical_types == false ? TLogicalTypeMap() :
              map_logical_types == true  ? DEFAULT_LOGICAL_TYPE_MAP :
              TLogicalTypeMap(map_logical_types)

    ParFile(String(path), handle, meta, Schema(meta.schema, typemap), PageLRU())
end

function close(par::ParFile)
    empty!(par.page_cache.refs)
    close(par.handle)
end

##
# layer 1 access
# can access raw (uncompressed) bytes from pages

schema(par::ParFile) = par.schema

colname(col::ColumnChunk) = colname(col.meta_data)
colname(col::ColumnMetaData) = col.path_in_schema
colnames(rowgroup::RowGroup) = [colname(col) for col in rowgroup.columns]
function colnames(par::ParFile)
    names = Vector{Vector{String}}()
    cs = Int[]
    ns = String[]
    for x in par.schema.schema[2:end]
        if Parquet.num_children(x) > 0
            push!(cs, x.num_children)
            push!(ns, x.name)
        else
            if !isempty(cs)
                push!(names, [ns; x.name])
                cs[end] -= 1
                if cs[end] == 0
                    pop!(cs)
                    pop!(ns)
                end
            else
                push!(names, [x.name])
            end
        end
    end
    names
end

ncols(par::ParFile) = length(colnames(par))
nrows(par::ParFile) = par.meta.num_rows

coltype(col::ColumnChunk) = coltype(col.meta_data)
coltype(col::ColumnMetaData) = col._type

# return all rowgroups in the par file
rowgroups(par::ParFile) = par.meta.row_groups

# Return rowgroups that stores all the columns mentioned in `cnames`.
# Returned row groups can be further queried to get the range of rows.
rowgroups(par::ParFile, colname::Vector{String}, rowrange::UnitRange=1:typemax(Int64)) = rowgroups(par, [colname], rowrange)
function rowgroups(par::ParFile, cnames::Vector{Vector{String}}, rowrange::UnitRange=1:typemax(Int64))
    R = RowGroup[]
    L = length(cnames)
    beginrow = 1
    for rowgrp in rowgroups(par)
        cnamesrg = colnames(rowgrp)
        found = length(intersect(cnames, cnamesrg))
        endrow = beginrow + rowgrp.num_rows - 1
        (found == L) && (length(beginrow:endrow) > 0) && push!(R, rowgrp)
        beginrow = endrow + 1
    end
    R
end

columns(par::ParFile, rowgroupidx) = columns(par, rowgroups(par)[rowgroupidx])
columns(par::ParFile, rowgroup::RowGroup) = rowgroup.columns
columns(par::ParFile, rowgroup::RowGroup, colname::Vector{String}) = columns(par, rowgroup, [colname])
function columns(par::ParFile, rowgroup::RowGroup, cnames::Vector{Vector{String}})
    R = ColumnChunk[]
    for col in columns(par, rowgroup)
        (colname(col) in cnames) && push!(R, col)
    end
    R
end

function _pagevec(par::ParFile, col::ColumnChunk)
    # read pages from the file
    pos = page_offset(col)
    endpos = end_offset(col)
    io = par.handle
    pagevec = Page[]
    while pos < endpos
        seek(io, pos)
        pagehdr = read_thrift(io, PageHeader)

        buff = Array{UInt8}(undef, page_size(pagehdr))
        page_data_pos = position(io)
        data = read!(io, buff)
        page = Page(col, pagehdr, page_data_pos, data)
        push!(pagevec, page)
        pos = position(io)
    end
    pagevec
end
pages(par::ParFile, rowgroupidx, colidx) = pages(par, columns(par, rowgroupidx), colidx)
pages(par::ParFile, cols::Vector{ColumnChunk}, colidx) = pages(par, cols[colidx])
pages(par::ParFile, col::ColumnChunk) = cacheget(par.page_cache, col, col->_pagevec(par,col))

function bytes(page::Page, uncompressed::Bool=true)
    data = page.data
    codec = page.colchunk.meta_data.codec
    if uncompressed && (codec != CompressionCodec.UNCOMPRESSED)
        uncompressed_sz = page.hdr.uncompressed_page_size
        if codec == CompressionCodec.SNAPPY
            data = Snappy.uncompress(data)
        elseif codec == CompressionCodec.GZIP
            data = transcode(GzipDecompressor, data)
        elseif codec == CompressionCodec.ZSTD
            data = transcode(ZstdDecompressor, data)
        else
            error("Unknown compression codec for column chunk: $codec")
        end
        (length(data) == uncompressed_sz) || error("failed to uncompress page. expected $(uncompressed_sz), got $(length(data)) bytes")
    end
    data
end

##
# layer 2 access
# can access decoded values from pages

map_dict_vals(valdict::Vector{T1}, vals::Vector{T2}) where {T1, T2} = isempty(valdict) ? vals : [valdict[v+1] for v in vals]

values(par::ParFile, rowgroupidx, colidx) = values(par, columns(par, rowgroupidx), colidx)
values(par::ParFile, cols::Vector{ColumnChunk}, colidx) = values(par, cols[colidx])
function values(par::ParFile, col::ColumnChunk)
    ctype = coltype(col)
    pgs = pages(par, col)
    valdict = Int[]
    jtype = PLAIN_JTYPES[ctype+1]
    if (ctype == _Type.BYTE_ARRAY) || (ctype == _Type.FIXED_LEN_BYTE_ARRAY)
        jtype = Vector{jtype}
    end
    vals = Array{jtype}(undef, 0)
    defn_levels = Int[]
    repn_levels = Int[]

    for pg in pgs
        typ = pg.hdr._type
        valtup = values(par, pg)
        if (typ == PageType.DATA_PAGE) || (typ == PageType.DATA_PAGE_V2)
            @debug("reading a data page for columnchunk")
            _vals, _defn_levels, _repn_levels = valtup
            enc, defn_enc, rep_enc = page_encodings(pg)
            if enc == Encoding.PLAIN_DICTIONARY || enc == Encoding.RLE_DICTIONARY
                append!(vals, map_dict_vals(valdict, _vals))
                #=
                if isempty(valdict)
                    append!(vals, _vals)
                else
                    mapped_vals = [valdict[v+1] for v in _vals]
                    append!(vals, mapped_vals)
                end
                =#
            else
                append!(vals, _vals)
            end
            append!(defn_levels, _defn_levels)
            append!(repn_levels, _repn_levels)
        elseif typ == PageType.DICTIONARY_PAGE
            _vals = valtup[1]
            @debug("read a dictionary page for columnchunk with $(length(_vals)) values")
            valdict = isempty(valdict) ? _vals : append!(valdict, _vals)
        end
    end
    vals, defn_levels, repn_levels
end

function read_levels(io::IO, max_val::Int, enc::Int32, num_values::Int32)
    bw = UInt8(bitwidth(max_val))
    (bw == 0) && (return Int[])
    @debug("reading levels. enc:$enc ($(Thrift.enumstr(Encoding,enc))), max_val:$max_val, num_values:$num_values")

    if enc == Encoding.RLE
        read_hybrid(io, num_values, bw)
    elseif enc == Encoding.BIT_PACKED
        read_bitpacked_run_old(io, num_values, bw)
    elseif enc == Encoding.PLAIN
        # levels should never be of this type though
        read_plain_values(io, _Type.INT32, num_values)
    else
        error("unsupported encoding $enc ($(Thrift.enumstr(Encoding,enc))) for levels")
    end
end

function read_values(io::IO, enc::Int32, typ::Int32, num_values::Int32)
    @debug("reading values. enc:$enc ($(Thrift.enumstr(Encoding,enc))), num_values:$num_values")

    if enc == Encoding.PLAIN
        read_plain_values(io, num_values, typ)
    elseif enc == Encoding.PLAIN_DICTIONARY || enc == Encoding.RLE_DICTIONARY
        read_rle_dict(io, num_values)
    else
        error("unsupported encoding $enc for pages")
        #@debug("unsupported encoding $enc ($(Thrift.enumstr(Encoding,enc))) for pages")
        #return Int[]
    end
end

function values(par::ParFile, page::Page)
    ctype = coltype(page.colchunk)
    rawbytes = bytes(page)
    io = IOBuffer(rawbytes)
    encs = page_encodings(page)
    num_values = page_num_values(page)
    typ = page.hdr._type

    if (typ == PageType.DATA_PAGE) || (typ == PageType.DATA_PAGE_V2)
        read_levels_and_values(io, encs, ctype, num_values, par, page)
    elseif typ == PageType.DICTIONARY_PAGE
        (read_plain_values(io, num_values, ctype),)
    else
        ()
    end
end

function read_levels_and_values(io::IO, encs::Tuple, ctype::Int32, num_values::Int32, par::ParFile, page::Page)
    cname = colname(page.colchunk)
    enc, defn_enc, rep_enc = encs

    #@debug("before reading defn levels bytesavailable in page: $(bytesavailable(io))")
    # read definition levels. skipped if column is required
    defn_levels = isrequired(par.schema, cname) ? Int[] : read_levels(io, max_definition_level(par.schema, cname), defn_enc, num_values)

    #@debug("before reading repn levels bytesavailable in page: $(bytesavailable(io))")
    # read repetition levels. skipped if all columns are at 1st level
    repn_levels = ('.' in cname) ? read_levels(io, max_repetition_level(par.schema, cname), rep_enc, num_values) : Int[]

    #@debug("before reading values bytesavailable in page: $(bytesavailable(io))")
    # read values
    # if there are missing values in the data then
    # where defn_levels's elements == 1 are present and only
    # sum(defn_levels) values can be read.
    # because defn_levels == 0 are where the missing vlaues are
    nmissing = Int32(sum(==(0), defn_levels))
    vals = read_values(io, enc, ctype, num_values - nmissing)

    vals, defn_levels, repn_levels
end


# column and page metadata
open(par::ParFile, col::ColumnChunk) = open(par.handle, par.path, col)
close(par::ParFile, col::ColumnChunk, io) = (par.handle == io) || close(io)
function open(io, path::AbstractString, col::ColumnChunk)
    if isfilled(col, :file_path)
        @debug("opening file $(col.file_path) to read column metadata at $(col.file_offset)")
        open(col.file_path)
    else
        if io == nothing
            @debug("opening file $path to read column metadata at $(col.file_offset)")
            open(path)
        else
            @debug("reading column metadata at $(col.file_offset)")
            io
        end
    end
end

function metadata(io, path::AbstractString, col::ColumnChunk)
    fio = open(io, path, col)
    seek(fio, col.file_offset)
    meta = read_thrift(fio, ColumnMetaData)
    (fio !== io) && close(fio)
    meta
end

function page_offset(col::ColumnChunk)
    colmeta = col.meta_data
    offset = colmeta.data_page_offset
    Thrift.isfilled(colmeta, :index_page_offset) && (offset = min(offset, colmeta.index_page_offset))
    Thrift.isfilled(colmeta, :dictionary_page_offset) && (offset = min(offset, colmeta.dictionary_page_offset))
    offset
end
end_offset(col::ColumnChunk) = page_offset(col) + col.meta_data.total_compressed_size

page_size(page::PageHeader) = Thrift.isfilled(page, :compressed_page_size) ? page.compressed_page_size : page.uncompressed_page_size

page_encodings(page::Page) = page_encodings(page.hdr)
function page_encodings(page::PageHeader)
    Thrift.isfilled(page, :data_page_header) ? page_encodings(page.data_page_header) :
    Thrift.isfilled(page, :data_page_header_v2) ? page_encodings(page.data_page_header_v2) :
    Thrift.isfilled(page, :dictionary_page_header) ? page_encodings(page.dictionary_page_header) : ()
end
page_encodings(page::DictionaryPageHeader) = (page.encoding,)
page_encodings(page::DataPageHeader) = (page.encoding, page.definition_level_encoding, page.repetition_level_encoding)
page_encodings(page::DataPageHeaderV2) = (page.encoding, Encoding.RLE, Encoding.RLE)

page_num_values(page::Page) = page_num_values(page.hdr)
function page_num_values(page::PageHeader)
    Thrift.isfilled(page, :data_page_header) ? page_num_values(page.data_page_header) :
    Thrift.isfilled(page, :data_page_header_v2) ? page_num_values(page.data_page_header_v2) :
    Thrift.isfilled(page, :dictionary_page_header) ? page_num_values(page.dictionary_page_header) : 0
end
page_num_values(page::Union{DataPageHeader,DataPageHeaderV2,DictionaryPageHeader}) = page.num_values

# file metadata
read_thrift(buff::Array{UInt8}, ::Type{T}) where {T} = read(TCompactProtocol(TMemoryTransport(buff)), T)
read_thrift(io::IO, ::Type{T}) where {T} = read(TCompactProtocol(TFileTransport(io)), T)
read_thrift(t::TR, ::Type{T}) where {TR<:TTransport,T} = read(TCompactProtocol(t), T)

function metadata_length(io)
    sz = filesize(io)
    seek(io, sz - SZ_PAR_MAGIC - SZ_FOOTER)

    # read footer size as little endian signed Int32
    read_fixed(io, Int32)
end

function metadata(io, path::AbstractString, len::Integer=metadata_length(io))
    @debug("metadata len = $len")
    sz = filesize(io)
    seek(io, sz - SZ_PAR_MAGIC - SZ_FOOTER - len)
    meta = read_thrift(io, FileMetaData)
    # go through all column chunks and read metadata from file offsets if required
    for grp in meta.row_groups
        for col in grp.columns
            if !isfilled(col, :meta_data)
                # need to read metadata from an offset
                col.meta_data = metadata(io, path, col)
            end
        end
    end
    meta
end

metadata(par::ParFile) = par.meta

# file format verification
function is_par_file(fname::AbstractString)
    open(fname) do io
        return is_par_file(io)
    end
end

function is_par_file(io)
    sz = filesize(io)
    (sz > SZ_VALID_PAR) || return false

    seekstart(io)
    magic = Array{UInt8}(undef, 4)
    read!(io, magic)
    (String(magic) == PAR_MAGIC) || return false

    seek(io, sz - SZ_PAR_MAGIC)
    magic = Array{UInt8}(undef, 4)
    read!(io, magic)
    (String(magic) == PAR_MAGIC) || return false

    true
end
