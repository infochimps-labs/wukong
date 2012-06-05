require 'spec_helper'
require 'wukong'
require 'wukong/local_runner'

load Pathname.path_to(:examples, 'graph/minimum_spanning_tree.rb')

describe 'Minimum Spanning Tree', :examples_spec => true, :helpers => true do

  context Wukong::Widget::DisjointForest do
    subject{ Wukong::Widget::DisjointForest.new }

    context 'operations' do
      before do
        %w[ AUS DFW ATL JFK SFO LGA LAX ].each{|el| subject.add el }
        p subject
        subject.union('DFW', 'AUS')
        subject.union('ATL', 'JFK')
        subject.union('ATL', 'DFW')
      end
      
      context '#find' do
        it 'collapses elements into a shallow tree during a find' do
          subject.parent['ATL'].should == 'JFK'
          subject.parent['JFK'].should == 'AUS'
          subject.find('ATL').should == 'AUS'
          subject.parent['ATL'].should == 'AUS'
        end
      end
      context '#union' do
        it 'joins shallow tree to deep tree' do
        end
      end
    end
    
  end
end
