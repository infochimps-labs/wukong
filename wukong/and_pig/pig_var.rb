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
      def self.anon slug
        idx = (Wukong::AndPig.anon_var_idx += 1)
        "_#{slug}_#{idx}_".to_sym
      end
      # Create a name building off this one
      def anon
        slug = name.to_s.gsub(/^_/,'').gsub(/_\d+_$/,'')
        self.class.anon slug
      end

      #
      def new_in_chain lval, l_klass, l_cmd
        rval = self.class.new l_klass, lval, l_cmd
        self.class.set lval, rval
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


