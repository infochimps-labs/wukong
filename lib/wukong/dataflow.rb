module Wukong

  # class Dataflow
  class Dataflow  < Hanuman::Graph
    # # FIXME: dummying out minimal locked-down interface for the moment
    # include Gorillib::Model
    # field :stages, Array
    #
    # def initialize(&block)
    #   self.stages = []
    #   instance_exec(&block) if block
    # end
    # # /FIXME

    def process(rec)
      stages.to_a.first.process(rec)
    end

    # FIXME: only handles one output slot
    def set_output(sink)
      stages.to_a.last.set_output :_, sink
    end

    def setup
      stages.each_value{|stage| stage.setup}
    end

    def stop
      stages.each_value{|stage| stage.stop}
    end

    #
    # Processor helpers
    #

    def reject(re_or_block=nil, &block)
      raise ArgumentError, "Supply a block or regular expression, not both" if re_or_block && block
      if re_or_block.is_a?(Regexp)
        add_stage(Widget::RegexpRejecter.new(:re => re_or_block))
      else
        block ||= re_or_block
        add_stage(Widget::ProcRejecter.new(block))
      end
    end

    def select(re_or_block=nil, &block)
      raise ArgumentError, "Supply a block or regular expression, not both" if re_or_block && block
      if re_or_block.is_a?(Regexp)
        add_stage(Widget::RegexpFilter.new(:re => re_or_block))
      else
        block ||= re_or_block
        add_stage(Widget::ProcFilter.new(block))
      end
    end

    def self.register_processor(name, klass=nil, &meth_body)
      name = name.to_sym
      raise ArgumentError, 'Supply either a processor class or a block' if (klass && meth_body) || (!klass && !meth_body)
      if block_given?
        define_method(name) do |*args, &blk|
          add_stage meth_body.call(*args, &blk)
        end
      else
        define_method(name) do |*args, &blk|
          add_stage klass.new(*args, &blk)
        end
      end
    end
  end
end
