class AS
  attr_accessor :expr, :name, :type, :ref
  def new expr, name=nil, type=nil, ref=nil
    self.expr = expr
    self.name = name
    self.type = type
    self.ref  = ref
  end

  def to_s
    clause  = "%-32s" % [ref, expr].compact.join('::')
    if name
      clause << "AS #{name}"
      clause << ": #{type}" if type
    end
    clause
  end

  def self.[] *args
    self.new *args
  end

  # Useful for feeding back into TypedStruct
  def name_type
    [name, type]
  end
end
