module Wukong
  class Dataflow  < Hanuman::Graph

    # FIXME: only handles one output slot
    def process(rec)
      stages.to_a.first.process(rec)
    end
    def set_output(sink)
      stages.to_a.last.set_output sink
    end

    #
    # lifecycle
    #

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

  end
end
