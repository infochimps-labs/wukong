
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
