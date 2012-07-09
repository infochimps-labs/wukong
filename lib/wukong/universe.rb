module Wukong

  #
  # Holds graphs, supplies `processor` and similar stage template methods
  #
  module Universe
    extend Gorillib::Concern

    def graph_id() nil ; end

    def find_or_create_class(klass_name, superklass, namespace, &block)
      klass_name = Gorillib::Inflector.camelize(klass_name.to_s).to_sym
      if namespace.const_defined?(klass_name)
        namespace.const_get(klass_name)
      else
        namespace.send(:const_set, klass_name, Class.new(superklass, &block))
      end
    end

    def processor(processor_name, superklass=Wukong::Processor, &block)
      klass = find_or_create_class(processor_name, superklass, Wukong::Widget) do
        register_processor(processor_name)
      end
      klass.class_eval(&block) if block_given?
      klass
    end

    def dataflow(name, attrs={}, &block)
      attrs[:_type] ||= Wukong::Dataflow
      @dataflows.update_or_add(name, attrs.merge(name: name), &block)
    end

    def chain(name, attrs={}, &block)
      attrs[:_type] ||= Wukong::Chain
      dataflow(name, attrs, &block)
    end

    def workflow(name, attrs={}, &block)
      attrs[:name] = name = name.to_sym
      workflow = @workflows[name] ||= Workflow.new(name: name, owner: self)
      workflow.receive!(attrs, &block)
      workflow
    end

    def self.extended(base)
      base.instance_eval do
        @dataflows = Hanuman::StageCollection.new(self)
        @workflows = Hash.new
      end
    end
  end

  # Wukong can serve as a universe
  extend Universe
end
