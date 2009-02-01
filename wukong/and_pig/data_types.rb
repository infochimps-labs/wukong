# == SimpleDataTypes ==
# int
# long
# double
# arrays
# chararray
# bytearray
#
# == ComplexDataTypes ==
# tuple
# bag
# map

module Wukong
  module AndPig
    class PigVar

    end
  end
end

class ScalarInteger  < TypedStruct.new [
    [:count,    Integer  ],
  ]
  include Wukong::AndPig::PigEmitter
  def self.load_scalar path
    var = super path
    var.to_i
  end
end
