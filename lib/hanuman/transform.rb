
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
      when Wukong.streamer_exists?(pred) then pred
      when pred.respond_to?(:match)  then Wukong::Filter::RegexpFilter.new(pred)
      when pred.is_a?(Proc)          then Wukong::Filter::ProcFilter.new(pred)
      else raise "Can't create a filter from #{pred.inspect}"
      end
    end

    def self.reject(pred=nil, &block)
      pred ||= block
      case
      when Wukong.streamer_exists?(pred) then pred
      when pred.respond_to?(:match)  then Wukong::Filter::RegexpRejecter.new(pred)
      when pred.is_a?(Proc)          then Wukong::Filter::ProcRejecter.new(pred)
      else raise "Can't create a filter from #{pred.inspect}"
      end
    end
