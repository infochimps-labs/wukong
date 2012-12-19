require_relative 'stdio_driver'
require_relative 'tcp_driver'

module Wukong
  module Local

    # Implements the Runner for wu-local.
    class Runner < Wukong::Runner
      
      usage "PROCESSOR|FLOW"
      
      description <<EOF
 wu-local is a tool for running Wukong processors and flows locally on
 the command-line.  Use wu-local by passing it a processor and feeding
 in some data:

   $ echo 'UNIX is Clever and Fun...' | wu-local tokenizer.rb
   UNIX
   is
   Clever
   and
   Fun

 If your processors have named fields you can pass them in as
 arguments:

   $ echo 'UNIX is clever and fun...' | wu-local tokenizer.rb --min_length=4
   UNIX
   Clever

 You can chain processors and calls to wu-local together:

   $ echo 'UNIX is clever and fun...' | wu-local tokenizer.rb --min_length=4 | wu-local downcaser.rb
   unix
   clever

 Which is a good way to develop a combined data flow which you can
 again test locally:

   $ echo 'UNIX is clever and fun...' | wu-local tokenize_and_downcase_big_words.rb
   unix
   clever
EOF

      # The processor we're going to run.
      attr_accessor :processor

      # Extracts the processor from the arguments.
      #
      # Will accept
      #
      # * the name of an already registered processor
      # * a Ruby file
      def evaluate_args
        arg      = args.first
        basename = File.basename(arg.to_s, '.rb')
        case
        when settings.run
          self.processor = settings.run
        when arg.nil?
          raise Error.new(settings.help)
        when Wukong.registry.registered?(arg.to_sym)
          self.processor = arg.to_sym
        when File.exist?(arg) && Wukong.registry.registered?(basename.to_sym)
          self.processor = basename.to_sym
        when File.exist?(arg) && (! Wukong.registry.registered?(basename.to_sym))
          raise Error.new("File #{arg} does not register a processor named <#{basename}>")
        when arg
          raise Error.new("No processor named <#{arg}>")
        else
          raise Error.new("Did not choose a processor to run via the first argument or an explicit --run param.")
        end     
      end

      # Runs either the StdioDriver or the TCPDriver, depending on
      # what settings were passed.
      def run
        EM.run do 
          (settings.tcp_server ? TCPDriver : StdioDriver).start(processor, settings)
        end
      end
    end
  end
end
