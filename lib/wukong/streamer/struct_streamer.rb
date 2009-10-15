# -*- coding: utf-8 -*-
module Wukong
  module Streamer
    #
    # Mix StructRecordizer into any streamer to make it accept a stream of
    # objects -- the first field in each line is turned into a class and used to
    # instantiate an object using the remaining fields on that line.
    #
    module StructRecordizer

      #
      # Turned the first field into a class name, then use the remaining fields
      # on that line to instantiate the object to process.
      #
      def self.recordize rsrc, *fields
        klass_name, suffix = rsrc.split('-', 2)
        klass = Wukong.class_from_resource(klass_name) or return
        # instantiate the class using the remaining fields on that line
        begin
          [ klass.new(*fields), suffix ]
        rescue ArgumentError => e
          warn "Couldn't instantiate: #{e} (#{[klass, fields].inspect})"
          return
        rescue Exception => e
          raise [e, rsrc, fields].inspect
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
