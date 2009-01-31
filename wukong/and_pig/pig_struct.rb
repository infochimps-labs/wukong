

Struct.class_eval do
  def self.pig_load filename
    PigVar.load filename, self
  end

  def self.relationize
    self.to_s
  end

  def self.members_types
    members
  end
end
