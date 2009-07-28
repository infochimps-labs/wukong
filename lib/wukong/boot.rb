module Wukong

  # ---------------------------------------------------------------------------
  #
  # Default options for Wukong
  #   http://github.com/infochimps/wukong
  #
  # If you set an environment variable WUKONG_CONFIG, *or* if the file
  # $HOME/.wukong.rb exists, that file will be +require+'d as well.
  #
  # Important values to set:
  #
  # * Wukong::CONFIG[:hadoop_home] --
  #   Path to root of hadoop install. If your hadoop runner is
  #     /usr/local/share/hadoop/bin/hadoop
  #   then your hadoop_home is
  #     /usr/local/share/hadoop.
  #   You can also set a
  #
  # * Wukong::CONFIG[:default_run_mode] -- Whether to run using hadoop (and
  #   thus, requiring a working hadoop install), or to run in local mode
  #   (script --map | sort | script --reduce)
  #
  CONFIG = {
    # Run as local or as hadoop?
    :default_run_mode => 'hadoop',

    # The command to run when a nil mapper or reducer is given.
    :default_mapper   => '/bin/cat',
    :default_reducer  => '/bin/cat',

    # Anything in HADOOP_OPTIONS_MAP (see lib/wukong/script/hadoop_command.rb)
    :runner_defaults => {
    },
  }

  def self.config_options
    # # override with site-specific options
    site_config_filename = ENV['WUKONG_CONFIG'] || (ENV['HOME'].to_s+'/.wukong.rb')
    require site_config_filename.gsub(/\.rb$/,'') if File.exists?(site_config_filename)

    # try to guess a hadoop_home if none given
    Wukong::CONFIG[:hadoop_home] ||= ENV['HADOOP_HOME'] || '/usr/lib/hadoop'
  end
  self.config_options
end

