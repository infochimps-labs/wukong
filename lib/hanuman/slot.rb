#
# Slot holds the
#
class Slot < Gorillib::Collection
  attr_reader :connections

  def initialize
    @connections = Hash.new{|h,k| h[k] = [] }
  end

  def names
    clxn.keys
  end

  def schemas
    clxn.values
  end

  def schema(name)
    s
  end
end
