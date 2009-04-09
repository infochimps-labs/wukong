# -*- coding: utf-8 -*-
module Wukong
  module Streamer
    #
    # Mix StructRecordizer into any streamer to make it accept a stream of
    # objects -- the first field in each line is turned into a class and used to
    # instantiate an object using the remaining fields on that line.
    #
    module StructRecordizer
      RESOURCE_CLASS_MAP = { }

      #
      # Find the class from its underscored name. Note the klass is non-modularized.
      # You can also pre-seed RESOURCE_CLASS_MAP
      #
      def self.class_from_resource rsrc
        #
        # This method has been profiled, so don't go making it more elegant
        # unless you're doing same.
        #
        rsrc = rsrc.to_s
        return RESOURCE_CLASS_MAP[rsrc] if RESOURCE_CLASS_MAP.include?(rsrc)
        # kill off all but the non-modularized class name and camelize
        klass_name = rsrc.gsub(/-.*$/, '').gsub(/(?:^|_)(.)/){ $1.upcase }
        begin
          # convert it to class name
          klass = klass_name.constantize
        rescue Exception => e
          warn "Bogus class name '#{klass_name}'? #{e}"
          klass = nil
        end
        RESOURCE_CLASS_MAP[rsrc] = klass
      end

      #
      # Turned the first field into a class name, then use the remaining fields
      # on that line to instantiate the object to process.
      #
      def self.recordize rsrc, *fields
        klass = class_from_resource(rsrc) or return
        # instantiate the class using the remaining fields on that line
        begin
          [ klass.new(*fields) ]
        rescue ArgumentError => e
          warn "Couldn't instantiate: #{e} (#{[rsrc, fields].inspect})"
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
