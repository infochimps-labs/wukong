module Wukong

  # Boots Wukong, reading any and all relevant +settings+ for your
  # processors.
  #
  # This is most useful for any script which wants to run within a
  # deploy.  See Wukong::Deploy for more details.
  #
  # @param [Configliere::Param] settings the relevant settings object that should be configured to boot within a deploy pack
  def self.boot! settings
    # First we load the deploy pack's environment, but only if we seem
    # to be running within a deploy pack.
    Boot.load_environment        if in_deploy_pack?

    # Next pass the +settings+ to the Deploy pack itself to add
    # options it needs.
    Deploy.pre_resolve(settings) if loaded_deploy_pack?

    # Resolve the +settings+ so we can capture all the options we need
    # from the command line, the environment, &c.
    settings.resolve!

    # Now boot the deploy pack itself, passing in its known location
    # and the +settings+
    Deploy.boot!(settings, Boot.deploy_pack_dir) if loaded_deploy_pack?
  end

  # Is execution likely happening within a deploy pack?
  #
  # See Wukong::Deploy for more information on deploy packs.
  #
  # @return [true, false]
  def self.in_deploy_pack?
    return @in_deploy_pack unless @in_deploy_pack.nil?
    @in_deploy_pack = (Boot.deploy_pack_dir != '/')
  end

  # Have we already loaded the environment of a deploy pack?
  #
  # See Wukong::Deploy for more information on deploy packs.
  #
  # @return [true, false]
  def self.loaded_deploy_pack?
    in_deploy_pack? && defined?(::Wukong::Deploy)
  end

  # Lets Wukong bootstrap by requiring an enclosing deploy pack's
  # environment file if available.
  #
  # We use a simple heuristic (presence of 'Gemfile' and
  # 'config/environment.rb' in a non-root parent directory) to
  # determine whether or not we are in a deploy pack.
  module Boot

    # Return the directory of the enclosing deploy pack.  Will return
    # the root ('/') if no deeper directory is identified as a deploy
    # pack.
    #
    # @return [String]
    def self.deploy_pack_dir
      return @deploy_pack_dir if @deploy_pack_dir
      wd     = Dir.pwd
      parent = File.dirname(wd)
      until wd == parent
        return wd if File.exist?(File.join(wd, 'Gemfile')) && File.exist?(File.join(wd, 'config', 'environment.rb'))
        wd     = parent
        parent = File.dirname(wd)
      end
      @deploy_pack_dir = wd
    end

    # The default environment file that will be require'd when
    # booting.
    #
    # @return [String]
    def self.environment_file
      File.join(deploy_pack_dir, 'config', 'environment.rb')
    end

    # Load the actual deploy pack environment.  Will not swallow any
    # load errors.
    def self.load_environment
      require environment_file
    end
  end
  
end
