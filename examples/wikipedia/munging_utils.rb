# encoding:UTF-8
module MungingUtils

  INTEGER_RE = %q{(\\d+)}
  FLOAT_RE = %q{(\\d+\\.\\d+)}
  STRING_RE = %q{'((?:[^\\\\']|\\\\+.)*)'}
  FIELD_RE = "(#{INTEGER_RE}|#{FLOAT_RE}|#{STRING_RE})"

  def self.guard_encoding line, &blk
    if line.valid_encoding?
      blk.call(line)
    else 
      repaired_line = []
      line.each_char do |char|
        if char.valid_encoding?
          repaired_line << char
        else
          repaired_line << "?"
        end
      end
      blk.call(repaired_line.join)
    end
  end

  def self.time_columns_from_time(time)
    columns = []
    columns << "%04d%02d%02d" % [time.year, time.month, time.day]
    columns << "%02d%02d%02d" % [time.hour, time.minute, time.second]
    columns << time.to_i
    columns << time.wday
    return columns
  end

  def self.create_sql_regex(field_types)
    regexes = []
    field_types.each do |field_type|
      case field_type
      when :int
        regexes << INTEGER_RE
      when :float
        regexes << FLOAT_RE
      when :string
        regexes << STRING_RE
      else
        regexes << FIELD_RE
      end
    end
    Regexp.new("\\(#{regexes.join(',')}\\)")
  end

end
