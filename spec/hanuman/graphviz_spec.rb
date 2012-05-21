require 'spec_helper'

require 'wukong'
require 'hanuman/graphvizzer'
require 'hanuman/graphviz'

describe 'Graphviz View' do

  can_run_graphviz = false
  begin
    result = `dot -V 2>&1`
    can_run_graphviz = ($?.to_i == 0) && (result =~ /dot - graphviz version/)
  rescue StandardError
  end


  if can_run_graphviz

    describe 'Cherry Pie Example', :examples_spec => true, :helpers => true do
      it 'makes a png' do
        require Pathname.path_to(:examples, 'workflow/cherry_pie.rb')
        gv = Warrant.to_graphviz

        basename = Pathname.path_to(:tmp, 'cherry_pie')
        gv.save(basename, 'png')
        # puts File.read("#{basename}.dot")
      end
    end

    describe 'Telegram Dataflow Example', :examples_spec => true, :helpers => true do
      it 'makes a png' do
        require Pathname.path_to(:examples, 'dataflow/telegram.rb')
        gv = TelegramUniverse.to_graphviz

        basename = Pathname.path_to(:tmp, 'telegram')
        gv.save(basename, 'png')
        # puts File.read("#{basename}.dot")
      end
    end

  else
    it 'requires graphviz -- brew/apt install graphviz, it is pretty awesome'
  end
end
