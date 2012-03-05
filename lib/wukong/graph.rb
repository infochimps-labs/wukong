module Wukong
  registry(:source)
  registry(:sink)
  registry(:streamer)
  registry(:formatter)

  class Graph
    # a retrievable name for this graph
    attr_reader :handle
    # the sequence of stages on this graph
    attr_reader :chain

    def initialize(handle)
      @handle = handle
      @chain  = []
    end

    #
    # @example
    #   streamer(:iter, File.open('/foo/bar'))
    #
    def add_stage(type, handle=nil, *args, &block)
      stage = Wukong.create(type, handle, *args, &block)
      stage.graph = self
      @chain << stage
      stage
    end

    def source(handle=nil, *args, &block)
      add_stage(:source, handle, *args, &block)
    end

    # synonym for switch?
    def multi
    end

    def switch
    end

    def input
      chain.first
    end

    def run
      d{ self }
      input.tell(:beg_stream)
      input.run
      input.finally
      input.tell(:end_stream)
    end

  end
end
