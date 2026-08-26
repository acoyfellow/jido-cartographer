defmodule JidoCartographer.Limits do
  @archive_bytes 25 * 1024 * 1024
  @max_files 2_000
  @max_archive_entries 10_000
  @file_bytes 512 * 1024
  @expanded_bytes 64 * 1024 * 1024
  @max_concurrency 256
  @fetch_timeout_ms 20_000
  @index_timeout_ms 60_000

  def archive_bytes, do: @archive_bytes
  def max_files, do: @max_files
  def max_archive_entries, do: @max_archive_entries
  def file_bytes, do: @file_bytes
  def expanded_bytes, do: @expanded_bytes
  def max_concurrency, do: @max_concurrency
  def fetch_timeout_ms, do: @fetch_timeout_ms
  def index_timeout_ms, do: @index_timeout_ms
end
