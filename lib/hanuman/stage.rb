module Hanuman
  class Stage
    include Gorillib::Builder

    # field      :name,    Symbol,         :doc => 'name for this stage; should be unique among other stages on its containing graph', :tester => true
    member     :owner,   Whatever,       :doc => 'the graph this stage sits in'
    field      :doc,     String,         :doc => 'freeform description of this stage type'

    # @returns the stage, namespaced by the graph that owns it
    def fullname
      [owner.fullname, name].compact.join('.')
    end

    def self.handle
      @handle ||= Gorillib::Inflector.underscore(Gorillib::Inflector.demodulize(self.name))
    end
    
    def name
      owner.stages.invert[self]
    end
    
    #
    # Methods
    #
    # def lookup(stage)
    #   owner.lookup(stage)
    # end

    # #
    # # Graph connections
    # #

    # def notify(msg)
    #   true
    # end

    # def report
    #   self.attributes
    # end

    # def to_key()      name   ; end
    # def key_method() :name ; end
  end
end
