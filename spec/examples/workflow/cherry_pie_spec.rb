require 'spec_helper'
require 'wukong'
require 'wukong/local_runner'

load Pathname.path_to(:examples, 'workflow/cherry_pie.rb')

describe 'Cherry Pie Example', :examples_spec => true, :helpers => true do

  it 'makes a png' do
    gv = Wukong.workflow(:cherry_pie).to_graphviz

    gv.save(Pathname.path_to(:tmp, gv.name.to_s), 'png')
    puts File.read(Pathname.path_to(:tmp, "#{gv.name}.dot"))
  end

end
