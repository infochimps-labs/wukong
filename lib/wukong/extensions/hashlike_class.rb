require 'wukong/extensions/class'
module Wukong

  module HashlikeClass
    module ClassMethods
      def has_members *members
        self.members ||= []
        self.members = members.map(&:to_s) + self.members
        self.members.each do |member|
          attr_accessor member.to_sym
        end
      end
      alias_method :has_member, :has_members
      def keys
        members
      end
    end

    def [](key)
      self.send(key)
    end

    def []=(key, val)
      self.send("#{key}=", val)
    end

    def self.included base
      base.class_eval do
        extend ClassMethods
        include HashLike
        class_inheritable_accessor :members

        def to_hash *args
          super(*args).merge 'type' => self.class.to_s
        end
      end
    end
  end
end
