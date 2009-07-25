module Wukong
  CONFIG_FILE_LOCATION=File.dirname(__FILE__)+'/../../config'
  ::Wukong::CONFIG      = { }
  def self.config_options

    # load main options
    require CONFIG_FILE_LOCATION+'/wukong'

    # # override with site-specific options
    site_config_filename = CONFIG_FILE_LOCATION+'/wukong-site'
    require site_config_filename if File.exists?(site_config_filename+'.rb')

    # try to guess a hadoop_home if none given
    Wukong::CONFIG[:hadoop_home] ||= ENV['HADOOP_HOME']

  end
  self.config_options
end

