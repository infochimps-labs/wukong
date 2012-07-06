require 'spec_helper'
require 'wukong'

require 'hanuman/graphvizzer/gv_presenter'

describe 'cherry_pie' do

  # it 'fiddles' do
  #   load(Pathname.path_to(:examples, 'workflow/cherry_pie.rb'))
  #   Wukong.workflow(:cherry_pie) do
  #     Log.dump self
  #
  #     graph(:crust) do
  #       Log.dump self
  #       action(:bob)
  #     end
  #
  #     Log.dump graph(:crust)
  #
  #   end
  # end


  describe 'Graphviz View', :if => GRAPHVIZ do
    it 'makes a png' do
      require Pathname.path_to(:examples, 'workflow/cherry_pie.rb')

      gv = Wukong.to_graphviz

      basename = Pathname.path_to(:tmp, 'cherry_pie')
      gv.save(basename, 'png')
      puts File.read("#{basename}.dot")
    end
  end

end
