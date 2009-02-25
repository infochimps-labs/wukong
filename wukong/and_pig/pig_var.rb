module Wukong
  module AndPig

    #
    # Make a PigVar understand the struct it describes
    #
    class PigVar
      attr_accessor :klass, :name, :cmd
      cattr_accessor :working_dir ; self.working_dir = '.'
      def initialize klass, name, cmd
        self.klass    = klass
        self.name     = name
        self.cmd      = cmd
      end

      # Sugar for PigVar.new_relation
      def self.[]= name, *args
        set name, *args
      end
      # Sugar for PigVar.new_relation
      def self.[] name
        PIG_SYMBOLS[name]
      end

      def self.set name, rval
        PIG_SYMBOLS[name] = rval
        rval.name = name
        emit_setter rval.relation, rval
      end

      def relation
        name.relationize
      end
      alias_method :relationize, :relation

      #
      # Create a name for a new anonymous relation
      #
      def self.anon sym
        idx = (Wukong::AndPig.anon_var_idx += 1)
        "#{sym}_#{idx}".to_sym
      end

      #
      def new_in_chain l_klass, l_cmd
        self.class.new l_klass, name, l_cmd
      end

      # Delegate to klass
      def field_type *args
        self.klass.field_type *args
      end

      # Fields in this relation
      def fields
        klass.members.map(&:to_sym)
      end

      #
      # Side-effect free operation
      #
      def simple_operation op
        self.class.emit  "#{op.to_s.upcase} #{relation}"
        self
      end

      def self.simple_operation lval, rel, op, r_str
        cmd  = "%-8s %s" % [op.to_s.upcase, r_str]
        rval = new(rel.klass, lval, cmd)
        set lval, rval
      end

      def self.simple_declaration op, r_str
        cmd  = "%-8s %s" % [op.to_s.upcase, r_str]
        emit cmd
      end

    end
  end
end


