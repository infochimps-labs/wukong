require 'active_support'
module Wukong
  class TypedStruct < Struct
    def self.unroll enum
      l_arr, r_arr = [ [] , [] ]
      enum.each{|l, r| l_arr << l ; r_arr << r}
      [ l_arr, r_arr ]
    end

    def self.new members_types
      members, mtypes = self.unroll(members_types)
      klass        = Struct.new *members
      klass.class_eval do
        cattr_accessor :mtypes, :members_types
        self.mtypes = mtypes
        self.members_types = Hash.new(members_types.flatten)
      end
      klass
    end
  end

end
