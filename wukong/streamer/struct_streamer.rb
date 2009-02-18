module Wukong
  module Streamer
    #
    # Mix StructRecordizer into any streamer to make it accept a stream of
    # objects -- the first field in each line is turned into a class and used to
    # instantiate an object using the remaining fields on that line.
    #
    module StructRecordizer
      def self.class_from_resource klass_name
        # kill off all but class name
        klass_name = klass_name.gsub(/-.*$/, '')
        begin
          # convert it to class name
          klass = klass_name.to_s.camelize.constantize
        rescue Exception => e
          warn "Bogus class name '#{klass_name}'? #{e}"
          return
        end
      end

      #
      # Turned the first field into a class name, then use the remaining fields
      # on that line to instantiate the object to process.
      #
      def self.recordize klass_name, *fields
        return if klass_name =~ /^(?:bogus-|bad_record)/
        klass = class_from_resource(klass_name) or return
        # instantiate the class using the remaining fields on that line
        begin
          [ klass.new(*fields) ]
        rescue Exception => e
          raise [e, klass_name, fields].inspect
        end
      end

      #
      #
      #
      def recordize line
        StructRecordizer.recordize *line.split("\t")
      end
    end

    #
    # Processes file as a stream of objects -- the first field in each line is
    # turned into a class and used to instantiate an object using the remaining
    # fields on that line.
    #
    # See [StructRecordizer] for more.
    #
    class StructStreamer < Wukong::Streamer::Base
      include StructRecordizer
    end
  end
end
