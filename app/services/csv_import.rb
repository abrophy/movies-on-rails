require "csv"

# Shared helpers for the two CSV importers.
#
# Safety model — CSV content is treated as untrusted input:
# * Structure: the header row must match the expected columns exactly; anything
#   else raises InvalidStructureError before any data is written.
# * Sanitization: values are trimmed and stripped of control characters, and
#   `year`/`stars` are validated by type and range.
# * Injection: all writes go through `insert_all`, which binds values as SQL
#   parameters — no CSV value is ever concatenated into SQL.
module CsvImport
  MOVIES_COLUMNS = [ "Movie", "Description", "Year", "Director", "Actor", "Filming location", "Country" ].freeze
  REVIEWS_COLUMNS = [ "Movie", "User", "Stars", "Review" ].freeze

  class InvalidStructureError < StandardError; end

  private

  # Trim whitespace and strip C0 control characters (keeping tab, LF, and CR).
  def clean_text(value)
    value.to_s.strip.gsub(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/, "")
  end

  def read_header(path)
    CSV.open(path, encoding: "bom|utf-8", &:shift)
  end

  def validate_columns!(headers, expected, path)
    actual = Array(headers).map { |header| header.to_s.strip.sub(/^\uFEFF/, "") }
    return if actual == expected

    raise InvalidStructureError,
      "Unrecognized CSV structure in #{File.basename(path.to_s)}: " \
      "expected columns [#{expected.join(', ')}], got [#{actual.join(', ')}]"
  end

  def record_error(path, line, message)
    @errors << { file: File.basename(path.to_s), line: line, message: message }
  end

  def with_timestamps(rows)
    now = Time.current
    rows.map { |row| row.merge(created_at: now, updated_at: now) }
  end
end
