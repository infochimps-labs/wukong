module Wukong
  module Streamer
    module PreprocessWithPipeStreamer
      #
      # Runs STDIN through a shell command and then begins processing.
      #
      # If you don't need to do anything to the output of the command, just
      # inherit from Wukong::Script and override the #map_command.
      #
      # You must provide a @preprocess_pipe_command@ method that returns a shell
      # command to run the input through.
      #
      def stream
        #
        `#{preprocess_pipe_command}`.each do |line|
          item = itemize(line) ; next if item.blank?
          process(*item)
        end
      end
    end
  end
end
