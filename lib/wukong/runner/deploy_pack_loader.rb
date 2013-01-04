module Wukong
  class Runner

    # Lets Wukong bootstrap by requiring an enclosing deploy pack's
    # environment file if available.
    #
    # We use a simple heuristic (presence of 'Gemfile' and
    # 'config/environment.rb' in a non-root parent directory) to
    # determine whether or not we are in a deploy pack.
    module DeployPackLoader

      # Load the actual deploy pack environment.  Will not swallow any
      # load errors.
      def load_deploy_pack
        load_ruby_file(environment_file) if in_deploy_pack?
      end
      
      # Is execution likely happening within a deploy pack?
      #
      # See Wukong::Deploy for more information on deploy packs.
      #
      # @return [true, false]
      def in_deploy_pack?
        return @in_deploy_pack unless @in_deploy_pack.nil?
        @in_deploy_pack = (deploy_pack_dir != '/')
      end
      
      # Have we already loaded the environment of a deploy pack?
      #
      # See Wukong::Deploy for more information on deploy packs.
      #
      # @return [true, false]
      def loaded_deploy_pack?
        in_deploy_pack? && defined?(::Wukong::Deploy)
      end

      # The default environment file that will be require'd when
      # booting.
      #
      # @return [String]
      def environment_file
        File.join(deploy_pack_dir, 'config', 'environment.rb')
      end
      
      # Return the directory of the enclosing deploy pack.  Will return
      # the root ('/') if no deeper directory is identified as a deploy
      # pack.
      #
      # @return [String]
      def deploy_pack_dir
        return File.dirname(ENV["BUNDLE_GEMFILE"]) if ENV["BUNDLE_GEMFILE"] && is_deploy_pack_dir?(File.dirname(ENV["BUNDLE_GEMFILE"]))
        return @deploy_pack_dir if @deploy_pack_dir
        wd     = Dir.pwd
        parent = File.dirname(wd)
        until wd == parent
          return wd if is_deploy_pack_dir?(wd)
          wd     = parent
          parent = File.dirname(wd)
        end
        @deploy_pack_dir = wd
      end

      private

      # Could `dir` be a deploy pack dir?
      #
      # @param [String] dir
      # @return [true, false]
      def is_deploy_pack_dir? dir
        dir && !dir.empty? && File.directory?(dir) && File.exist?(File.join(dir, 'Gemfile')) && File.exist?(File.join(dir, 'config', 'environment.rb'))
      end
    end
    
  end
end
