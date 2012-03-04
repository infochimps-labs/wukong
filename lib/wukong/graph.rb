module Wukong
  class Graph
    # a retrievable name for this graph
    attr_reader :handle

    def initialize(handle)
      @handle = handle
    end

    #
    # @example
    #   streamer(:iter, File.open('/foo/bar'))
    #
    def stage(type, handle=nil, *args, &block)
      self.class.find_or_create(type, handle, *args, &block)
    end

    def source(handle=nil, *args, &block)
      stage(:source, handle, *args, &block)
    end

    # synonym for switch?
    def multi
    end

    def switch
    end


    def run(handle)
      source.tell(:beg_stream)
      source.run
      source.finally
      source.tell(:end_stream)
    end

  end
end
