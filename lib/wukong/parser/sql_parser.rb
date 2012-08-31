module Wukong
  module Parser
    class SQLParser
      attr_accessor :columns 

      INTEGER_RE = %q{(\\d+)}
      FLOAT_RE = %q{(\\d+\\.\\d+)}
      STRING_RE = %q{'((?:[^\\\\']|\\\\+.)*)'}
      FIELD_RE = "(#{INTEGER_RE}|#{FLOAT_RE}|#{STRING_RE})"

        # Creates a new SQLParser from a list of columns types.
        # Column types should be either :int, :float, or :string. 
        # e.g. [:int, :int, :float, :string]
        def initialize(columns)
          self.columns = columns
        end

        def columns=(columns)
          @re = self.class.create_sql_regex(columns)
          @columns = columns
        end

        # Accepts a SQL dump line as a string and 
        # extracts all records from it. Note that there
        # may be multiple records per INSERT INTO statement,
        # so records are yielded rather than returned. 
        def parse line
          return nil unless line =~/INSERT INTO/
          records = [] unless block_given?
          line.scan(@re).each do |record|
            @columns.each_with_index do |type, index|
              next unless type == :string
              record[index].gsub!(/\\(['"\\])/,'\1') # un-escape the record
            end
            if block_given?
              yield record
            else
              records << record
            end
          end
          return records unless block_given?
        end

        # Creates a regex that will match SQL INSERT statements
        # from the supplied field_types. See 'initialize' comments
        # for formatting.
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
  end
end
