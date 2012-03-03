module Wukong
  registry(:source)
  registry(:sink)
  registry(:streamer)
  registry(:formatter)

  class Stage

    # stage to receive emitted messages
    attr_reader :next_stage

    # invoked on each record in turn
    # override this in your subclass
    def call(record)
    end

    def start
    end

    # passes a record on down the line
    def emit(record, status=nil, headers={})
      next_stage.call(record) if next_stage
    end

    # called at the end of a run
    def finally
      next_stage.finally if next_stage
    end

    def tell(event, *info)
      if respond_to?(event)
        self.send(event, *info)
      elsif next_stage
        next_stage.tell(event, *info)
      else
        warn("No next_stage set for #{self}")
        return
      end
    end

    #
    # Graph connections
    #

    def into(stage=nil, &block)
      stage ||= block
      stage = Wukong.make_streamer(:map, stage) if stage.is_a?(Proc)
      @next_stage = stage
    end

    def |(*args, &block)
      into(*args, &block)
    end

    #
    # Graph Sugar
    #

    def select(pred=nil, &block)
      self.into(Wukong::Stage.select(pred, &block))
    end

    def reject(pred=nil, &block)
      self.into(Wukong::Stage.reject(pred, &block))
    end

    def self.select(pred=nil, &block)
      pred ||= block
      case
      when Wukong.has_streamer?(pred) then pred
      when pred.respond_to?(:match)  then Wukong::Filter::RegexpFilter.new(pred)
      when pred.is_a?(Proc)          then Wukong::Filter::ProcFilter.new(pred)
      else raise "Can't make a filter from #{pred.inspect}"
      end
    end

    def self.reject(pred=nil, &block)
      pred ||= block
      case
      when Wukong.has_streamer?(pred) then pred
      when pred.respond_to?(:match)  then Wukong::Filter::RegexpRejecter.new(pred)
      when pred.is_a?(Proc)          then Wukong::Filter::ProcRejecter.new(pred)
      else raise "Can't make a filter from #{pred.inspect}"
      end
    end

    #
    # Assembly -- find and identify by handle
    #

    def self.handle
      self.to_s.demodulize.underscore.to_sym
    end

    class << self
      # # gets class for given streamer
      # def klass_for(type, handle)
      #   @@registry[type][handle]
      # end

      # # returns a new instance of given type
      # def make(type, klass, *args, &block)
      #   klass = klass_for(type, klass) unless klass.is_a?(Class)
      #   if not klass
      #     raise "Can't make '#{type}' '#{klass}': registry #{all.inspect}"
      #   end
      #   klass.new(*args, &block)
      # end

      # def has(type, obj)
      #   all[type].has_value?(obj)
      # end

    end

  end
end
