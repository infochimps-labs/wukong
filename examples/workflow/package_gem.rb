class RubyScript
  include Gorillib::FancyBuilder
  # option :warn,       :doc => 'turn warnings on for your script', :default => nil, :native_short => 'w', :type => :boolean
  # option :warn_level, :doc => 'set warning level; 0=silence, 1=medium, 2=verbose', :default => nil, :native_short => 'w', :type => Integer
  # option :with_path,  :doc => 'look for the script using PATH environment variable', :default => nil, :native_short => 'S', :type => :boolean
  option :script_name, :doc => 'the script to run', :required => true, :type => String


  def ruby_exe
    'ruby'
  end

  def commandline
    [ruby_exe, '--', script_name]
  end

  def process
    system( *commandline.flatten.reject(&:blank?) )
  end
end


class RSpecJobs < Wukong::Job
  doc    "Run RSpec code examples"
  field :rspec_opts, String, :doc => 'Command line options to pass rspec'
  field :rspec_path,    Pathname, :default => 'rspec', :doc => 'path to rspec runner'
  field :specs_pattern, String,   :default => './spec{,/*/**}/*_spec.rb', :doc => 'path glob (relative to the repo root) matching all rspec files'

  def commandline
    [ruby_exe, '-S', 'rspec', '--', script_name]
  end
end

Wukong.workflow do

  chain :gemspec do

  end

  chain :spec do

  end

  chain :version do
    chain :bump do

    end
  end


  chain :docs do
    sh 'yard', 'doc', :output => 'doc'
  end

end
