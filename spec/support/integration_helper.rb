module Wukong
  module Local
    module IntegrationHelper

      def root
        @root ||= Pathname.new(File.expand_path('../../..', __FILE__))
      end

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
