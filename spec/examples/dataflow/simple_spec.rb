require 'spec_helper'
require 'wukong'

describe 'example', :only do
  # describe_example_script(:simple, 'dataflow/simple.rb', :only => true) do
  #   it 'runs' do
  #     p subject
  #   end
  # end

  it 'runs' do
    # load Pathname.path_to(:examples, 'dataflow/simple.rb')

    Wukong.dataflow(:bob) do
      ff = file_source(Pathname.path_to(:data, 'text/jabberwocky.txt')){ p self }
      rr = map{|s| s.reverse! }

      ff > rr > stdout

      setup
      ff.drive
    end

  end
end
