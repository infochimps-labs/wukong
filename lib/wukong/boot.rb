module Wukong

  def self.boot! settings
    deploy_pack_dir    = enclosing_deploy_pack_dir
    within_deploy_pack = (deploy_pack_dir != '/')
    
    load_deploy_pack_environment(deploy_pack_dir) if within_deploy_pack
    settings.resolve!
    boot_deploy_pack(deploy_pack_dir)             if within_deploy_pack
  end

  private

  def self.enclosing_deploy_pack_dir
    wd     = Dir.pwd
    parent = File.dirname(wd)
    until wd == parent
      return wd if File.exist?(File.join(wd, 'Gemfile'))
      wd     = parent
      parent = File.dirname(wd)
    end
    wd                          
  end
  
  def self.load_deploy_pack_environment deploy_pack_dir
    env = File.join(deploy_pack_dir, 'config', 'environment.rb')
    require env if File.exist?(env) && File.readable?(env)
  end

  def self.boot_deploy_pack deploy_pack_dir
    Wukong::Deploy.boot!(deploy_pack_dir) if defined?(Wukong::Deploy)
  end
    
end
