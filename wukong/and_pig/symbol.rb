
Symbol.class_eval do
  def << relation
    case relation
    when Wukong::AndPig::PigVar
      Wukong::AndPig::PigVar.new_relation(self, relation)
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
