require 'active_support'

class TypedStruct < Struct
  def self.new *members_types
    members, mtypes = members_types.transpose
    klass           = Struct.new *members
    klass.class_eval do
      cattr_accessor :mtypes, :members_types
      self.mtypes        = mtypes
      self.members_types = Hash.zip(members, mtypes)
    end
    klass
  end
end
