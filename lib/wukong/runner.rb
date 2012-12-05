module Wukong
  module CommandlineRunner
            
    def exit_with_status(status, options = {})
      warn options[:msg] if options[:msg]
      @env.dump_help     if options[:show_help]
      exit(status)
    end    

    def env= settings
      @env = settings
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      
      def usage(usg = nil)
        return @usage if usg.nil?
        @usage = usg
      end

      def desc(dsc = nil)
        return @description if dsc.nil?
        @decription = desc
      end

      def add_param(*args)
        defined_params << args
      end
      
      def defined_params
        @defined_params ||= []
      end

      def base_config(conf = nil)
        return @base_configuration if conf.nil?
        @base_configuration = conf
      end

      def decorate_environment! env
        usg = self.usage
        env.define_singleton_method(:usage){ usg }
        env.description = self.desc
        defined_params.each{ |params| env.send(:define, *params) }
      end

      def in_deploy_pack?
        return @in_deploy_pack unless @in_deploy_pack.nil?
        @in_deploy_pack = (find_deploy_pack_dir != '/')
      end

      def find_deploy_pack_dir
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

      def run!(*run_params)
        settings   = base_configuration || Configliere::Param.use(:commandline)
        boot_environment(settings) if in_deploy_pack?
        runner     = new(*run_params)
        runner.env = settings.resolve!
        runner.run(*settings.rest)
      end
      
    end    
  end
  
  class LocalRunner
    include CommandlineRunner
    base_configuration

    usage 'usage: wu-local PROCESSOR|FLOW [ --param=value | -p value | --param | -p]'
    desc  <<EOF
 wu-local is a tool for running Wukong processors and flows locally on
 the command-line.  Use wu-local by passing it a processor and feeding
 in some data:

   $ echo 'UNIX is Clever and Fun...' | wu-local tokenizer.rb
   UNIX
   is
   Clever
   and
   Fun

 If your processors have named fields you can pass them in as
 arguments:

   $ echo 'UNIX is clever and fun...' | wu-local tokenizer.rb --min_length=4
   UNIX
   Clever

 You can chain processors and calls to wu-local together:

   $ echo 'UNIX is clever and fun...' | wu-local tokenizer.rb --min_length=4 | wu-local downcaser.rb
   unix
   clever

 Which is a good way to develop a combined data flow which you can
 again test locally:

   $ echo 'UNIX is clever and fun...' | wu-local tokenize_and_downcase_big_words.rb
   unix
   clever
EOF
    
    add_param :run,        description: "Name of the processor or dataflow to use. Defaults to basename of the given path.", flag: 'r'
    add_param :tcp_server, description: "Run locally as a server using provided TCP port", default: false,                   flag: 't'

    def run *args
      arg = args.first
      case
      when arg.nil?
        exit_with_status(1, show_help: true, msg: "Must pass a processor name or path to a processor file. Got <#{arg}>")
      when Wukong.registry.registered?(arg.to_sym)
        processor = arg.to_sym
      when File.exist?(arg)
        load arg
        processor = @env.run || File.basename(arg, '.rb')
      else
        exit_with_status(2, show_help: true, msg: "Must pass a processor name or path to a processor file. Got <#{arg}>")
      end     
      run_em_server(processor, @env)
    end
    
    def run_em_server(processor, env)
      EM.run do 
        env.tcp_server ? Wu::TCPServer.start(processor, env) : Wu::StdioServer.start(processor, env)
      end
    rescue Wu::Error => e
      exit_with_status(3, msg: e.backtrace.join("\n"))
    end

  end
end
