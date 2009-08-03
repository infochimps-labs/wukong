require 'extlib/object'
require 'extlib/module'

# Module.module_eval do
#   # Tries to find a constant with the name specified in the argument string:
#   #
#   #   "Module".constantize     # => Module
#   #   "Test::Unit".constantize # => Test::Unit
#   #
#   # The name is assumed to be the one of a top-level constant, no matter whether
#   # it starts with "::" or not. No lexical context is taken into account:
#   #
#   #   C = 'outside'
#   #   module M
#   #     C = 'inside'
#   #     C               # => 'inside'
#   #     "C".constantize # => 'outside', same as ::C
#   #   end
#   #
#   # NameError is raised when the name is not in CamelCase or the constant is
#   # unknown.
#   def constantize const_name
#     unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ const_name
#       raise NameError, "#{self.inspect} is not a valid constant name!"
#     end
#     self.module_eval("#{$1}", __FILE__, __LINE__)
#   end
# end
