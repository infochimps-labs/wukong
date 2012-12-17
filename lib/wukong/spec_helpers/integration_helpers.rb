module Wukong
  module SpecHelpers
    
    # This module defines methods that are helpful to use in
    # integration tests which require reading files from the local
    # repository.
    #
    # 
    module IntegrationHelpers

      def lib_dir *args
        root.join('lib', *args)
      end

      def bin_dir *args
        root.join('bin', *args)
      end
      
      def examples_dir *args
        root.join('examples', *args)
      end

      def integration_env
        {
          "PATH"    => [bin_dir.to_s, ENV["PATH"]].compact.join(':'),
          "RUBYLIB" => [lib_dir.to_s, ENV["RUBYLIB"]].compact.join(':')
        }
      end

      def integration_cwd
        root.to_s
      end

      def example_script *args
        examples_dir(*args)
      end

    end
  end
end
