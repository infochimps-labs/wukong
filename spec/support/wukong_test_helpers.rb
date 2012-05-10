require 'gorillib/utils/capture_output'

shared_context 'wukong', :helpers => true do
  let(:mock_record){   mock }
  let(:mock_streamer){ m = mock ; m.stub(:name => 'mock streamer', :attributes => { :a => :b }) ; m }

  let(:test_array_sink){ Wukong::Sink::ArraySink.new }

  # the base streamer, but emits all records unmodified
  let(:test_streamer_klass){ Class.new(Wukong::Transform){ def call(record) emit(record) ; end } }

  let(:test_streamer){ test_streamer_klass.new }

  let(:test_filter){ Wukong.flow.select{|rec| rec =~ /^h/ } }
end


module WukongTestHelpers

  def example_script_filename(name)
    Gorillib.path_to(:examples, name)
  end

  def example_script_contents(name)
    File.read(example_script_filename(name))
  end

  def sample_data_filename(name)
    CODE_ROOT('data', name)
  end

  def sample_data(name)
    File.open(sample_data_filename(name))
  end

end
