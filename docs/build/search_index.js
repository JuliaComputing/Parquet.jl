var documenterSearchIndex = {"docs":
[{"location":"api.html","page":"API","title":"API","text":"CurrentModule = Parquet","category":"page"},{"location":"api.html#API","page":"API","title":"API","text":"","category":"section"},{"location":"api.html","page":"API","title":"API","text":"Pages = [\"api.md\"]","category":"page"},{"location":"api.html#Basic-Usage","page":"API","title":"Basic Usage","text":"","category":"section"},{"location":"api.html","page":"API","title":"API","text":"Parquet.File\nParquet.Table\nParquet.Dataset\nread_parquet\nwrite_parquet","category":"page"},{"location":"api.html#Parquet.File","page":"API","title":"Parquet.File","text":"Parquet.File(path; map_logical_types) => Parquet.File\n\nRepresents a Parquet file at path open for reading. Options to map logical types can be provided via map_logical_types.\n\nmap_logical_types can be one of:\n\nfalse: no mapping is done (default)\ntrue: default mappings are attempted on all columns (bytearray => String, int96 => DateTime)\nA user supplied dict mapping column names to a tuple of type and a converter function\n\nReturns a Parquet.File type that keeps a handle to the open file and the file metadata and also holds a LRU cache of raw bytes of the pages read.\n\n\n\n\n\n","category":"type"},{"location":"api.html#Parquet.Table","page":"API","title":"Parquet.Table","text":"Parquet.Table(path; kwargs...)\n\nReturns the table contained in the parquet file in a Tables.jl compatible format.\n\nOptions:\n\nrows: The row range to iterate through, all rows by default.\nbatchsize: Maximum number of rows to read in each batch (default: row count of first row group).\nuse_threads: Whether to use threads while reading the file; applicable only for Julia v1.3 and later and switched on by default if julia processes is started with multiple threads.\n\nOne can easily convert the returned object to any Tables.jl compatible table e.g. DataFrames.DataFrame via\n\nusing DataFrames\ndf = DataFrame(read_parquet(path))\n\n\n\n\n\n","category":"type"},{"location":"api.html#Parquet.Dataset","page":"API","title":"Parquet.Dataset","text":"Parquet.Dataset(path; kwargs...)\n\nReturns the table contained in the parquet dataset in an Tables.jl compatible format. A dataset comprises of multiple parquet files and optionally some metadata files.\n\nThese options if provided are passed along while reading each parquet file in the dataset:\n\nfilter: Filter function that takes the path to partitioned file and returns boolean to indicate whether to include the partition while loading. All partitions are loaded by default.\nbatchsize: Maximum number of rows to read in each batch (default: row count of first row group). Applied to each file in the partition.\nuse_threads: Whether to use threads while reading the file; applicable only for Julia v1.3 and later and switched on by default if julia processes is started with multiple threads.\ncolumn_generator: Function to generate a partitioned column when not found in the partitioned table. Parameters provided to the function: table, column index, length of column to generate. Default implementation determines column values from the table path.\n\nOne can easily convert the returned object to any Tables.jl compatible table e.g. DataFrames.DataFrame via\n\nusing DataFrames\ndf = DataFrame(read_parquet(path))\n\n\n\n\n\n","category":"type"},{"location":"api.html#Parquet.read_parquet","page":"API","title":"Parquet.read_parquet","text":"read_parquet(path; kwargs...)\n\nReturns the table contained in the parquet file or dataset (partitioned parquet files in a folder) in a Tables.jl compatible format.\n\nOptions:\n\nrows: The row range to iterate through, all rows by default. Applicable only when reading a single file.\nfilter: Filter function to apply while loading only a subset of partitions from a dataset.\nbatchsize: Maximum number of rows to read in each batch (default: row count of first row group). Applied only when reading a single file, and to each file when reading a dataset.\nuse_threads: Whether to use threads while reading the file; applicable only for Julia v1.3 and later and switched on by default if julia processes is started with multiple threads.\ncolumn_generator: Function to generate a partitioned column when not found in the partitioned table. Parameters provided to the function: table, column index, length of column to generate. Default implementation determines column values from the table path.\n\nOne can easily convert the returned object to any Tables.jl compatible table e.g. DataFrames.DataFrame via\n\nusing DataFrames\ndf = DataFrame(read_parquet(path))\n\n\n\n\n\n","category":"function"},{"location":"api.html#Parquet.write_parquet","page":"API","title":"Parquet.write_parquet","text":"write_parquet(io, tbl; compression_codec=\"SNAPPY\")\n\nWrite a parquet file from a Tables.jl compatible table e.g DataFrame Write table (Table.jl compatible object) as a parquet to io.  io can either be an IO stream object or a string, in which case it will be written to the file name given.\n\nAvailable compression codecs are: \"SNAPPY\", \"UNCOMPRESSED\", \"ZSTD\", \"GZIP\".\n\n\n\n\n\n","category":"function"},{"location":"api.html#Low-level-Usage","page":"API","title":"Low-level Usage","text":"","category":"section"},{"location":"api.html","page":"API","title":"API","text":"Page\nPageLRU\nTablePartition\nTablePartitions\nColCursor\nBatchedColumnsCursor\nDatasetPartitions\nSchema","category":"page"},{"location":"api.html#Parquet.Page","page":"API","title":"Parquet.Page","text":"Page\n\nData structure representing a parquet \"page\".\n\nColumn chunks are divided into pages which are conceptually individual units in terms of compression and encoding.  Multiple page types can be contained in a simble column chunk.\n\n\n\n\n\n","category":"type"},{"location":"api.html#Parquet.PageLRU","page":"API","title":"Parquet.PageLRU","text":"PageLRU\n\nKeeps a cache of pages read from a file.  Pages are kept as weak refs, so that they can be collected when there's memory pressure.\n\n\n\n\n\n","category":"type"},{"location":"api.html#Parquet.TablePartition","page":"API","title":"Parquet.TablePartition","text":"TablePartition\n\nRepresents one partition of the parquet file. Typically a row group, but could be any other unit as mentioned while opening the table.\n\n\n\n\n\n","category":"type"},{"location":"api.html#Parquet.TablePartitions","page":"API","title":"Parquet.TablePartitions","text":"TablePartitions\n\nIterator to iterate over partitions of a parquet file, returned by the Tables.partitions(table) method. Each partition is typically a row group, but could be any other unit as mentioned while opening the table.\n\n\n\n\n\n","category":"type"},{"location":"api.html#Parquet.ColCursor","page":"API","title":"Parquet.ColCursor","text":"ColCursor{T}\n\nColumn cursor iterates through all values of the column, including null values. Each iteration returns the value (as a Union{T,Nothing}), definition level, and repetition level for each value.  Row can be deduced from repetition level.\n\n\n\n\n\n","category":"type"},{"location":"api.html#Parquet.BatchedColumnsCursor","page":"API","title":"Parquet.BatchedColumnsCursor","text":"BatchedColumnsCursor\n\nCreate cursor to iterate over batches of column values. Each iteration returns a named tuple of column names with batch of column values. Files with nested schemas can not be read with this cursor.\n\nConstructors\n\nBatchedColumnsCursor(par::Parquet.File; kwargs...)\n\nArguments\n\nrows: the row range to iterate through, all rows by default.\nbatchsize: maximum number of rows to read in each batch (default: row count of first row group).\nreusebuffer: boolean to indicate whether to reuse the buffers with every iteration; if each iteration processes the batch and does not need to refer to the same data buffer again, then setting this to true reduces GC pressure and can help significantly while processing large files.\nuse_threads: whether to use threads while reading the file; applicable only for Julia v1.3 and later and switched on by default if julia processes is started with multiple threads.\n\n\n\n\n\n","category":"type"},{"location":"api.html#Parquet.DatasetPartitions","page":"API","title":"Parquet.DatasetPartitions","text":"DatasetPartitions\n\nIterator to iterate over partitions of a parquet dataset, returned by the Tables.partitions(dataset) method. Each partition is a Parquet.Table.\n\n\n\n\n\n","category":"type"},{"location":"api.html#Parquet.Schema","page":"API","title":"Parquet.Schema","text":"Schema\n\nParquet table schema.\n\n\n\n\n\n","category":"type"},{"location":"index.html","page":"Home","title":"Home","text":"CurrentModule = Parquet","category":"page"},{"location":"index.html","page":"Home","title":"Home","text":"note: Note\nDocs currently under construction!","category":"page"},{"location":"index.html#Parquet.jl","page":"Home","title":"Parquet.jl","text":"","category":"section"},{"location":"index.html","page":"Home","title":"Home","text":"Parquet is a tabular, columnar storage format which supports nested data with optional compression.","category":"page"},{"location":"index.html","page":"Home","title":"Home","text":"The parquet format specification can be found here.","category":"page"}]
}