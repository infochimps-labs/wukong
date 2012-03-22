module Wukong

  def self.chain(name, &block)
    Wukong::Chain.new(name, &block)
  end
  
  module Stage
    extend ActiveSupport::Concern
    
    module ClassMethods
    end

    def actions
      self.class.actions
    end

    def run_action(action, *args)
      self.instance_exec(*args, &actions[action][:block])
    end
  end

  class Job < Wukong::Graph

    def cooking_container(*args)
      p self
      add_a_stage(:task, :container, *args)
    end
  end
end

module Kitchen
  class Ingredient
    include Wukong::Stage
    #
    attr_reader :name
    attr_reader :quantity
    def initialize(name, quantity)
      @name     = name
      @quantity = quantity
    end
    def to_s
      "#{quantity} #{name}"
    end
  end

  class Container
    include Wukong::Stage
    Wukong.register_task(self)
    #
    attr_reader :contents
    attr_reader :name
    #
    def initialize(name)
      @name     = name
      @contents = []
    end
    def to_s()
      [ name,
        contents.blank? ? "(empty)" : "with #{contents.join(", ")}"
      ].join(" ")
    end

    define_action :add do |ingredient|
      contents << ingredient
    end
  end

  class MixingBowl < Container
  end

  class PieTin < Container
  end

  class Utensil
  end

  class Mixer < Utensil
    def mix(container)
      puts "mixed the contents of #{container}"
    end
  end

end
