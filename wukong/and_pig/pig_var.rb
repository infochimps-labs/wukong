module Wukong
  module AndPig

    #
    # Make a PigVar understand the struct it describes
    #
    class PigVar
      attr_accessor :klass, :basename, :anon, :cmd
      cattr_accessor :working_dir
      def initialize klass, basename, cmd
        self.klass    = klass
        self.basename = basename
        self.cmd      = cmd
        self.anon     = ( Wukong::AndPig.anon_var_idx += 1 )
      end

      # Adds the given generator to the pig symbol table
      def self.new_relation name, rval
        # rval = new *args
        PIG_SYMBOLS[name] = rval
        rval.name = name
        emit_setter rval.relation, rval
      end

      # Sugar for PigVar.new_relation
      def self.[]= name, *args
        new_relation name, *args
      end

      def name
        anon ? "#{basename}_#{anon}".to_sym : basename
      end
      def name= rel
        self.anon = nil
        self.basename = rel
      end

      def relation
        name.relationize
      end
      alias_method :relationize, :relation

      #
      # pig subexpression for the relation's aliases and types
      #
      def self.type_spec klass
        klass.members_types.join(", ")
      end

      #
      def new_in_chain l_klass, l_cmd
        self.class.new l_klass, basename, l_cmd
      end

      #
      # Side-effect free operation
      #
      def simple_operation op
        self.class.emit  "#{op.to_s.upcase} #{relation}"
        self
      end
    end
  end
end


# module Wukong
#   module AndPig
#     class PigVar
#       cattr_accessor :default_path
#       attr_accessor  :name, :klass, :path_base
#       def initialize name, klass, path_base=nil
#         self.name       = name.relationize.underscore
#         self.klass      = klass
#         self.path_base = path_base || self.class.default_path
#       end
#
#
#       def foreach dest_rel, *args
#         case
#         when args.length == 1 && args[0].is_a?(String) then gen_string = args[0]
#         else gen_string = 'GENERATE ' + args.join(", ")
#         end
#         emit_set dest_rel.relationize, "FOREACH #{relation} #{gen_string}"
#         PigVar.new dest_rel, klass
#       end
#       alias_method :generate, :foreach
#
#       # ===========================================================================
#       #
#       # Synthesized Expressions
#       #
#       REL_COUNTERS = { }
#       def temp_rel rel
#         REL_COUNTERS[rel] ||= 0
#         REL_COUNTERS[rel]  += 1
#         "#{rel}_#{REL_COUNTERS[rel]}"
#       end
#     end
#   end
# end

