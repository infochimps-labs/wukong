#
# String Monkeypatched for processing with wukong: see wukong/extensions/string
#
String.class_eval do
  # By default, +camelize+ converts strings to UpperCamelCase. If the argument to +camelize+
  # is set to <tt>:lower</tt> then +camelize+ produces lowerCamelCase.
  #
  # +camelize+ will also convert '/' to '::' which is useful for converting paths to namespaces.
  #
  # Examples:
  #   "active_record".camelize                # => "ActiveRecord"
  #   "active_record".camelize(:lower)        # => "activeRecord"
  #   "active_record/errors".camelize         # => "ActiveRecord::Errors"
  #   "active_record/errors".camelize(:lower) # => "activeRecord::Errors"
  def camelize(first_letter_in_uppercase = true)
    if first_letter_in_uppercase
      self.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    else
      self.first + camelize(self)[1..-1]
    end
  end

  #
  # The reverse of +camelize+. Makes an underscored, lowercase form from the expression in the string.
  #
  # Changes '::' to '/' to convert namespaces to paths.
  #
  # Examples:
  #   "ActiveRecord".underscore         # => "active_record"
  #   "ActiveRecord::Errors".underscore # => active_record/errors
  #
  # Stolen from active_support
  #
  def underscore
    gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
  end

  # Tries to find a constant with the name specified in the argument string:
  #
  #   "Module".constantize     # => Module
  #   "Test::Unit".constantize # => Test::Unit
  #
  # The name is assumed to be the one of a top-level constant, no matter whether
  # it starts with "::" or not. No lexical context is taken into account:
  #
  #   C = 'outside'
  #   module M
  #     C = 'inside'
  #     C               # => 'inside'
  #     "C".constantize # => 'outside', same as ::C
  #   end
  #
  # NameError is raised when the name is not in CamelCase or the constant is
  # unknown.
  def constantize
    unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ self
      raise NameError, "#{self.inspect} is not a valid constant name!"
    end
    Object.module_eval("::#{$1}", __FILE__, __LINE__)
  end
end
