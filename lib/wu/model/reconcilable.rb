module Gorillib
  module Model
    module Reconcilable
      # @returns [Hash] all attributes that are set with non-nil values
      def reconcilable_attributes
        compact_attributes.compact!
      end

      # * asks the other object what attributes it has to give, via `#reconcilable_attrs`
      # * if this instance has a `adopt_foo` method, calls it; all further
      #   action (such as setting the consensus value) is done over there
      # * otherwise, calls adopt_attribute(attr, val) to set the consensus value
      #
      def adopt(obj)
        peace = true
        obj.reconcilable_attributes.each do |attr, val|
          if self.respond_to?("adopt_#{attr}")
            result = self.public_send("adopt_#{attr}", val, obj)
          else
            result = adopt_attribute(attr, val)
          end
          peace &&= result
        end
        peace
      end

      def conflicting_attribute!(attr, this_val, that_val)
        warn "  - conflicting values for #{attr}: had #{this_val.inspect} got #{that_val.inspect}"
        false
      end

    protected
      #
      #
      # * if our value is unset or nil: sets it to `that_val` and returns true
      # * if our value is equal to `that_val`: does nothing and returns true
      # * if our value is a reconcilable object,
      #   - have it adopt `that_val`
      #   - return the result
      # * otherwise the two values are in conflict:
      #   - warn about the conflict
      #   - return false
      #
      # note: this does _not_ treat a set-but-nil value on itself as important;
      # override the `adopt_{attr}` method if you want that behavior.
      #
      def adopt_attribute(attr, that_val)
        # handle unset immediately,so defaults / lazy evaluations aren't triggered
        if not attribute_set?(attr)        then write_attribute(attr, that_val) ; return true ; end
        this_val = read_attribute(attr)
        if    this_val.nil?                then write_attribute(attr, that_val) ; return true
        elsif this_val == that_val         then return true
        elsif this_val.respond_to?(:adopt) then return this_val.adopt(that_val)
        elsif block_given?
          return yield(attr, this_val, that_val)
        else
          return conflicting_attribute!(attr, this_val, that_val)
        end
      end

    end
  end
end
