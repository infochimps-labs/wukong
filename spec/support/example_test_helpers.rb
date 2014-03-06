if ENV['WUKONG_COV']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/gorillib/'
    add_filter '/away/'
    add_group  'Hanuman', '/hanuman/'
  end
end

require 'gorillib/pathname'
require 'gorillib/type/extended'
require 'wukong/model/faker'

Pathname.register_path(:wukong_root, File.expand_path('..', File.dirname(__FILE__)))
Pathname.register_path(:examples,    :wukong_root, 'examples')
Pathname.register_path(:tmp,         :wukong_root, 'tmp')
Pathname.register_path(:data,        :wukong_root, 'data')
Pathname.path_to(:tmp).mkpath

Dir[ Pathname.path_to('spec', 'support', '*.rb') ].each{|f| require f }

result   = `dot -V 2>&1` rescue nil
GRAPHVIZ = ($?.exitstatus == 0) && (result =~ /dot - graphviz version/)
puts 'Some specs require graphviz to run -- brew/apt install graphviz, it is pretty awesome' unless GRAPHVIZ

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
end

shared_context 'wukong', :helpers => true do

  RSpec::Matchers.define(:be_in){|expected| match{|actual| expected.include?(actual) } }

  def self.be_ish_matcher(handle, regexp)
    RSpec::Matchers.define("be_#{handle}_ish"){ match{|actual| actual.should =~ regexp } }
  end

  let(:mock_val)      { mock('mock val')       }
  let(:mock_record)   { mock('mock record')    }
  let(:mock_stage)    { mock('mock stage')     }
  let(:mock_processor){ mock('mock processor') }

  let(:test_source)         { Wukong::Integers.new(:name => :integers, :qty => 100) }
  let(:test_sink)           { Wukong::Sink::ArraySink.new(:name => :test_sink)      }
  let(:test_processor_class){ Wukong::AsIs                                          }
  let(:test_processor)      { test_processor_class.new                              }
  let(:test_filter)         { Wukong::Widget::RegexpFilter.new(:re => /^m/)         }
  let(:test_dataflow)       { Wukong.dataflow(:test_dataflow)                       }
end

require 'gorillib/utils/capture_output'

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
    return unless attrs[:only]
    load Pathname.path_to(:examples, source_file)
    describe "Example: #{example_name}", attrs.merge(:examples_spec => true, :helpers => true) do
      let(:example_name){ example_name }
      instance_eval(&block)
    end
  rescue StandardError => err
    warn "Broken example #{example_name} with script #{source_file} (#{attrs})"
    warn err
    warn err.backtrace.join("\n")
  end

  def it_generates_graphviz
    it 'generates a graphviz picture', :if => GRAPHVIZ do
      require 'hanuman/graphvizzer/gv_presenter'
      #
      basename = Pathname.path_to(:tmp, example_name.to_s)
      Wukong.to_graphviz.save(basename, 'png')
      yield "#{basename}.dot" if block_given?
    end
  end
end
