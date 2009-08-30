# require 'active_support/core_ext/class/inheritable_attributes.rb'
require 'extlib/class'

module Wukong
  #
  # Use to instrument an actual class to behave
  #
  module WukongClass


    def [](attr)
      self.send attr
    end
    def []=(attr, val)
      self.send("#{attr}=", val)
    end

  end


end
