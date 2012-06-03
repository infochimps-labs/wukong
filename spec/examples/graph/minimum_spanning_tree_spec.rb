require 'spec_helper'
require 'wukong'
require 'wukong/local_runner'

load Pathname.path_to(:examples, 'graph/minimum_spanning_tree.rb')

describe 'Minimum Spanning Tree', :examples_spec => true, :helpers => true do

  context Wukong::Widget::UnionFind do
    subject{ Wukong::Widget::UnionFind.new }
    it '' do
    end
  end

end
