require 'gorillib/utils/capture_output'

shared_context 'wukong', :helpers => true do
  let(:mock_record){   mock }
  let(:mock_transform){ m = mock ; m.stub(:name => 'mock transform', :attributes => { :a => :b }) ; m }

  let(:test_array_sink){ Wukong::Sink::ArraySink.new }

  # the base transform, but emits all records unmodified
  let(:test_transform_klass){ Class.new(Wukong::Processor){ def call(record) emit(record) ; end } }

  let(:test_transform){ test_transform_klass.new }

  let(:test_filter){ Wukong.flow.select{|rec| rec =~ /^h/ } }
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
