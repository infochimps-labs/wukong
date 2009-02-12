module Wukong
  module Streamer
    #
    #
    #
    class StructStreamer < Wukong::Streamer::Base
      def itemize line
        StructItemizer.itemize *super(line)
      end
    end

    #
    #
    #
    module StructItemizer
      def self.class_from_resource klass_name
        begin klass = klass_name.to_s.camelize.constantize
        rescue ; warn "Bogus class name '#{klass_name}'" ; return ; end
      end

      def self.itemize klass_name, *vals
        return if klass_name =~ /^(?:bogus-|bad_record)/
        klass_name.gsub!(/-.*$/, '') # kill off all but class name
        klass = self.class_from_resource(klass_name) or return
        [ klass.new(*vals) ]
      end
    end

  end
end
