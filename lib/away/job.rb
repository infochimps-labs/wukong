module Wukong
  #
  #
  #
  #
  class Job < Wukong::Graph
    # invokable resources
    attr_reader :resources

    def to_s
      ['<job', handle,
        "resources={#{resources.join(' | ')}}",
        "chain={#{chain.join(' | ')}}",
      ].join(' ')+'>'
    end


    def add_resource(type, handle=nil, *args, &block)
      rsrc = Wukong.create(type, handle, *args, &block)
      rsrc.graph = self
      @resources << rsrc
      rsrc
    end

  end

  module Task
    extend Gorillib::Concern
    include Wukong::Stage

    module ClassMethods
      def define_action(name, options={}, &block)
        self.actions = self.actions.merge(name => options.merge(:block => block))
      end

      def class_defaults
        super
        # field :actions,     Array, :of => Symbol, :description => 'list of actions this stage responds to'
        class_attribute :actions
        self.actions ||= Hash.new
        class_attribute :default_action

        define_action :nothing, :description => 'ze goggles, zey do nussing'
      end

    end
    included do
      self.class_defaults
    end
  end

  def self.job(handle, *args, &block)
    @jobs ||= Hash.new
    @jobs[handle] ||= Job.new(handle, *args, &block)
  end
end
