require File.expand_path('../spec_helper', File.dirname(__FILE__))
require 'wukong'
require Wukong.path_to(:examples, 'examples_helper')
require Wukong.path_to(:examples, 'cook_food')

describe 'examples/cook_food', :helpers => true do
  let(:eggs){ Kitchen::Ingredient.new('egg', '2') }
  let(:bowl){ Kitchen::Container.new('medium mixing bowl') }

  describe Wukong::Stage, :helpers => true do
    context 'defining actions' do

      it 'adds to the action list' do
        Kitchen::Container.actions.keys.should == [:nothing, :add]
      end

      it 'runs on run_action' do
        bowl.run_action(:add, 'cherries')
        bowl.contents.should == ['cherries']
      end
    end

    context 'factory method' do
    end
  end


  context 'make pie' do
    it 'works' do
      p Wukong.job(:cherry_pie)
    end
  end

  context 'ingredients' do
    it 'works' do
      eggs.name.should     == 'egg'
      eggs.quantity.should == '2'
    end
  end
end
