require 'gorillib/utils/capture_output'

shared_context 'wukong', :helpers => true do

  RSpec::Matchers.define(:be_in){|expected| match{|actual| expected.include?(actual) } }

  def self.be_ish_matcher(handle, regexp)
    RSpec::Matchers.define("be_#{handle}_ish"){ match{|actual| actual.should =~ regexp } }
  end

  def self.the(class_method, &block)
    describe(class_method){ subject{described_class} ; its(class_method, &block) }
  end

  let(:mock_val   ){ mock('mock val') }
  let(:mock_record){ mock('mock record') }
  let(:mock_stage    ){ m = mock('mock stage') ; m }
  let(:mock_processor){ m = mock ; m.stub(:name => 'mock processor', :attributes => { :a => :b }) ; m }

  let(:test_model_class){     Class.new{ include Gorillib::Model ; field :smurfiness, Integer } }
  let(:test_model){           test_model_class.receive(:smurfiness => 99) }

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
