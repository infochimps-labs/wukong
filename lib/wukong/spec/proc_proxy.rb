module Wukong
  module SpecHelper

    class ProcProxy
      def initialize proc, &block
        @proc   = proc
        yield @proc if block_given?
        @givens = []
      end
      
      def given event
        @givens << event
        self
      end

      def as_json
        @json = true
        self
      end

      def delimited delimiter
        @delimited = true
        @delimiter = delimiter
        self
      end

      def as_tsv
        delimited("\t")
        self
      end

      def run
        @outputs = [].tap do |output_records|
          @givens.each do |given_record|
            @proc.process(serialize(given_record)) do |output_record|
              output_records << output_record
            end
          end
        end
      end

      def serialize record
        case
        when @json      then MultiJson.dump(record)
        when @delimited then record.map(&:to_s).join(@delimiter)
        else record.to_s
        end
      end

      def outputs
        @outputs
      end
    end
  end
end
