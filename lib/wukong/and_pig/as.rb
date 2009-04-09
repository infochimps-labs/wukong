class AS
  attr_accessor :expr, :name, :type, :ref, :options
  def initialize expr, name=nil, type=nil, ref=nil, *option_flags
    case expr
    when AS
      self.expr = expr.expr
      self.name = expr.name
      self.type = expr.type
      self.ref  = expr.ref
      self.options = expr.options
    end
    self.expr ||= expr
    self.name = name if name
    self.type = type if type
    self.ref  = ref  if ref
    self.options ||= { }
    option_flags.each{|option| self.options[option] = true }
  end

  def to_s
    clause  = "%-30s \t" % [ref, expr].compact.join('::')
    if name
      clause << "AS #{name}"      unless options[:skip_name]
      clause << ":#{type.typify}" unless ((!type) || options[:skip_type])
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
