module Wukong

  #
  # Describe a dataflow of sources, processors and sinks.
  #
  #
  class Dataflow < Hanuman::Graph

    #
    # lifecycle
    #

    def setup
      stages.each_value{|stage| stage.setup}
    end

    # FIXME -- this is ugly, and evidence to  consider in the "Where does an input live" conundrum
    #   ... or it means that we're thinking about message propogation wrong.

    def stop
      source_stages.each{|stage| stage.stop}
      process_stages.each{|stage| stage.stop}
      sink_stages.each{|stage| stage.stop}
    end

    def source_stages()  stages.to_a.select{|st| st.is_a?(Wukong::Source) }     end
    def process_stages() stages.to_a.select{|st| (not st.is_a?(Wukong::Source)) && (not st.is_a?(Wukong::Sink)) }  end
    def sink_stages()    stages.to_a.select{|st| st.is_a?(Wukong::Sink) }       end

    def drive(slot_name)
      raise StandardError, "No source wired up input slot '#{slot_name.inspect}' of #{self.inspect} #{self.attributes}" unless has_input?(slot_name)
      input(slot_name).drive
    end

    #
    # Processor helpers
    #

    def reject(re_or_block=nil, &block)
      raise ArgumentError, "Supply a block or regular expression, not both" if re_or_block && block
      if re_or_block.is_a?(Regexp)
        set_stage(Widget::RegexpRejecter.new(:pattern => re_or_block))
      else
        block ||= re_or_block
        set_stage(Widget::ProcRejecter.new(block))
      end
    end

    def select(re_or_block=nil, &block)
      raise ArgumentError, "Supply a block or regular expression, not both" if re_or_block && block
      if re_or_block.is_a?(Regexp)
        set_stage(Widget::RegexpFilter.new(:pattern => re_or_block))
      else
        block ||= re_or_block
        set_stage(Widget::ProcFilter.new(block))
      end
    end

  end
end
