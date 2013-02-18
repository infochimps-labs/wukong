require_relative 'command'

module Wukong
  module Script
    module HadoopRunner
      extend self
      def run args, opts
        cmd = ['hadoop'] + args
        Gorillib::System::Runner.run(cmd,opts)
      end
    end
  end
end
