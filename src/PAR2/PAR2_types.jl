#
# Autogenerated by Thrift Compiler (0.11.0)
#
# DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING

struct _enum__Type
  BOOLEAN::Int32
  INT32::Int32
  INT64::Int32
  INT96::Int32
  FLOAT::Int32
  DOUBLE::Int32
  BYTE_ARRAY::Int32
  FIXED_LEN_BYTE_ARRAY::Int32
end
const _Type = _enum__Type(Int32(0), Int32(1), Int32(2), Int32(3), Int32(4), Int32(5), Int32(6), Int32(7))

struct _enum_ConvertedType
  UTF8::Int32
  MAP::Int32
  MAP_KEY_VALUE::Int32
  LIST::Int32
  ENUM::Int32
  DECIMAL::Int32
  DATE::Int32
  TIME_MILLIS::Int32
  TIME_MICROS::Int32
  TIMESTAMP_MILLIS::Int32
  TIMESTAMP_MICROS::Int32
  UINT_8::Int32
  UINT_16::Int32
  UINT_32::Int32
  UINT_64::Int32
  INT_8::Int32
  INT_16::Int32
  INT_32::Int32
  INT_64::Int32
  JSON::Int32
  BSON::Int32
  INTERVAL::Int32
end
const ConvertedType = _enum_ConvertedType(Int32(0), Int32(1), Int32(2), Int32(3), Int32(4), Int32(5), Int32(6), Int32(7), Int32(8), Int32(9), Int32(10), Int32(11), Int32(12), Int32(13), Int32(14), Int32(15), Int32(16), Int32(17), Int32(18), Int32(19), Int32(20), Int32(21))

struct _enum_FieldRepetitionType
  REQUIRED::Int32
  OPTIONAL::Int32
  REPEATED::Int32
end
const FieldRepetitionType = _enum_FieldRepetitionType(Int32(0), Int32(1), Int32(2))

struct _enum_Encoding
  PLAIN::Int32
  PLAIN_DICTIONARY::Int32
  RLE::Int32
  BIT_PACKED::Int32
  DELTA_BINARY_PACKED::Int32
  DELTA_LENGTH_BYTE_ARRAY::Int32
  DELTA_BYTE_ARRAY::Int32
  RLE_DICTIONARY::Int32
end
const Encoding = _enum_Encoding(Int32(0), Int32(2), Int32(3), Int32(4), Int32(5), Int32(6), Int32(7), Int32(8))

struct _enum_CompressionCodec
  UNCOMPRESSED::Int32
  SNAPPY::Int32
  GZIP::Int32
  LZO::Int32
  BROTLI::Int32
  LZ4::Int32
  ZSTD::Int32
end
const CompressionCodec = _enum_CompressionCodec(Int32(0), Int32(1), Int32(2), Int32(3), Int32(4), Int32(5), Int32(6))

struct _enum_PageType
  DATA_PAGE::Int32
  INDEX_PAGE::Int32
  DICTIONARY_PAGE::Int32
  DATA_PAGE_V2::Int32
end
const PageType = _enum_PageType(Int32(0), Int32(1), Int32(2), Int32(3))

struct _enum_BoundaryOrder
  UNORDERED::Int32
  ASCENDING::Int32
  DESCENDING::Int32
end
const BoundaryOrder = _enum_BoundaryOrder(Int32(0), Int32(1), Int32(2))


mutable struct Statistics <: Thrift.TMsg
  max::Vector{UInt8}
  min::Vector{UInt8}
  null_count::Int64
  distinct_count::Int64
  max_value::Vector{UInt8}
  min_value::Vector{UInt8}
  Statistics() = (o=new(); fillunset(o); o)
end # mutable struct Statistics
meta(t::Type{Statistics}) = meta(t, Symbol[:max,:min,:null_count,:distinct_count,:max_value,:min_value], Int[], Dict{Symbol,Any}())

mutable struct StringType <: Thrift.TMsg
end # mutable struct StringType

mutable struct UUIDType <: Thrift.TMsg
end # mutable struct UUIDType

mutable struct MapType <: Thrift.TMsg
end # mutable struct MapType

mutable struct ListType <: Thrift.TMsg
end # mutable struct ListType

mutable struct EnumType <: Thrift.TMsg
end # mutable struct EnumType

mutable struct DateType <: Thrift.TMsg
end # mutable struct DateType

mutable struct NullType <: Thrift.TMsg
end # mutable struct NullType

mutable struct DecimalType <: Thrift.TMsg
  scale::Int32
  precision::Int32
  DecimalType() = (o=new(); fillunset(o); o)
end # mutable struct DecimalType

mutable struct MilliSeconds <: Thrift.TMsg
end # mutable struct MilliSeconds

mutable struct MicroSeconds <: Thrift.TMsg
end # mutable struct MicroSeconds

mutable struct TimeUnit <: Thrift.TMsg
  MILLIS::MilliSeconds
  MICROS::MicroSeconds
  TimeUnit() = (o=new(); fillunset(o); o)
end # mutable struct TimeUnit
meta(t::Type{TimeUnit}) = meta(t, Symbol[:MILLIS,:MICROS], Int[], Dict{Symbol,Any}())

mutable struct TimestampType <: Thrift.TMsg
  isAdjustedToUTC::Bool
  unit::TimeUnit
  TimestampType() = (o=new(); fillunset(o); o)
end # mutable struct TimestampType

mutable struct TimeType <: Thrift.TMsg
  isAdjustedToUTC::Bool
  unit::TimeUnit
  TimeType() = (o=new(); fillunset(o); o)
end # mutable struct TimeType

mutable struct IntType <: Thrift.TMsg
  bitWidth::UInt8
  isSigned::Bool
  IntType() = (o=new(); fillunset(o); o)
end # mutable struct IntType

mutable struct JsonType <: Thrift.TMsg
end # mutable struct JsonType

mutable struct BsonType <: Thrift.TMsg
end # mutable struct BsonType

mutable struct LogicalType <: Thrift.TMsg
  STRING::StringType
  MAP::MapType
  LIST::ListType
  ENUM::EnumType
  DECIMAL::DecimalType
  DATE::DateType
  TIME::TimeType
  TIMESTAMP::TimestampType
  INTEGER::IntType
  UNKNOWN::NullType
  JSON::JsonType
  BSON::BsonType
  LogicalType() = (o=new(); fillunset(o); o)
end # mutable struct LogicalType
meta(t::Type{LogicalType}) = meta(t, Symbol[:STRING,:MAP,:LIST,:ENUM,:DECIMAL,:DATE,:TIME,:TIMESTAMP,:INTEGER,:UNKNOWN,:JSON,:BSON], Int[1,2,3,4,5,6,7,8,10,11,12,13], Dict{Symbol,Any}())

mutable struct SchemaElement <: Thrift.TMsg
  _type::Int32
  type_length::Int32
  repetition_type::Int32
  name::String
  num_children::Int32
  converted_type::Int32
  scale::Int32
  precision::Int32
  field_id::Int32
  logicalType::LogicalType
  SchemaElement() = (o=new(); fillunset(o); o)
end # mutable struct SchemaElement
meta(t::Type{SchemaElement}) = meta(t, Symbol[:_type,:type_length,:repetition_type,:num_children,:converted_type,:scale,:precision,:field_id,:logicalType], Int[], Dict{Symbol,Any}())

mutable struct DataPageHeader <: Thrift.TMsg
  num_values::Int32
  encoding::Int32
  definition_level_encoding::Int32
  repetition_level_encoding::Int32
  statistics::Statistics
  DataPageHeader() = (o=new(); fillunset(o); o)
end # mutable struct DataPageHeader
meta(t::Type{DataPageHeader}) = meta(t, Symbol[:statistics], Int[], Dict{Symbol,Any}())

mutable struct IndexPageHeader <: Thrift.TMsg
end # mutable struct IndexPageHeader

mutable struct DictionaryPageHeader <: Thrift.TMsg
  num_values::Int32
  encoding::Int32
  is_sorted::Bool
  DictionaryPageHeader() = (o=new(); fillunset(o); o)
end # mutable struct DictionaryPageHeader
meta(t::Type{DictionaryPageHeader}) = meta(t, Symbol[:is_sorted], Int[], Dict{Symbol,Any}())

mutable struct DataPageHeaderV2 <: Thrift.TMsg
  num_values::Int32
  num_nulls::Int32
  num_rows::Int32
  encoding::Int32
  definition_levels_byte_length::Int32
  repetition_levels_byte_length::Int32
  is_compressed::Bool
  statistics::Statistics
  DataPageHeaderV2() = (o=new(); fillunset(o); o)
end # mutable struct DataPageHeaderV2
meta(t::Type{DataPageHeaderV2}) = meta(t, Symbol[:is_compressed,:statistics], Int[], Dict{Symbol,Any}(:is_compressed => true))

mutable struct PageHeader <: Thrift.TMsg
  _type::Int32
  uncompressed_page_size::Int32
  compressed_page_size::Int32
  crc::Int32
  data_page_header::DataPageHeader
  index_page_header::IndexPageHeader
  dictionary_page_header::DictionaryPageHeader
  data_page_header_v2::DataPageHeaderV2
  PageHeader() = (o=new(); fillunset(o); o)
end # mutable struct PageHeader
meta(t::Type{PageHeader}) = meta(t, Symbol[:crc,:data_page_header,:index_page_header,:dictionary_page_header,:data_page_header_v2], Int[], Dict{Symbol,Any}())

mutable struct KeyValue <: Thrift.TMsg
  key::String
  value::String
  KeyValue() = (o=new(); fillunset(o); o)
end # mutable struct KeyValue
meta(t::Type{KeyValue}) = meta(t, Symbol[:value], Int[], Dict{Symbol,Any}())

mutable struct SortingColumn <: Thrift.TMsg
  column_idx::Int32
  descending::Bool
  nulls_first::Bool
  SortingColumn() = (o=new(); fillunset(o); o)
end # mutable struct SortingColumn

mutable struct PageEncodingStats <: Thrift.TMsg
  page_type::Int32
  encoding::Int32
  count::Int32
  PageEncodingStats() = (o=new(); fillunset(o); o)
end # mutable struct PageEncodingStats

mutable struct ColumnMetaData <: Thrift.TMsg
  _type::Int32
  encodings::Vector{Int32}
  path_in_schema::Vector{String}
  codec::Int32
  num_values::Int64
  total_uncompressed_size::Int64
  total_compressed_size::Int64
  key_value_metadata::Vector{KeyValue}
  data_page_offset::Int64
  index_page_offset::Int64
  dictionary_page_offset::Int64
  statistics::Statistics
  encoding_stats::Vector{PageEncodingStats}
  ColumnMetaData() = (o=new(); fillunset(o); o)
end # mutable struct ColumnMetaData
meta(t::Type{ColumnMetaData}) = meta(t, Symbol[:key_value_metadata,:index_page_offset,:dictionary_page_offset,:statistics,:encoding_stats], Int[], Dict{Symbol,Any}())

mutable struct EncryptionWithFooterKey <: Thrift.TMsg
end # mutable struct EncryptionWithFooterKey

mutable struct EncryptionWithColumnKey <: Thrift.TMsg
  path_in_schema::Vector{String}
  column_key_metadata::Vector{UInt8}
  EncryptionWithColumnKey() = (o=new(); fillunset(o); o)
end # mutable struct EncryptionWithColumnKey
meta(t::Type{EncryptionWithColumnKey}) = meta(t, Symbol[:column_key_metadata], Int[], Dict{Symbol,Any}())

mutable struct ColumnCryptoMetaData <: Thrift.TMsg
  ENCRYPTION_WITH_FOOTER_KEY::EncryptionWithFooterKey
  ENCRYPTION_WITH_COLUMN_KEY::EncryptionWithColumnKey
  ColumnCryptoMetaData() = (o=new(); fillunset(o); o)
end # mutable struct ColumnCryptoMetaData
meta(t::Type{ColumnCryptoMetaData}) = meta(t, Symbol[:ENCRYPTION_WITH_FOOTER_KEY,:ENCRYPTION_WITH_COLUMN_KEY], Int[], Dict{Symbol,Any}())

mutable struct ColumnChunk <: Thrift.TMsg
  file_path::String
  file_offset::Int64
  meta_data::ColumnMetaData
  offset_index_offset::Int64
  offset_index_length::Int32
  column_index_offset::Int64
  column_index_length::Int32
  crypto_meta_data::ColumnCryptoMetaData
  ColumnChunk() = (o=new(); fillunset(o); o)
end # mutable struct ColumnChunk
meta(t::Type{ColumnChunk}) = meta(t, Symbol[:file_path,:meta_data,:offset_index_offset,:offset_index_length,:column_index_offset,:column_index_length,:crypto_meta_data], Int[], Dict{Symbol,Any}())

mutable struct RowGroup <: Thrift.TMsg
  columns::Vector{ColumnChunk}
  total_byte_size::Int64
  num_rows::Int64
  sorting_columns::Vector{SortingColumn}
  RowGroup() = (o=new(); fillunset(o); o)
end # mutable struct RowGroup
meta(t::Type{RowGroup}) = meta(t, Symbol[:sorting_columns], Int[], Dict{Symbol,Any}())

mutable struct TypeDefinedOrder <: Thrift.TMsg
end # mutable struct TypeDefinedOrder

mutable struct ColumnOrder <: Thrift.TMsg
  TYPE_ORDER::TypeDefinedOrder
  ColumnOrder() = (o=new(); fillunset(o); o)
end # mutable struct ColumnOrder
meta(t::Type{ColumnOrder}) = meta(t, Symbol[:TYPE_ORDER], Int[], Dict{Symbol,Any}())

mutable struct PageLocation <: Thrift.TMsg
  offset::Int64
  compressed_page_size::Int32
  first_row_index::Int64
  PageLocation() = (o=new(); fillunset(o); o)
end # mutable struct PageLocation

mutable struct OffsetIndex <: Thrift.TMsg
  page_locations::Vector{PageLocation}
  OffsetIndex() = (o=new(); fillunset(o); o)
end # mutable struct OffsetIndex

mutable struct ColumnIndex <: Thrift.TMsg
  null_pages::Vector{Bool}
  min_values::Vector{Vector{UInt8}}
  max_values::Vector{Vector{UInt8}}
  boundary_order::Int32
  null_counts::Vector{Int64}
  ColumnIndex() = (o=new(); fillunset(o); o)
end # mutable struct ColumnIndex
meta(t::Type{ColumnIndex}) = meta(t, Symbol[:null_counts], Int[], Dict{Symbol,Any}())

mutable struct FileMetaData <: Thrift.TMsg
  version::Int32
  schema::Vector{SchemaElement}
  num_rows::Int64
  row_groups::Vector{RowGroup}
  key_value_metadata::Vector{KeyValue}
  created_by::String
  column_orders::Vector{ColumnOrder}
  FileMetaData() = (o=new(); fillunset(o); o)
end # mutable struct FileMetaData
meta(t::Type{FileMetaData}) = meta(t, Symbol[:key_value_metadata,:created_by,:column_orders], Int[], Dict{Symbol,Any}())

mutable struct AesGcmV1 <: Thrift.TMsg
  aad_metadata::Vector{UInt8}
  AesGcmV1() = (o=new(); fillunset(o); o)
end # mutable struct AesGcmV1
meta(t::Type{AesGcmV1}) = meta(t, Symbol[:aad_metadata], Int[], Dict{Symbol,Any}())

mutable struct AesGcmCtrV1 <: Thrift.TMsg
  aad_metadata::Vector{UInt8}
  AesGcmCtrV1() = (o=new(); fillunset(o); o)
end # mutable struct AesGcmCtrV1
meta(t::Type{AesGcmCtrV1}) = meta(t, Symbol[:aad_metadata], Int[], Dict{Symbol,Any}())

mutable struct EncryptionAlgorithm <: Thrift.TMsg
  AES_GCM_V1::AesGcmV1
  AES_GCM_CTR_V1::AesGcmCtrV1
  EncryptionAlgorithm() = (o=new(); fillunset(o); o)
end # mutable struct EncryptionAlgorithm
meta(t::Type{EncryptionAlgorithm}) = meta(t, Symbol[:AES_GCM_V1,:AES_GCM_CTR_V1], Int[], Dict{Symbol,Any}())

mutable struct FileCryptoMetaData <: Thrift.TMsg
  encryption_algorithm::EncryptionAlgorithm
  encrypted_footer::Bool
  footer_key_metadata::Vector{UInt8}
  footer_offset::Int64
  iv_prefix::Vector{UInt8}
  FileCryptoMetaData() = (o=new(); fillunset(o); o)
end # mutable struct FileCryptoMetaData
meta(t::Type{FileCryptoMetaData}) = meta(t, Symbol[:footer_key_metadata,:iv_prefix], Int[], Dict{Symbol,Any}())
