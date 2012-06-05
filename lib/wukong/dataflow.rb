module Wukong

  #
  # Describe a dataflow of sources, processors and sinks.
  #
  #
  class Dataflow < Hanuman::Graph
    include Hanuman::SplatInputs
    include Hanuman::SplatOutputs

    # * defines the named input slot, if it doesn't exist
    # * wires the given stage to that input slot
    # * returns the named input slot
    def input(slot_name, default_stage = nil)
      if not splat_inslots.include?(slot_name)
        slot = Hanuman::InputSlot.new(:name => slot_name, :stage => self, :input => default_stage)
        self.splat_inslots << slot
      else
        slot = splat_inslots[slot_name]
      end
      slot.input
    end

    def output(slot_name, default_stage = nil)
      if not splat_outslots.include?(slot_name)
        slot = Hanuman::OutputSlot.new(:name => slot_name, :stage => self, :output => default_stage)
        self.splat_outslots << slot
      else
        slot = splat_outslots[slot_name]
      end
      slot.output
    end

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
        add_stage(Widget::RegexpRejecter.new(:pattern => re_or_block))
      else
        block ||= re_or_block
        add_stage(Widget::ProcRejecter.new(block))
      end
    end

    def select(re_or_block=nil, &block)
      raise ArgumentError, "Supply a block or regular expression, not both" if re_or_block && block
      if re_or_block.is_a?(Regexp)
        add_stage(Widget::RegexpFilter.new(:pattern => re_or_block))
      else
        block ||= re_or_block
        add_stage(Widget::ProcFilter.new(block))
      end
    end

  end
end
