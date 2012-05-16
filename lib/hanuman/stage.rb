module Hanuman
  class Stage
    include Gorillib::Builder

    field      :name,    Symbol
    member     :input,   Hanuman::Stage, :default => ->{ Hanuman::Stage.new(:name => "#{self.name}:input") }
    member     :output,  Hanuman::Stage
    member     :owner,   Hanuman::Stage
    field      :doc,     String, :doc => 'briefly documents this stage and its purpose'

    #
    # Methods
    #

    def setup
      true
    end

    def stop
      true
    end

    #
    # Graph connections
    #

    def <<(stage)
      stage.output(self)
      self
    end

    def >(stage)
      output(stage)
      stage
    end

    def fullname
      [owner.try(:fullname), name].compact.join('.')
    end

    def notify(msg)
      true
    end

    # def inspect(detailed=true)
    #   str = "#<%-18s %-18s" % [self.class.name, fullname]
    #   attr_names = self.class.field_names - [:name]
    #   if detailed && attr_names.present?
    #     str << " " << attr_names.map{|attr| "#{attr}=#{inspect_attr(attr)}" }.join(", ")
    #   end
    #   str << ">"
    # end

    def tree(options={})
      { :name => name,
        :input => input.name,
      }
    end

    def report(options={})
      tree(options)
    end

  end

  class Action < Stage
    def output(*args)
      super || owner.stage(:"#{self.name}_out")
    end
  end

  class Resource < Stage
  end
end
