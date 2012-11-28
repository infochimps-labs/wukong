module Wukong
  module SpecHelpers
    # This module defines methods to be included into the
    # Wukong::Processor class.
    module ProcessorSpecMethods

      # An array of accumulated records to process come match-time.
      attr_reader :given_records

      # Give a collection of records to the processor.
      #
      # @param [Array] records
      def given *records
        @given_records ||= []
        @given_records.concat(records)
        self                    # for chaining
      end

      # Give a collection of records to the processor but turn each
      # to JSON first.
      #
      # @param [Array] records
      def given_json *records
        self.given(*records.map { |record| MultiJson.dump(record) })
      end
      
      # Give a collection of records to the processor but join each
      # in a delimited format first.
      #
      # @param [Array] records
      def given_delimited delimiter, *records
        self.given(*records.map do |record|
                     record.map(&:to_s).join(delimiter)
                   end.join("\n"))
      end

      # Give a collection of records to the processor but join each
      # in TSV format first.
      #
      # @param [Array] records
      def given_tsv *records
        self.given_delimited("\t", *records)
      end

      # Give a collection of records to the processor but join each
      # in CSV format first.
      #
      # @param [Array] records
      def given_csv *records
        self.given_delimited(",", *records)
      end
    end
  end
end
