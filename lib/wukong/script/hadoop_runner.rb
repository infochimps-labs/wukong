module Wukong
  module Script
    module HadoopRunner
      extend self
      
      def run *args
        Gorillib::System::Runner.run('hadoop', args: args)
      end
    end
  end
end
