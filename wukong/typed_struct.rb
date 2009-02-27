require 'active_support'
module Wukong
  module TypedStructMethods
    module ClassMethods
    end
    def self.included base
      base.extend ClassMethods
    end
  end
end

class TypedStruct < Struct
  include Wukong::TypedStructMethods
  def self.unroll enum
    l_arr, r_arr = [ [] , [] ]
    enum.each{|l, r| l_arr << l ; r_arr << r}
    [ l_arr, r_arr ]
  end

  def self.new *members_types
    members, mtypes = members_types.transpose
    klass        = Struct.new *members
    klass.class_eval do
      include Wukong::TypedStructMethods
      cattr_accessor :mtypes, :members_types
      self.mtypes = mtypes
      self.members_types = Hash.zip(members, mtypes)
    end
    klass
  end

end
