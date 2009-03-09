require 'active_support/core_ext/array/extract_options.rb'
#
# h2. extensions/array.rb
#
# Extensions to the +Array+ class.
#
class Array
  # Needed for cattr_accessor
  include ActiveSupport::CoreExtensions::Array::ExtractOptions
end
