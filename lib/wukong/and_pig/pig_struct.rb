module Wukong
  module PigStructMethods
    module ClassMethods
      #
      # Pig type string --
      # the pig type strings for each sub-element.
      #
      def typify has_rsrc=nil
        vars_str = members.zip(mtypes).map do |attr, mtype|
          "%s: %s" % [attr, mtype.typify]
        end
        vars_str = ["rsrc: chararray"] + vars_str if has_rsrc
        "(#{vars_str.join(', ')})"
      end

      #
      #
      #
      def pig_load rel, *args
        Wukong::AndPig::PigVar.pig_load rel, self, *args
      end

      #
      # Returns type for a fieldspec
      #
      def field_type field
        case field
        when Symbol             then members_types[field]
        # when Array
        #   if field.length > 1   then members_types[field.first].field_type(field[1..-1])
        #   else                       field_type field.first
        #   end
        end
      end

    end
    def self.included base
      base.extend ClassMethods
    end
  end
end

Struct.class_eval do
  include Wukong::PigStructMethods
  def self.mtypes
    members
  end
end
