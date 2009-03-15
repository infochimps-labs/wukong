require 'rubygems'
require 'active_support'

String.class_eval do
  #
  # Generate relation name from a handle
  #
  def relationize() camelize end
end
Symbol.class_eval do
  #
  # Generate relation name from a handle
  #
  def relationize
    to_s.relationize
  end
end

Object.class_eval do
  def typify() self.class ; end

  def symbolize
    self.to_s.underscore.gsub(%r{.*/}, '').to_sym
  end
end

class << Integer ; def typify() 'int'           end ; end
class << Bignum  ; def typify() 'long'          end ; end
class << Float   ; def typify() 'float'         end ; end
class << String  ; def typify() 'chararray'     end ; end
class << Symbol  ; def typify() self            end ; end
class << Date    ; def typify() 'long'          end ; end

# Array.class_eval do
#   def typify()
#     "{ #{ map{|f,t| "#{f}: #{t.typify}"} } }"
#   end
# end
# class Tuple
#   attr_accessor :contents
#   def initialize *args
#     self.contents = args
#   end
#   def typify
#     "bag { #{ contents.map{|f,t| "#{f}: #{t.typify}"} } }"
#   end
#   #
#   # Sugar for creating a new bag. The following are equivalent:
#   #
#   #   Bag[:foo]
#   #   Bag.new :foo
#   #
#   def self.[] *args
#     new *args
#   end
# end

module BagMethods
  module ClassMethods
    #
    # Pig type string --
    # the pig type strings for each sub-element.
    #
    def typify
      vars_str = members.zip(mtypes).map do |attr, mtype|
        "%s: %s" % [attr, mtype.typify]
      end
      "{ #{vars_str.join(', ')} }"
    end
  end
  def self.included base
    base.extend ClassMethods
  end
end

class Bag < TypedStruct
  def self.new *args
    bag = super *args
    bag.class_eval{ include BagMethods }
  end
  def self.[] *args
    new *args
  end
end

