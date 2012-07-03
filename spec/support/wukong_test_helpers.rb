require 'gorillib/utils/capture_output'

shared_context 'wukong', :helpers => true do

  RSpec::Matchers.define(:be_in){|expected| match{|actual| expected.include?(actual) } }

  def self.be_ish_matcher(handle, regexp)
    RSpec::Matchers.define("be_#{handle}_ish"){ match{|actual| actual.should =~ regexp } }
  end

  let(:mock_val      ){ mock('mock val')    }
  let(:mock_record   ){ mock('mock record') }
  let(:mock_stage    ){ mock('mock stage')  }
  let(:mock_processor){ mock('mock processor') }

  let(:test_source){          Wukong::Integers.new(:name => :integers, :size => 100) }
  let(:test_sink){            Wukong::Sink::ArraySink.new(:name => :test_sink) }
  let(:test_processor_class){ Wukong::AsIs }
  let(:test_processor){       test_processor_class.new }
  let(:test_filter){          Wukong::Widget::RegexpFilter.new(:re => /^m/) }
  let(:test_dataflow){        Wukong.dataflow(:test_dataflow) }
end


module WukongTestHelpers

  def example_script_filename(name)
    Pathname.path_to(:examples, name)
  end

  def example_script_contents(name)
    File.read(example_script_filename(name))
  end

  def sample_data_filename(name)
    Pathname.path_to(:wukong_root, 'data', name)
  end

  def sample_data(name)
    File.open(sample_data_filename(name))
  end

end

RSpec::Core::DSL.module_eval do
  def describe_example_script(example_name, source_file, attrs={}, &block)
    return unless attrs.delete(:only)
    load Pathname.path_to(:examples, source_file)
    describe "Example: #{example_name}", attrs.merge(:examples_spec => true, :helpers => true) do
      subject{ Wukong.dataflow(example_name) }
      instance_eval(&block)
    end
  rescue StandardError => err
    warn "Broken example #{example_name} with script #{source_file} (#{attrs})"
    warn err
    warn err.backtrace
  end
end
