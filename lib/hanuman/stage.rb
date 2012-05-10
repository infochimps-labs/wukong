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
    end

    def stop
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

    # def to_s
    #   "<~" + [
    #     self.class.handle,
    #     self.instance_variables.reject{|iv| iv.to_s =~ /^@(graph|next_stage|prev_stage)$/ }.map{|iv| "#{iv}=#{self.instance_variable_get(iv)}"  },
    #     ].flatten.compact.join(" ") + "~>"
    # end
  end
end
