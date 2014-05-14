module Gorillib
  module Model
    class Field

      field :length,    :whatever
      field :in,        :whatever
      field :charset,   :string
      field :signed,    :boolean  ; def signed?()   !! self.signed   ; end
      field :required,  :boolean  ; def required?() !! self.required ; end
    end

    module ClassMethods
      attr_reader :_own_indexes

      RESETTABLE_ACCS = %w[@_fields @_field_names @_positionals]
      RESETTABLE_ACCS << "@_indexes"

      # Ensure that classes inherit all their parents' fields, even if fields
      # are added after the child class is defined.
      def _reset_descendant_fields
        ObjectSpace.each_object(::Class) do |klass|
          RESETTABLE_ACCS.each do |acc|
            klass.__send__(:remove_instance_variable, acc) if (klass <= self) && klass.instance_variable_defined?(acc)
          end
        end
      end

      def indexes
        return @_indexes if defined?(@_indexes)
        @_indexes = ancestors.reverse.inject({}){|acc, ancestor| acc.merge!(ancestor.try(:_own_indexes) || {}) }
      end
      def index(ixname, fns, opts={})
        @_own_indexes ||= {}
        @_own_indexes[ixname] = opts.merge(fields: fns)
      end
    end
  end
end
