module Wukong
  class Runner

    # Defines methods to help a Runner class load code passed in
    # dynamically on the command-line.
    #
    # The default behavior of code in this module is to load any Ruby
    # files (ending with `.rb`) passed in the command-line.
    module CodeLoader
      
      # Loads all code, whether from a deploy pack or additionally
      # passed on the command line.
      def load_args
        (args_to_load || []).each do |path|
          load_ruby_file(path)
        end
      end

      private
      
      # Load any additional code that we found out about on the
      # command-line.
      #
      # @return [Array<String>] paths to load culled from the ARGV.
      def args_to_load
        ruby_file_args || []
      end

      # Returns all pre-resolved arguments which are Ruby files.
      #
      # @return [Array<String>]
      def ruby_file_args
        ARGV.find_all { |arg| arg.to_s =~ /\.rb$/ && arg.to_s !~ /^--/ }
      end
      
      # Loads a single Ruby file, capturing LoadError and SyntaxError
      # and raising Wukong::Error instead (so it can be easily captured
      # by the Runner).
      #
      # @param [String] path
      # @raise [Wukong::Error] if there is an error
      def load_ruby_file path
        return unless path
        begin
          Kernel.load path
        rescue LoadError, SyntaxError => e
          raise Error.new(e)
        end
      end
    end
  end
end
