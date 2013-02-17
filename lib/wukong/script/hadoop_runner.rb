require_relative 'command'

module Wukong
  module Script
    module HadoopRunner
      extend self
      def run *args
        Gorillib::System::Runner.run('hadoop', *args)
      end
    end
  end
end
