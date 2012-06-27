module Wukong
  class Dataflow < Hanuman::Graph

    def ready?
      stages.values.all?(&:ready?)
    end

    def outlink(stage, link_name)
      set_stage(stage, :output)
      links[:output] = stage
    end

    def inlink(stage, link_name)
      set_stage(stage, :input)
      stage.outlink(stages[:input], :input)
    end

    # def wire
    #   links[:input]  ||= Hanuman::StubSource
    #   links[:output] ||= Hanuman::StubSink
    # end

    # * defines the named input slot, if it doesn't exist
    # * wires the given stage to that input slot
    # * returns the named input slot
    # def input(slot_name, default_stage = nil)
    #   if not splat_inslots.include?(slot_name)
    #     slot = Hanuman::InputSlot.new(:name => slot_name, :stage => self)
    #     self.splat_inslots << slot
    #   else
    #     slot = splat_inslots[slot_name]
    #   end
    #   if default_stage.present?
    #     self.add_stage(default_stage) if not self.stages.include?(default_stage)
    #     slot.input(default_stage)
    #   end
    #   slot.input
    # end

    # def output(slot_name, default_stage = nil)
    #   if not splat_outslots.include?(slot_name)
    #     slot = Hanuman::OutputSlot.new(:name => slot_name, :stage => self)
    #     self.splat_outslots << slot
    #   else
    #     slot = splat_outslots[slot_name]
    #   end
    #   if default_stage.present?
    #     self.add_stage(default_stage) if not self.stages.include?(default_stage)
    #     slot.output(default_stage)
    #   end
    #   slot.output
    # end

    # FIXME: only handles one output slot
    # def process(rec)
    #   input(:default).output.process(rec)
    #   # stages.to_a.first.process(rec)
    # end

    # def set_output(sink)
    #   stages.to_a.last.set_output sink
    # end

    #
    # lifecycle
    #

    # def setup
    #   stages.each_value{|stage| stage.setup}
    # end

    # FIXME -- this is ugly, and evidence to  consider in the "Where does an input live" conundrum
    #   ... or it means that we're thinking about message propogation wrong.

    # def stop
    #   source_stages.each{|stage| stage.stop}
    #   process_stages.each{|stage| stage.stop}
    #   sink_stages.each{|stage| stage.stop}
    # end

    # def source_stages()  stages.to_a.select{|st| st.is_a?(Wukong::Source) }     end
    # def process_stages() stages.to_a.select{|st| (not st.is_a?(Wukong::Source)) && (not st.is_a?(Wukong::Sink)) }  end
    # def sink_stages()    stages.to_a.select{|st| st.is_a?(Wukong::Sink) }       end

    # def drive(slot_name)
    #   raise StandardError, "No source wired up input slot '#{slot_name.inspect}' of #{self.inspect} #{self.attributes}" unless has_input?(slot_name)
    #   input(slot_name).drive
    # end

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
