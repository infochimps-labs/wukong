require 'wukong/extensions/hash'
require 'wukong/extensions/hash_like'
require 'wukong/extensions/symbol'

#
# extensions/struct
#
# Add several methods to make a struct duck-type much more like a Hash
#
Struct.class_eval do
  include Wukong::HashLike
  def self.keys
    members
  end
end


