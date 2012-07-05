require 'spec_helper'
require 'wukong'

# Hanuman::Graph.class_eval do
#   def foo_graph(label, &block)
#     stage(label, :_type => Hanuman::FooGraph, &block)
#   end
# end
# class Hanuman::FooGraph < Hanuman::Graph
#   # field      :inputs,  Gorillib::Collection, :of => Hanuman::InputSlot,  :doc => 'inputs to this stage',  :default => ->{ Gorillib::Collection.new }
#   # field      :outputs, Gorillib::Collection, :of => Hanuman::OutputSlot, :doc => 'outputs of this stage', :default => ->{ Gorillib::Collection.new }
#
#   collection   :inputs, Hanuman::InputSlot
#
# end

describe 'example', :examples_spec do
  # describe_example_script(:simple, 'dataflow/simple.rb', :only => true) do
  #   it 'runs' do
  #     p subject
  #   end
  # end

  it 'runs' do
    # load Pathname.path_to(:examples, 'dataflow/simple.rb')

    Wukong.dataflow(:bob) do
      ff = file_source(Pathname.path_to(:data, 'text/jabberwocky.txt')){ p self }


    end

  end
end
