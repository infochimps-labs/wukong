module Wukong
  class Source < Processor

    class Stdin < Source
      def process
        while line = $stdin.readline.chomp! rescue nil
          yield line
        end
      end
      register
    end    

  end
end
