module Hanuman
  class Stage
    include Gorillib::FancyBuilder

    field      :doc,      String, :doc => 'briefly documents this stage and its purpose'
    field      :summary,  String, :doc => 'a long-form description of the stage'
    collection :inputs,   Hanuman::Stage
    collection :outputs,  Hanuman::Stage
    belongs_to :owner,    Hanuman::Stage

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

    def report
      {}
    end

  end
end
