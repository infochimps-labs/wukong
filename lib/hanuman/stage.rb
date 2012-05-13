module Hanuman
  class Stage
    include Gorillib::Builder

    field      :name,     Symbol
    collection :inputs,   Hanuman::Stage
    member     :output,   Hanuman::Stage, :default => ->(){ Stage.new("out") }
    member     :owner,    Hanuman::Stage
    field      :doc,      String, :doc => 'briefly documents this stage and its purpose'

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

    def input(stage_name, stage=nil)
      stage ||= (owner||self).stage(stage_name)
      obj = super(stage_name, stage)
      obj.output(self) if obj
      obj
    end

    def <<(stage)
      input(stage.name, stage)
      self
    end

    def >(stage)
      # owner.stage(stage.name, stage) if owner
      st = output(stage)
      p ['out', self, stage, st]
      st
    end

    def fullname
      [owner.try(:fullname), name].compact.join('.')
    end

    def notify(msg)
      true
    end

    def inspect(detailed=true)
      str = "#<%-18s %-18s" % [self.class.name, fullname]
      attr_names = self.class.field_names - [:name]
      if detailed && attr_names.present?
        str << " " << attr_names.map{|attr| "#{attr}=#{inspect_attr(attr)}" }.join(", ")
      end
      str << ">"
    end

    def tree(options={})
      { :name => name,
        :inputs => inputs.to_a.map{|input| input.name },
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
