require 'extlib/inflection'
require 'wukong'


#
# Basic types: SQL conversion
#
class << Integer    ; def to_sql() 'INT'                              end ; end
class << Bignum     ; def to_sql() 'BIGINT'                           end ; end
class << String     ; def to_sql() 'VARCHAR(255) CHARACTER SET ASCII' end ; end
class << Symbol     ; def to_sql() 'VARCHAR(255) CHARACTER SET ASCII' end ; end
class << BigDecimal ; def to_sql() 'DECIMAL'                          end ; end if defined?(BigDecimal)
class << EpochTime  ; def to_sql() 'INT'                              end ; end if defined?(EpochTime)
class << FilePath   ; def to_sql() 'VARCHAR(255) CHARACTER SET ASCII' end ; end if defined?(FilePath)
class << Flag       ; def to_sql() 'CHAR(1)      CHARACTER SET ASCII' end ; end if defined?(Flag)
class << IPAddress  ; def to_sql() 'CHAR(15)     CHARACTER SET ASCII' end ; end if defined?(IPAddress)
class << URI        ; def to_sql() 'VARCHAR(255) CHARACTER SET ASCII' end ; end if defined?(URI)
class << Csv        ; def to_sql() 'TEXT'                             end ; end if defined?(Csv)
class << Yaml       ; def to_sql() 'TEXT'                             end ; end if defined?(Yaml)
class << Json       ; def to_sql() 'TEXT'                             end ; end if defined?(Json)
class << Regex      ; def to_sql() 'TEXT'                             end ; end if defined?(Regex)
class String        ; def to_sql() self             ; end ; end
class Symbol        ; def to_sql() self.to_s.upcase ; end ; end

#
# Basic types: Pig conversion
#
class << Integer    ; def to_pig() 'int'           end ; end
class << Bignum     ; def to_pig() 'long'          end ; end
class << Float      ; def to_pig() 'float'         end ; end
class << Symbol     ; def to_pig() 'chararray'     end ; end
class << Date       ; def to_pig() 'long'          end ; end
class << Time       ; def to_pig() 'long'          end ; end
class << DateTime   ; def to_pig() 'long'          end ; end
class << String     ; def to_pig() 'chararray'     end ; end
class << Text       ; def to_pig() 'chararray'     end ; end if defined?(Text)
class << Blob       ; def to_pig() 'bytearray'     end ; end if defined?(Blob)
class << Boolean    ; def to_pig() 'bytearray'     end ; end if defined?(Boolean)
class String        ; def to_pig() self.to_s ; end ; end
class Symbol        ; def to_pig() self.to_s ; end ; end

class << BigDecimal ; def to_pig() 'long'          end ; end if defined?(BigDecimal)
class << EpochTime  ; def to_pig() 'integer'       end ; end if defined?(EpochTime)
class << FilePath   ; def to_pig() 'chararray'     end ; end if defined?(FilePath)
class << Flag       ; def to_pig() 'chararray'     end ; end if defined?(Flag)
class << IPAddress  ; def to_pig() 'chararray'     end ; end if defined?(IPAddress)
class << URI        ; def to_pig() 'chararray'     end ; end if defined?(URI)
class << Csv        ; def to_pig() 'chararray'     end ; end if defined?(Csv)
class << Yaml       ; def to_pig() 'chararray'     end ; end if defined?(Yaml)
class << Json       ; def to_pig() 'chararray'     end ; end if defined?(Json)
class << Regex      ; def to_pig() 'chararray'     end ; end if defined?(Regex)


#
# Basic types: Avro conversion
#
class << Integer    ; def to_avro() 'int'           end ; end
class << Bignum     ; def to_avro() 'long'          end ; end
class << Float      ; def to_avro() 'float'         end ; end
class << Symbol     ; def to_avro() 'string'        end ; end
class << Date       ; def to_avro() 'long'          end ; end
class << Time       ; def to_avro() 'long'          end ; end
class << DateTime   ; def to_avro() 'long'          end ; end
class << String     ; def to_avro() 'string'        end ; end
class << Text       ; def to_avro() 'string'        end ; end if defined?(Text)
class << Blob       ; def to_avro() 'bytearray'     end ; end if defined?(Blob)
class << Boolean    ; def to_avro() 'bytearray'     end ; end if defined?(Boolean)
class String        ; def to_avro() self.to_s ;     end ; end
class Symbol        ; def to_avro() self.to_s ;     end ; end

class << BigDecimal ; def to_avro() 'long'          end ; end if defined?(BigDecimal)
class << EpochTime  ; def to_avro() 'integer'       end ; end if defined?(EpochTime)
class << FilePath   ; def to_avro() 'string'        end ; end if defined?(FilePath)
class << Flag       ; def to_avro() 'string'        end ; end if defined?(Flag)
class << IPAddress  ; def to_avro() 'string'        end ; end if defined?(IPAddress)
class << URI        ; def to_avro() 'string'        end ; end if defined?(URI)
class << Csv        ; def to_avro() 'string'        end ; end if defined?(Csv)
class << Yaml       ; def to_avro() 'string'        end ; end if defined?(Yaml)
class << Json       ; def to_avro() 'string'        end ; end if defined?(Json)
class << Regex      ; def to_avro() 'string'        end ; end if defined?(Regex)

module Wukong
  #
  # Export model's structure for loading and manipulating in other frameworks,
  # such as SQL and Pig
  #
  # Your class should support the #resource_name and #mtypes methods
  # An easy way to do this is by being a TypedStruct.
  #
  # You can use this to do silly stunts like
  #
  #      % ruby -rubygems -r'wukong/schema' -e 'require "/path/to/user_model.rb" ; puts User.pig_load ; '
  #
  # If you include the classes from Wukong::Datatypes::MoreTypes, you can draw
  # on a richer set of type definitions
  #
  #     require 'wukong/datatypes/more_types'
  #     include Wukong::Datatypes::MoreTypes
  #     require 'wukong/schema'
  #
  # (if you're using Wukong to bulk-process Datamapper records, these should
  # fall right in line as well -- make sure *not* to include
  # Wukong::Datatypes::MoreTypes, and to require 'dm-more' before 'wukong/schema')
  #
  module Schema
    module ClassMethods

      #
      # Table name for this class
      #
      def table_name
        resource_name.to_s.pluralize
      end

      # ===========================================================================
      #
      # Pig
      #

      # Export schema as Pig
      #
      # Won't correctly handle complex types (struct having struct as member, eg)
      #
      def to_pig
        members.zip(mtypes).map do |member, type|
          member.to_s + ': ' + type.to_pig
        end.join(', ')
      end

      #
      # A pig snippet to load a tsv file containing
      # serialized instances of this class.
      #
      # Assumes the first column is the resource name (you can, and probably
      # should, follow with an immediate GENERATE to ditch that field.)
      #
      def pig_load filename=nil
        filename ||= resource_name.to_s+'.tsv'
        cmd = [
          "%-23s" % self.to_s.gsub(/^.*\W/, ""),
          "= LOAD '#{filename}'",
          "AS ( rsrc:chararray,", self.to_pig, ') ;',
        ].join(" ")
      end

      # ===========================================================================
      #
      # SQL

      #
      # Schema definition for use in a CREATE TABLE statement
      #
      def to_sql
        sql_str = []
        members.zip(mtypes).each do |attr, type|
          type_str = type.respond_to?(:to_sql) ? type.to_sql : type.to_s.upcase
          sql_str << "  %-29s\t%s" %["`#{attr}`", type_str]
        end
        sql_str.join(",\n")
      end

      #
      # List off member names, to be stuffed into a SELECT or a LOAD DATA
      #
      def sql_members
        members.map{|attr| "`#{attr}`" }.join(", ")
      end

      #
      # Creates a table for the wukong class.
      #
      # * primary_key gives the name of one column to be set as the primary key
      #
      # * if drop_first is given, a "DROP TABLE IF EXISTS" statement will
      #   precede the snippet.
      #
      # * table_options sets the table parameters. Useful table_options for a
      #   read-only database in MySQL:
      #     ENGINE=MyISAM PACK_KEYS=0
      #
      def sql_create_table primary_key=nil, drop_first=nil, table_options=''
        str = []
        str << %Q{DROP TABLE IF EXISTS `#{self.table_name}`;  } if drop_first
        str << %Q{CREATE TABLE         `#{self.table_name}` ( }
        str << self.to_sql
        if primary_key then str.last << ',' ; str << %Q{  PRIMARY KEY     \t(`#{primary_key}`)} ; end
        str << %Q{  ) #{table_options} ;}
        str.join("\n")
      end

      #
      # A mysql snippet to bulk load the tab-separated-values file emitted by a
      # Wukong script.
      #
      # Let's say your class is ClickLog; its resource_name is "click_log"
      # and thus its table_name is 'click_logs'. sql_load_mysql will:
      #
      # * disable indexing on the table
      # * import the file, replacing any existing rows. (Replacement is governed
      #   by primary key and unique index constraints -- see the mysql docs).
      # * re-enable indexing on that table
      # * show the number of
      #
      # The load portion will
      #
      # * Load into a table named click_logs
      # * from a file named click_logs.tsv
      # * where all rows have the string 'click_logs' in their first column
      # * and all remaining fields in their #members order
      # * assuming strings are wukong_encode'd and so shouldn't be escaped or enclosed.
      #
      # Why the "LINES STARTING BY" part? For map/reduce outputs that have many
      # different objects jumbled together, you can just dump in the whole file,
      # landing each object in its correct table.
      #
      def sql_load_mysql(filename=nil)
        filename ||= ":resource_name.tsv"
        filename.gsub!(/:resource_name/, self.table_name)
        str = []
        # disable indexing during bulk load
        str << %Q{ALTER TABLE            `#{self.table_name}` DISABLE KEYS; }
        # Bulk load the tab-separated-values file.
        str << %Q{LOAD DATA LOCAL INFILE '#{filename}'}
        str << %Q{  REPLACE INTO TABLE   `#{self.table_name}`    }
        str << %Q{  COLUMNS                                         }
        str << %Q{    TERMINATED BY           '\\t'                 }
        str << %Q{    OPTIONALLY ENCLOSED BY  ''                    }
        str << %Q{    ESCAPED BY              ''                    }
        str << %Q{  LINES STARTING BY     '#{self.resource_name}'   }
        str << %Q{  ( @dummy,\n }
        str << '    '+self.sql_members
        str << %Q{\n  ); }
        # Re-enable indexing
        str << %Q{ALTER TABLE `#{self.table_name}` ENABLE KEYS ; }
        # Show it loaded correctly
        str << %Q{SELECT NOW(), COUNT(*), '#{self.table_name}' FROM `#{self.table_name}`; }
        str.join("\n")
      end




      #
      # Avro
      #
      def to_avro
        require 'json' # yikes
        h = {}
        h[:name]   = self.name
        h[:type]   = "record"
        h[:fields] =  []
        members.zip(mtypes).each do |member, type|
          h[:fields] << {:name => member.to_s, :type => type.to_avro}
        end
        h.to_json
      end
      
    end
    # standard stanza for making methods appear on the class itself on include
    def self.included base
      base.class_eval{ extend ClassMethods }
    end
  end
end

#
# TypedStructs are class-schematizeable
#
Struct.class_eval do include(Wukong::Schema) ; end
