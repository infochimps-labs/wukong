module Hanuman
  class Stage
    include Gorillib::FancyBuilder

    collection :inputs,   Hanuman::Stage
    collection :outputs,  Hanuman::Stage
    belongs_to :owner,    Hanuman::Stage
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

    def <<(stage)
      owner.stage(stage.name, stage.attributes) if owner
      input(stage.name, stage.attributes)
    end

    def >(stage)
      owner.stage(stage.name, stage.attributes) if owner
      output(stage.name, stage.attributes)
    end

    def output(stage)
      obj = super
      owner.stages << obj if owner.respond_to?(:stages)
      p [:output, self, obj, self.try(:stages)]
      obj
    end

    def notify(msg)
      true
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
  end

  class Resource < Stage
  end
end
