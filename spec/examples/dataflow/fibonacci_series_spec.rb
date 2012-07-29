require 'spec_helper'
require 'wukong'

describe_example_script :fibonacci_series, 'dataflow/fibonacci_series.rb', examples_spec: true do
  subject{ Wukong.chain(:fibbonaci_series) }

  it 'generates a fibonacci sequence' do
    subject.ticker.qty(12)
    # subject.output > subject.array_sink(name: :numbers)
    # subject.setup
    # subject.ticker.drive
    #
    # subject.numbers.records.should == [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89]
  end

  it_generates_graphviz{|gv_filename| puts File.read(gv_filename) }

end
