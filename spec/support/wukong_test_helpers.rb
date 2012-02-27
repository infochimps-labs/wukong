

shared_context 'wukong', :helpers => true do
  let(:mock_record){ mock }
  let(:mock_streamer){ mock }

  let(:test_array_sink){ Wukong::Sink::ArraySink.new }

  # the base streamer, but emits all records unmodified
  let(:test_streamer_klass){ Class.new(Wukong::Streamer::Base){ def call(record) emit(record) ; end } }

  let(:test_streamer){ test_streamer_klass.new }

  let(:test_filter){ Wukong.flow.select{|rec| rec =~ /^h/ } }
end


module WukongTestHelpers

  def dummy_stdio(stdin_text, &block)
    new_fhs = [StringIO.new(stdin_text), StringIO.new('', "w"), StringIO.new('', "w") ]
    old_fhs = [$stdin, $stdout, $stderr]
    begin
      $stdin, $stdout, $stderr = new_fhs
      yield
    ensure
      $stdin, $stdout, $stderr = old_fhs
    end
    [ new_fhs[1].string, new_fhs[2].string ]
  end

  def example_script_filename(name)
    CODE_ROOT('examples', name)
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
