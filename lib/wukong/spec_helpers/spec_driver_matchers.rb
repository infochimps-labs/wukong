require_relative('spec_driver')

module Wukong
  module SpecHelpers
    
    module SpecMatchers

      def emit *expected
        EmitMatcher.new(*expected)
      end

      def emit_json *expected
        JsonMatcher.new(*expected)
      end

      def emit_delimited delimiter, *expected
        DelimiterMatcher.new(delimiter, *expected)
      end

      def emit_tsv *expected
        TsvMatcher.new(*expected)
      end

      def emit_csv *expected
        CsvMatcher.new(*expected)
      end
    end

    class EmitMatcher

      attr_accessor :driver, :expected, :reason, :expected_record, :actual_record, :mismatched_index

      def matches?(dataflow)
        self.driver = SpecDriver.new(dataflow)
        driver.run
        if actual_size != expected_size
          self.reason = :size
          return false
        end
        return true if just_count?
        expected.each_with_index do |expectation, index|
          actual = output[index]
          if actual != expectation
            self.reason           = :element
            self.expected_record  = expectation
            self.actual_record    = actual
            self.mismatched_index = index
            return false
          end
        end
        true
      end
      
      def initialize *expected
        self.expected = expected
      end

      def failure_message
        if reason == :size
          "Expected #{expected_size} records, got #{actual_size}:\n\n#{pretty_output}"
        else
          "Expected the #{ordinalize(mismatched_index)} record to be#{parse_modifier}\n\n#{expected_record}\n\nbut got\n\n#{pretty_output}"
        end
      end

      def negative_failure_message
        if reason == :size
          "Expected to NOT get #{expected_size} records:\n\n#{output}"
        else
          "Expected the #{ordinalize(mismatched_index)} record to NOT be#{parse_modifier}\n\n#{pretty_output}"
        end
      end
      
      def records
        @just_count = true
        self                    # chaining
      end
      alias_method :record, :records

      private
      
      def just_count?
        @just_count
      end

      def actual_size
        driver.size
      end

      def expected_size
        just_count? ? expected.first.to_i : expected.size
      end

      def output
        driver
      end

      def parse_modifier
      end

      def pretty_output
        [].tap do |pretty|
          output.each_with_index do |record, index|
            s      = (record.is_a?(String) ? record : record.inspect)
            prefix = case
            when output.size > 1 && index == mismatched_index
              " => "
            when output.size > 1
              "    "
            else
              ''
            end
            pretty << [prefix,s].join('')
          end
        end.join("\n")
      end

      # http://stackoverflow.com/questions/1081926/how-do-i-format-a-date-in-ruby-to-include-rd-as-in-3rd
      def ordinalize array_index
        n = array_index + 1
        if (11..13).include?(n % 100)
          "#{n}th"
        else
          case n % 10
          when 1; "#{n}st"
          when 2; "#{n}nd"
          when 3; "#{n}rd"
          else    "#{n}th"
          end
        end
      end
    end

    class JsonMatcher < EmitMatcher
      def output
        driver.map do |record|
          begin
            MultiJson.load(record)
          rescue => e
            raise Error.new("Could not parse output of dataflow as JSON: \n\n#{record}")
          end
        end
      end
      def parse_modifier
        ' (after parsing as JSON)'
      end
    end

    class DelimitedMatcher < EmitMatcher

      attr_accessor :delimiter
      
      def initialize delimiter, *expected
        self.delimiter = delimiter
        super(*expected)
      end
      
      def output
        driver.map do |record|
          begin
            record.to_s.split(delimiter)
          rescue => e
            raise Error.new("Could not parse as #{delimited_type}': \n\n#{record}")
          end
        end
      end

      def delimited_type
        "'#{delimiter}-delimited'"
      end
      
      def parse_modifier
        " (after parsing as #{delimited_type})"
      end
    end

    class TsvMatcher < DelimitedMatcher
      def initialize *expected
        super("\t", *expected)
      end
      def delimited_type
        "TSV"
      end
    end

    class CsvMatcher < DelimitedMatcher
      def initialize *expected
        super(",", *expected)
      end
      def delimited_type
        "CSV"
      end
    end
  end
end
