module Enumerable
  #
  # Convert an array of values to a string representing it as a pig tuple
  #
  def to_pig_tuple
    map{|*vals| '(' + vals.join(',') + ')' }
  end

  #
  # Convert an array of values to a string pig format
  # Delegates to to_pig_tuple -- see also to_pig_bag
  #
  def to_pig *args
    to_pig_tuple *args
  end

  #
  # Convert an array of values to a string representing it as a pig bag
  #
  def to_pig_bag
    '{' + self.join(',') + '}'
  end
end
