module Enumerable
  #
  # Convert an array of values to a string representing it as a pig tuple
  #
  def to_pig_tuple
    '(' + self.join(',') + ')'
  end

  #
  # Convert an array of values to a string pig format
  # see also to_pig_bag
  #
  def to_pig *args
    to_pig_tuple *args
  end

  #
  # Convert an array of values to a string representing it as a pig bag
  #
  def to_pig_bag
    '{' + self.map{|*vals| vals.to_pig_tuple}.join(",") + '}'
  end

  #
  # Convert a string representing a pig bag into a nested array
  #
  def from_pig_bag
    self.split("),(").map{|t| t.gsub(/[\{\}]/, '').from_pig_tuple} rescue []
  end

  #
  # Convert a string representing a pig tuple into an array
  #
  def from_pig_tuple
    self.gsub(/[\(\)]/, '').split(',')
  end

end
