#!/usr/bin/env ruby
$LOAD_PATH.push(File.expand_path('../../../lib', File.dirname(__FILE__)))

require 'wukong'
require 'set'

module AllNeighborhoods
  class Mapper < Wukong::Streamer::RecordStreamer

    def recordize line
      line = line.split "\t"
      line[2] = (line[2] == '1')
      line[3] = (line[3] == '1')
      line[4] = (line[4] == '1')
    end

    def process(line)
      if line[2]
        yield line[0..1]
      end
      if line[3]
        yield [line[1],line[0]]
      end
    end
  end

  class Reducer < Wukong::Streamer::AccumulatingReducer
    attr_accessor :neighbors 
    
    def start! *args
      self.neighbors = Set.new   
    end

    def accumulate *args
      self.neighbors <<  args[1]
    end

    def finalize
      yield [key] + self.neighbors.to_a
    end
  end
end

Wukong::Script.new(
  AllNeighborhoods::Mapper,
  AllNeighborhoods::Reducer,
).run
