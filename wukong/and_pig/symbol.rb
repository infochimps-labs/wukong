module Wukong
  module AndPig
    PIG_SYMBOLS = { }
    mattr_accessor :anon_var_idx
    self.anon_var_idx = 0
  end
end


Symbol.class_eval do
  def << relation
    case
    when relation.is_a?(Wukong::AndPig::PigVar)
      Wukong::AndPig::PigVar.new_relation(self, relation)
    when relation.is_a?(Symbol) && (pig_var = Wukong::AndPig::PIG_SYMBOLS[relation])
      Wukong::AndPig::PigVar.new_relation(self, pig_var)
    else raise "Don't know how to pigify RHS #{relation.inspect}"
    end
  end

  def method_missing method, *args
    pig_var = Wukong::AndPig::PIG_SYMBOLS[self]
    if pig_var && pig_var.respond_to?(method)
      pig_var.send(method, *args)
    else
      super method, *args
    end
  end
end
