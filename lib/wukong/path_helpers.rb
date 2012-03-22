# TODO: this should be part of configliere

require 'gorillib/metaprogramming/delegation'
require 'pathname'

module Wukong

  class Pathref < ::Pathname
    ROOT_PATHS = Hash.new unless defined?(ROOT_PATHS)

    def initialize(*pathsegs)
      raise ArgumentError, 'wrong number of arguments(0 for 1)' if pathsegs.empty?
      pathsegs = pathsegs.map{|ps| self.class.expand_pathseg(ps) }.flatten
      dir = pathsegs.shift
      super(File.expand_path(File.join(*pathsegs), dir))
    end

    def /(pathseg)
      self.join(pathseg)
    end

    class << self
      # TODO: does nothing with the options
      def register_path(handle, pathsegs, options={})
        ROOT_PATHS[handle] = Array(pathsegs)
      end

      def path_to(*pathsegs)
        self.new(*pathsegs)
      end

      def expand_pathseg(handle)
        return handle unless handle.is_a?(Symbol)
        pathsegs = ROOT_PATHS[handle] or raise ArgumentError, "Don't know how to expand path reference '#{handle.inspect}'."
        pathsegs.map{|ps| expand_pathseg(ps) }.flatten
      end
    end
  end

  singleton_class.class_eval{ delegate :path_to, :register_path, :to => Pathref }
end
