module Hanuman
  class Stage
    include Gorillib::Builder

    field :name,  Symbol,         :doc => 'name for this stage; should be unique among other stages on its containing graph', :tester => true
    field :owner, Whatever,       :doc => 'the graph this stage sits in'
    # field      :doc,     String,         :doc => 'freeform description of this stage type'

    def initialize() @connections = [] ; end
    def outputs()    @connections.dup  ; end

    # @returns the stage, namespaced by the graph that owns it
    def fullname
      basename = attribute_set?(:name) ? self.name : self.class.handle
      owner.try(:determine_fullname, self) || basename
      # [owner.try(:fullname), name].compact.join('.')
    end

    def into(stage)
      @connections << stage
      stage
    end

    def self.handle
      @handle ||= Gorillib::Inflector.underscore(Gorillib::Inflector.demodulize(self.name))
    end
    
    def self.make(owner, name, *args, &block)
      stage = receive(*args)
      owner.set_stage(name, stage)
      stage.receive!(&block)
      stage
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
