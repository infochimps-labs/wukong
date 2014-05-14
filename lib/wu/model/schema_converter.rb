require 'gorillib/string/inflections'

#
# Basic types: SQL conversion
#
module Gorillib
  module Model

    module ClassMethods

      def sql_schema(opts={})
        lines = []
        lines << fields.each_with_index.map do |(_,fld),ii|
          comment = (fld.doc.present? ? " COMMENT '#{ii}: #{fld.doc.gsub(/[\'\"\r\n]+/, " ")}'" : "" )
          if fld.type.respond_to?(:to_sql)
            "  %-29s\t%-23s\t%s" % ["`#{fld.name}`", fld.type.to_sql(fld), comment]
          else
            "  %-29s\t%-23s\t%s" % ["`_#{fld.name}`", 'VARCHAR(255),', "COMMENT 'Cannot make SQL schema for #{fld.name}'"]
          end
        end
        lines << '  -- ' if indexes.present?
        indexes.each do |name, idx|
          key_str = case when idx[:primary] then "PRIMARY KEY" when idx[:unique] then "UNIQUE KEY" else  "KEY" end
          lines << "  %-11s %-12s\t(%s)" % [key_str, "`#{name}`", idx[:fields].map{|fn| "`#{fn}`" }.join(", ")]
        end
        lines.join(",\n")
      end

      def sql_create(opts={})
        lines = []
        lines << "CREATE TABLE `#{name.to_s.underscore}` ("
        lines << sql_schema
        lines << "  )"
        lines << "  ENGINE=#{opts[:engine]}"             if opts[:engine].present?
        lines << "  DEFAULT CHARSET=#{opts[:charset]}"   if opts[:charset].present?
        lines << "  PARTITION BY #{opts[:partition_by]}" if opts[:partition_by].present?
        lines << '  ;'
        lines.join("\n")
      end

      def pig_schema(opts={})
        lines = []
        lines << fields.map do |_,fld|
          if    (fld.type.is_a? Gorillib::Factory::DateFactory) && opts[:date_as_chararray]
            "#{fld.name}:chararray"
          elsif fld.type.respond_to?(:to_pig)
            "#{fld.name}:#{fld.type.to_pig(fld)}"
          else
            "_#{fld.name}:bytearray"
          end
        end
        lines.join(", ")
      end

      def pig_load(opts={})
        var  = opts[:var]  || name.to_s.underscore.gsub(%r{.*/},'')
        path = opts[:path] || name.to_s.underscore
        lines = []
        lines << "#{var} = LOAD '#{path}' AS (\n"
        lines << "  " << pig_schema(opts)
        lines << "\n  );"
        lines.join
      end

    end
  end

  module Factory

    # ===========================================================================
    # #
    # # Pig conversion
    # #

    IntegerFactory.class_eval     do def to_pig(fld) 'long'          end ; end
    BignumFactory.class_eval      do def to_pig(fld) 'biginteger'    end ; end
    FloatFactory.class_eval       do def to_pig(fld) 'double'        end ; end
    StringlikeFactory.class_eval  do def to_pig(fld) 'chararray'     end ; end

    DateFactory.class_eval        do def to_pig(fld) 'datetime'      end ; end
    TimeFactory.class_eval        do def to_pig(fld) 'datetime'      end ; end
    BooleanFactory.class_eval     do def to_pig(fld) 'boolean'       end ; end if defined?(BooleanFactory)
    EpochTimeFactory.class_eval   do def to_pig(fld) 'int'           end ; end if defined?(EpochTimeFactory)
    # ArrayFactory.class_eval       do def to_pit() 'bag'         end ; end


    # ===========================================================================
    # #
    # # SQL conversion
    # #

    BignumFactory.class_eval  do  def to_sql(fld) 'BIGINT'  ; end ; end
    BooleanFactory.class_eval do  def to_sql(fld) 'BOOLEAN' ; end ; end
    DateFactory.class_eval    do  def to_sql(fld) 'DATE'    ; end ; end
    TimeFactory.class_eval    do  def to_sql(fld) 'TIME'    ; end ; end

    IntegerFactory.class_eval do
      SQL_TYPE_RANGES = [
        [:unsigned, -2**7,   2**7-1,    'TINYINT'   ],
        [:unsigned, -2**15,  2**15-1,   'SMALLINT'  ],
        [:unsigned, -2**23,  2**23-1,   'MEDIUMINT' ],
        [:unsigned, -2**31,  2**31-1,   'INTEGER'   ],
        [:signed,   0,       2**8-1,    'TINYINT'   ],
        [:signed,   0,       2**16-1,   'SMALLINT'  ],
        [:signed,   0,       2**24-1,   'MEDIUMINT' ],
        [:signed,   0,       2**32-1,   'INTEGER'   ],
      ]

      def to_sql(fld)
        base = 'INTEGER'
        #
        if fld.in.present?
          min_val = fld.in.min if fld.in.respond_to?(:min)
          max_val = fld.in.max if fld.in.respond_to?(:max)
          signedness = fld.signed? ? :signed : :unsigned
          SQL_TYPE_RANGES.each do |type_sign, type_min_val, type_max_val, type_str|
            if (type_sign == signedness) && (min_val >= type_min_val) && (max_val <= type_max_val)
              base = type_str
              break
            end
          end
          display_len = [min_val.abs.to_s.length, max_val.abs.to_s.length].max
          base += "(#{display_len})"
        end
        not_null  = fld.required? ? 'NOT NULL' : nil
        ["%-12s" % base, not_null].compact.join(" ").strip
      end
    end

    FloatFactory.class_eval do
      def to_sql(fld)
        base = 'FLOAT'
        not_null  = fld.required? ? 'NOT NULL' : nil
        ["%-12s" % base, not_null].compact.join(" ").strip
      end
    end

    class StringlikeFactory
      def to_sql(fld)
        exact = fld.length.is_a?(Integer)
        len   = if fld.length.is_a?(Integer) then fld.length elsif fld.length.respond_to?(:max) then fld.length.max else nil end
        if len.nil?
          base = "VARCHAR(255)"
        elsif len > 255
          base = "TEXT"
        elsif exact
          base = "CHAR(#{len})"
        else
          base = "VARCHAR(#{len})"
        end
        charset   = fld.charset   ? "CHARACTER SET #{fld.charset.upcase}" : nil
        not_null  = fld.required? ? 'NOT NULL' : nil
        ["%-12s" % base, charset, not_null].compact.join(" ").strip
      end
    end

    # ===========================================================================
    # #
    # # Basic types: Avro conversion
    # #
    # class IntegerFactory    ; def to_avro() 'int'           end ; end
    # class BignumFactory     ; def to_avro() 'long'          end ; end
    # class FloatFactory      ; def to_avro() 'float'         end ; end
    # class StringlikeFactory ; def to_avro() 'string'        end ; end
    # class DateFactory       ; def to_avro() 'long'          end ; end
    # class TimeFactory       ; def to_avro() 'long'          end ; end
    # class TextFactory       ; def to_avro() 'string'        end ; end if defined?(Text)
    # class BlobFactory       ; def to_avro() 'bytearray'     end ; end if defined?(Blob)
    # class BooleanFactory    ; def to_avro() 'bytearray'     end ; end if defined?(Boolean)

  end
end
