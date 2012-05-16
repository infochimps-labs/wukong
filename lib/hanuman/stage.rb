module Hanuman
  class Stage
    include Gorillib::Builder

    field      :name,    Symbol
    member     :input,   Hanuman::Stage, :default => ->{ Hanuman::Stage.new(:name => "#{self.name}:input") }
    member     :output,  Hanuman::Stage
    member     :owner,   Hanuman::Stage
    field      :doc,     String, :doc => 'briefly documents this stage and its purpose'

    def fullname
      [owner.try(:fullname), name].compact.join('.')
    end

    def self.handle
      Gorillib::Inflector.underscore(Gorillib::Inflector.demodulize(self.name))
    end

    #
    # Methods
    #

    # Called after the graph is constructed, before the flow is run
    def setup
    end

    # Called to signal the flow should stop. Close any open connections, flush
    # buffers, stop supervised projects, etc.
    def stop
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

    def notify(msg)
      true
    end

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
  end

  class Resource < Stage
  end
end
