##
# layer 3 access
# read data as records which are named tuple representations of the schema

##
# Row cursor iterates through row numbers of a column 
mutable struct RowCursor
    par::ParFile

    rows::UnitRange{Int64}                      # rows to scan over
    row::Int64                                  # current row
    
    rowgroups::Vector{RowGroup}                 # row groups in range
    rg::Union{Int,Nothing}                      # current row group
    rgrange::Union{UnitRange{Int64},Nothing}    # current rowrange

    function RowCursor(par::ParFile, rows::UnitRange{Int64}, col::Vector{String}, row::Int64=first(rows))
        rgs = rowgroups(par, col, rows)
        cursor = new(par, rows, row, rgs, nothing, nothing)
        setrow(cursor, row)
        cursor
    end
end

function setrow(cursor::RowCursor, row::Int64)
    cursor.row = row
    (cursor.rgrange !== nothing) && (cursor.row in cursor.rgrange) && return
    startrow = Int64(1)
    rowgroups = cursor.rowgroups
    for rowgroup_idx in 1:length(rowgroups)
        rowgroup_row_range = startrow:(startrow + rowgroups[rowgroup_idx].num_rows)
        if row in rowgroup_row_range
            cursor.row = row
            cursor.rg = rowgroup_idx
            cursor.rgrange = rowgroup_row_range
            return
        else
            startrow = last(rowgroup_row_range) + 1
        end
    end
    throw(BoundsError(par.path, row))
end

rowgroup_offset(cursor::RowCursor) = cursor.row - first(cursor.rgrange)

function _start(cursor::RowCursor)
    row = first(cursor.rows)
    setrow(cursor, row)
    row
end
_done(cursor::RowCursor, row::Int64) = (row > last(cursor.rows))
function _next(cursor::RowCursor, row::Int64)
    setrow(cursor, row)
    row, (row+1)
end

function Base.iterate(cursor::RowCursor, state)
    _done(cursor, state) && return nothing
    return _next(cursor, state)
end

function Base.iterate(cursor::RowCursor)
    r = iterate(x, _start(x))
    return r
end

##
# Column cursor iterates through all values of the column, including null values.
# Each iteration returns the value (as a Union{T,Nothing}), definition level, and repetition level for each value.
# Row can be deduced from repetition level.
mutable struct ColCursor{T}
    row::RowCursor
    colname::Vector{String}
    maxdefn::Int

    colchunks::Union{Vector{ColumnChunk},Nothing}
    cc::Union{Int,Nothing}
    ccrange::Union{UnitRange{Int64},Nothing}

    vals::Vector{T}
    valpos::Int64
    #valrange::UnitRange{Int}

    defn_levels::Vector{Int}
    repn_levels::Vector{Int}
    levelpos::Int64
    levelrange::UnitRange{Int}

    function ColCursor{T}(row::RowCursor, colname::Vector{String}) where T
        maxdefn = max_definition_level(schema(row.par), colname)
        new{T}(row, colname, maxdefn, nothing, nothing, nothing)
    end
end

function ColCursor(par::ParFile, rows::UnitRange{Int64}, colname::Vector{String}, row::Int64=first(rows))
    rowcursor = RowCursor(par, rows, colname, row)

    rowgroup = rowcursor.rowgroups[rowcursor.rg] 
    colchunks = columns(par, rowgroup, colname)
    parquet_coltype = coltype(colchunks[1])
    T = PLAIN_JTYPES[parquet_coltype+1]
    if (parquet_coltype == _Type.BYTE_ARRAY) || (parquet_coltype == _Type.FIXED_LEN_BYTE_ARRAY)
        T = Vector{T}
    end

    cursor = ColCursor{T}(rowcursor, colname)
    setrow(cursor, row)
    cursor
end

function setrow(cursor::ColCursor{T}, row::Int64) where {T}
    par = cursor.row.par
    rg = cursor.row.rowgroups[cursor.row.rg]
    ccincr = (row - cursor.row.row) == 1 # whether this is just an increment within the column chunk
    setrow(cursor.row, row) # set the row cursor
    cursor.colchunks!==nothing || (cursor.colchunks = columns(par, rg, cursor.colname))

    # check if cursor is done
    if _done(cursor.row, row)
        cursor.cc = length(cursor.colchunks) + 1
        cursor.ccrange = row:(row-1)
        cursor.vals = Vector{T}()
        cursor.repn_levels = cursor.defn_levels = Int[]
        cursor.valpos = cursor.levelpos = 0
        cursor.levelrange = 0:-1 #cursor.valrange = 0:-1
        return
    end

    # find the column chunk with the row
    if (cursor.ccrange === nothing) || !(row in cursor.ccrange)
        offset = rowgroup_offset(cursor.row) # the offset of row from beginning of current rowgroup
        colchunks = cursor.colchunks

        startrow = row - offset
        for cc in 1:length(colchunks)
            vals, defn_levels, repn_levels = values(par, colchunks[cc])
            if isempty(repn_levels)
                nrowscc = length(vals) # number of values is number of rows
            else
                nrowscc = length(repn_levels) - length(find(repn_levels))   # number of values where repetition level is 0
            end
            ccrange = startrow:(startrow + nrowscc)

            if row in ccrange
                cursor.cc = cc
                cursor.ccrange = ccrange
                cursor.vals = vals
                cursor.defn_levels = defn_levels
                cursor.repn_levels = repn_levels
                cursor.valpos = cursor.levelpos = 0
                ccincr = false
                break
            else
                startrow = last(ccrange) + 1
            end
        end
    end

    if cursor.ccrange === nothing
        # we did not find the row in this column
        cursor.valpos = cursor.levelpos = 0
        cursor.levelrange = 0:-1 #cursor.valrange = 0:-1
    else
        # find the starting positions for values and levels
        ccrange = cursor.ccrange
        defn_levels = cursor.defn_levels
        repn_levels = cursor.repn_levels
        levelpos = valpos = Int64(0)

        # compute the level and value pos for row
        if isempty(repn_levels)
            # no repetitions, so each entry corresponds to one full row
            levelpos = row - first(ccrange) + 1
            levelrange = levelpos:levelpos
        else
            # multiple entries may constitute one row
            idx = first(ccrange)
            levelpos = findfirst(repn_levels, 0) # NOTE: can start from cursor.levelpos to optimize, but that will prevent using setrow to go backwards
            while idx < row
                levelpos = findnext(repn_levels, 0, levelpos+1)
                idx += 1
            end
            levelend = max(findnext(repn_levels, 0, levelpos+1)-1, length(repn_levels))
            levelrange = levelpos:levelend
        end

        # compute the val pos for row
        if isempty(defn_levels)
            # all entries are required, so there must be a corresponding value
            valpos = levelpos
            #valrange = levelrange
        else
            maxdefn = cursor.maxdefn
            if ccincr
                valpos = cursor.valpos
            else
                valpos = sum(view(defn_levels, 1:(levelpos-1)) .== maxdefn) + 1
            end
            #nvals = sum(sub(defn_levels, levelrange) .== maxdefn)
            #valrange = valpos:(valpos+nvals-1)
        end

        cursor.levelpos = levelpos
        cursor.levelrange = levelrange
        cursor.valpos = valpos
        #cursor.valrange = valrange
    end
    nothing
end

function _start(cursor::ColCursor)
    row = _start(cursor.row)
    setrow(cursor, row)
    row, cursor.levelpos
end
function _done(cursor::ColCursor, rowandlevel::Tuple{Int64,Int64})
    row, levelpos = rowandlevel
    (levelpos > last(cursor.levelrange)) || _done(cursor.row, row)
end
function _next(cursor::ColCursor{T}, rowandlevel::Tuple{Int64,Int64}) where {T}
    # find values for current row and level in row
    row, levelpos = rowandlevel
    (levelpos == cursor.levelpos) || throw(InvalidStateException("Invalid column cursor state", :levelpos))

    maxdefn = cursor.maxdefn
    defn_level = isempty(cursor.defn_levels) ? maxdefn : cursor.defn_levels[levelpos]
    repn_level = isempty(cursor.repn_levels) ? 0 : cursor.repn_levels[levelpos]
    cursor.levelpos += 1
    if defn_level == maxdefn
        val = (cursor.vals[cursor.valpos])::T
        cursor.valpos += 1
    else
        val = nothing
    end

    # advance row
    if cursor.levelpos > last(cursor.levelrange)
        row += 1
        setrow(cursor, row)
    end

    NamedTuple{(:value, :defn_level, :repn_level),Tuple{Union{Nothing,T},Int64,Int64}}((val, defn_level, repn_level)), (row, cursor.levelpos)
end

function Base.iterate(cursor::ColCursor{T}, state) where {T}
    _done(cursor, state) && return nothing
    return _next(cursor, state)
end

function Base.iterate(cursor::ColCursor)
    r = iterate(x, _start(x))
    return r
end

##

mutable struct RecordCursor{T}
    par::ParFile
    colnames::Vector{Vector{String}}
    colcursors::Vector{ColCursor}
    colstates::Vector{Tuple{Int64,Int64}}
    rows::UnitRange{Int64}                      # rows to scan over
    row::Int64                                  # current row
end

function RecordCursor(par::ParFile; rows::UnitRange=1:nrows(par), colnames::Vector{Vector{String}}=colnames(par), row::Signed=first(rows))
    colcursors = [ColCursor(par, UnitRange{Int64}(rows), colname, Int64(row)) for colname in colnames]
    sch = schema(par)
    rectype = ntelemtype(sch, sch.schema[1])
    RecordCursor{rectype}(par, colnames, colcursors, Array{Tuple{Int64,Int64}}(undef, length(colcursors)), rows, row)
end

eltype(cursor::RecordCursor{T}) where {T} = T
length(cursor::RecordCursor) = length(cursor.rows)

state(cursor::RecordCursor) = cursor.row

function _start(cursor::RecordCursor)
    cursor.colstates = [_start(colcursor) for colcursor in cursor.colcursors]
    state(cursor)
end
_done(cursor::RecordCursor, row::Int64) = (row > last(cursor.rows))

function _next(cursor::RecordCursor{T}, _row::Int64) where {T}
    states = cursor.colstates
    cursors = cursor.colcursors

    row = Dict{Symbol,Any}()
    col_repeat_state = Dict{Tuple{Int,Int},Int}()
    for colid in 1:length(states)                                                               # for each column
        colcursor = cursors[colid]
        colstate = states[colid]
        states[colid] = update_record(cursor.par, row, colid, colcursor, colstate, col_repeat_state)
    end
    cursor.row += 1
    _nt(row, T), state(cursor)
end

function Base.iterate(cursor::RecordCursor{T}, state) where {T}
    _done(cursor, state) && return nothing
    return _next(cursor, state)
end

function Base.iterate(cursor::RecordCursor{T}) where {T}
    r = iterate(cursor, _start(cursor))
    return r
end

function _val_or_missing(dict::Dict{Symbol,Any}, k::Symbol, ::Type{T}) where {T}
    v = get(dict, k, missing)
    (isa(v, Dict{Symbol,Any}) ? _nt(v, T) : v)::T
end

@generated function _nt(dict::Dict{Symbol,Any}, ::Type{T}) where {T}
    names = fieldnames(T)
    strnames = ["$n" for n in names]
    quote
        return T(($([:(_val_or_missing(dict,Symbol($(strnames[i])),$(fieldtype(T,i)))) for i in 1:length(names)]...),))
    end
end

default_init(::Type{Vector{T}}) where {T} = Vector{T}()
default_init(::Type{Dict{Symbol,Any}}) = Dict{Symbol,Any}()
default_init(::Type{T}) where {T} = ccall(:jl_new_struct_uninit, Any, (Any,), T)::T

function update_record(par::ParFile, row::Dict{Symbol,Any}, colid::Int, colcursor::ColCursor{T}, colcursor_state::Tuple{Int64,Int64}, col_repeat_state::Dict{Tuple{Int,Int},Int}) where {T}
    if !_done(colcursor, colcursor_state)
        colval, colcursor_state = _next(colcursor, colcursor_state)                                                         # for each value, defn level, repn level in column
        update_record(par, row, colid, colcursor.colname, colval.value, colval.defn_level, colval.repn_level, col_repeat_state)    # update record
    end
    colcursor_state # return new colcursor state
end

function update_record(par::ParFile, row::Dict{Symbol,Any}, colid::Int, nameparts::Vector{String}, val, defn_level::Int64, repn_level::Int64, col_repeat_state::Dict{Tuple{Int,Int},Int})
    lparts = length(nameparts)
    sch = par.schema
    F = row  # the current field corresponding to the level in nameparts
    Fdefn = 0
    Frepn = 0

    # for each name part of colname (a field)
    for idx in 1:lparts
        colname = view(nameparts, 1:idx)
        #@debug("updating part $colname of $nameparts isnull:$(val === nothing), def:$(defn_level), rep:$(repn_level)")
        leaf = nameparts[idx]
        symleaf = Symbol(leaf)

        required = isrequired(sch, colname)         # determine whether field is optional and repeated
        repeated = isrepeated(sch, colname)
        required || (Fdefn += 1)                    # if field is optional, increment defn level
        repeated && (Frepn += 1)                    # if field can repeat, increment repn level

        defined = ((val === nothing) || (idx < lparts)) ? haskey(F, symleaf) : false
        mustdefine = defn_level >= Fdefn
        mustrepeat = repeated && (repn_level == Frepn)
        repkey = (colid, idx) #join(nameparts, '.') * ":" * string(idx) #join(colname, '.')
        repidx = get(col_repeat_state, repkey, 0)
        if mustrepeat
            repidx += 1
            col_repeat_state[repkey] = repidx
        end
        nreps = (defined && isa(F[symleaf], Vector)) ? length(F[symleaf]) : 0

        #@debug("repeat:$mustrepeat, nreps:$nreps, repidx:$repidx, defined:$defined, mustdefine:$mustdefine")
        if mustrepeat && (nreps < repidx)
            if !defined && mustdefine
                Vtyp = elemtype(sch, colname)
                Vrep = F[symleaf] = default_init(Vtyp)
            else
                Vrep = F[symleaf]
            end
            if length(Vrep) < repidx
                resize!(Vrep, repidx)
                if !isbits(eltype(Vrep))
                    Vrep[repidx] = default_init(eltype(Vrep))
                end
            end
            F = Vrep[repidx]
        elseif !defined && mustdefine
            if idx == length(nameparts)
                V = logical_convert(sch, nameparts, val)
            else
                Vtyp = elemtype(sch, colname)
                V = default_init(Vtyp)
            end
            F[symleaf] = V
            F = V
        else
            F = get(F, symleaf, nothing)
        end
    end
    nothing
end
