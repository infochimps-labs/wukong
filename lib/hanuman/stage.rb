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
      input(stage.name, stage.attributes)
    end

    def >(stage)
      output(stage.name, stage.attributes)
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
end
