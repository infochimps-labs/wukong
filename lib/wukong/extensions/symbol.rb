#
# h2. extensions/symbol.rb -- extensions to symbol class
#
class Symbol
  #
  # Turn the symbol into a simple proc (stolen from
  # <tt>ActiveSupport::CoreExtensions::Symbol</tt>).
  def to_proc
    Proc.new { |*args| args.shift.__send__(self, *args) }
  end unless method_defined?(:to_proc)
end
