#
# h2. extensions/array.rb
#
# Extensions to the +Array+ class.
#
class Array
  def in_groups_of(number, fill_with = nil, &block)
    require 'enumerator'
    collection = dup
    collection << fill_with until collection.size.modulo(number).zero?
    collection.each_slice(number, &block)
  end
end
