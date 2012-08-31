require 'wukong/parser/flatpack_parser'

module Wukong
  module Streamer
    class FlatPackStreamer < Wukong::Streamer::Base
      
      def self.format format
        @@parser = Wukong::Parser::FlatPack.create_parser format
      end
      
      def recordize line
        @@parser.parse line
      end
    end
  end
end
