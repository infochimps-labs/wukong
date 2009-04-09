require 'yaml'
module Wukong
  CONFIG_FILE_LOCATION=File.dirname(__FILE__)+'/../../config'
  CONFIG      = { }
  def self.config_options

    # load main options
    config = YAML.load(File.open(CONFIG_FILE_LOCATION+'/wukong.yaml'     ))

    # override with site-specific options
    site_config_filename = CONFIG_FILE_LOCATION+'/wukong-site.yaml'
    if File.exists?(site_config_filename)
      site_config = YAML.load(File.open(site_config_filename))
      config.merge! site_config if site_config
    end

    # try to guess a hadoop_home if none given
    config[:hadoop_home] ||= ENV['HADOOP_HOME']

    # force these into the CONFIG global
    CONFIG.merge! config
  end
  self.config_options
end
