require 'spec_helper'

require 'wukong'
require 'hanuman/graphvizzer'
require 'hanuman/graphviz'

describe 'Graphviz View' do
  describe 'Cherry Pie Example', :if => GRAPHVIZ, :examples_spec => true, :helpers => true do
    it 'makes a png' do
      require Pathname.path_to(:examples, 'workflow/cherry_pie.rb')
      gv = Warrant.to_graphviz

      basename = Pathname.path_to(:tmp, 'cherry_pie')
      gv.save(basename, 'png')
      # puts File.read("#{basename}.dot")
    end
  end

  describe 'Telegram Dataflow Example', :if => GRAPHVIZ, :examples_spec => true, :helpers => true do
    it 'makes a png' do
      require Pathname.path_to(:examples, 'dataflow/telegram.rb')
      gv = ExampleUniverse.to_graphviz

      basename = Pathname.path_to(:tmp, 'telegram')
      gv.save(basename, 'png')
      # puts File.read("#{basename}.dot")
    end
  end
end
