require File.expand_path('../spec_helper', File.dirname(__FILE__))
require 'wukong'

describe :runner, :helpers => true do

  context 'tiny_count example script' do
    it 'is shorter than a tweet' do
      example_script_contents('tiny_count.rb').length.should < 140
    end

  end
end
