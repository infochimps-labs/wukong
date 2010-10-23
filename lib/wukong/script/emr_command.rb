require 'right_aws'
require 'configliere/config_block'
Settings.read(File.expand_path('~/.wukong/emr.yaml'))
Settings.define :emr_credentials_file, :description => 'A .json file holding your AWS access credentials. See http://bit.ly/emr_credentials_file for format'
Settings.define :access_key,           :description => 'AWS Access key',        :env_var => 'AWS_ACCESS_KEY_ID'
Settings.define :secret_access_key,    :description => 'AWS Secret Access key', :env_var => 'AWS_SECRET_ACCESS_KEY'
Settings.define :emr_runner,           :description => 'Path to the elastic-mapreduce command (~ etc will be expanded)'
Settings.define :emr_root,             :description => 'S3 bucket and path to use as the base for Elastic MapReduce storage, organized by job name'
Settings.define :emr_data_root,        :description => 'Optional '
Settings.define :emr_bootstrap_script, :description => 'Bootstrap actions for Elastic Map Reduce machine provisioning', :default => '~/.wukong/emr_bootstrap.sh', :type => :filename
Settings.define :emr_keep_alive,       :description => 'Whether to keep machine running after job invocation', :type => :boolean
#
Settings.define :key_pair_file,        :description => 'AWS Key pair file',                               :type => :filename
Settings.define :key_pair,             :description => "AWS Key pair name. If not specified, it's taken from key_pair_file's basename", :finally => lambda{ Settings.key_pair ||= File.basename(Settings.key_pair_file.to_s, '.pem') if Settings.key_pair_file }
Settings.define :instance_type,        :description => 'AWS instance type to use',                        :default => 'm1.small'
Settings.define :master_instance_type, :description => 'Overrides the instance type for the master node', :finally => lambda{ Settings.master_instance_type ||= Settings.instance_type }
Settings.define :jobflow,              :description => "ID of an existing EMR job flow. Wukong will create a new job flow"

module Wukong
  #
  # EMR Options
  #
  module EmrCommand

    def execute_emr_workflow
      copy_script_to_cloud
      execute_emr_runner
    end

    def copy_script_to_cloud
      Log.info "  Copying this script to the cloud."
      S3Util.store(this_script_filename, mapper_s3_uri)
      S3Util.store(this_script_filename, reducer_s3_uri)
      S3Util.store(Settings.emr_bootstrap_script, bootstrap_s3_uri)
    end

    def copy_jars_to_cloud
      S3Util.store(File.expand_path('/tmp/wukong-libs.jar'), wukong_libs_s3_uri)
      # "--cache-archive=#{wukong_libs_s3_uri}#vendor",
    end

    def execute_emr_runner
      command_args = []
      command_args << Settings.dashed_flags(:hadoop_version, :enable_debugging, :step_action, [:emr_runner_verbose, :verbose], [:emr_runner_debug, :debug]).join(' ')
      command_args += emr_credentials
      if Settings.jobflow
        command_args << Settings.dashed_flag_for(:jobflow)
      else
        command_args << Settings.dashed_flag_for(:emr_keep_alive, :alive)
        command_args << "--create --name=#{job_name}"
        command_args << Settings.dashed_flags(:num_instances, [:instance_type, :slave_instance_type], :master_instance_type).join(' ')
      end
      command_args += [
        "--bootstrap-action=#{bootstrap_s3_uri}",
        "--log-uri=#{log_s3_uri}",
        "--stream",
        "--mapper=#{mapper_s3_uri} ",
        "--reducer=#{reducer_s3_uri} ",
        "--input=#{input_paths} --output=#{output_path}",
        # to specify zero reducers:
        # "--arg '-D mapred.reduce.tasks=0'"
      ]
      Log.info 'Follow along at http://localhost:9000/job'
      execute_command!( File.expand_path(Settings.emr_runner), *command_args )
    end

    def emr_credentials
      command_args = []
      if Settings.emr_credentials_file
        command_args << "--credentials #{File.expand_path(Settings.emr_credentials_file)}"
      else
        command_args << %Q{--access-id #{Settings.access_key} --private-key #{Settings.secret_access_key} }
      end
      command_args << Settings.dashed_flags(:availability_zone, :key_pair, :key_pair_file).join(' ')
      command_args
    end

    # A short name for this job
    def job_handle
      File.basename($0,'.rb')
    end

    # Produces an s3 URI within the Wukong emr sandbox from a set of path
    # segments
    #
    # @example
    #   Settings.emr_root = 's3://emr.yourmom.com/wukong'
    #   emr_s3_path('log', 'my_happy_job', 'run-97.log')
    #   # => "s3://emr.yourmom.com/wukong/log/my_happy_job/run-97.log"
    #
    def emr_s3_path *path_segs
      File.join(Settings.emr_root, path_segs.flatten.compact)
    end

    def mapper_s3_uri
      emr_s3_path(job_handle, 'code', job_handle+'-mapper.rb')
    end
    def reducer_s3_uri
      emr_s3_path(job_handle, 'code', job_handle+'-reducer.rb')
    end
    def log_s3_uri
      emr_s3_path(job_handle, 'log', job_handle)
    end
    def bootstrap_s3_uri
      emr_s3_path(job_handle, 'bin', "bootstrap-#{job_handle}.sh")
    end
    def wukong_libs_s3_uri
      emr_s3_path(job_handle, 'code', "wukong-libs.jar")
    end

    ABSOLUTE_URI = %r{^/|^\w+://}
    #
    # Walk through the input paths and the output path. Prepends
    # Settings.emr_data_root to any that does NOT look like
    # an absolute path ("/foo") or a URI ("s3://yourmom/data")
    #
    def fix_paths!
      return if Settings.emr_data_root.blank?
      unless input_paths.blank?
        @input_paths = input_paths.map{|path|   (path =~ ABSOLUTE_URI) ? path : File.join(Settings.emr_data_root, path) }
      end
      unless output_path.blank?
        @output_path = [output_path].map{|path| (path =~ ABSOLUTE_URI) ? path : File.join(Settings.emr_data_root, path) }
      end
    end

    #
    # Simple class to coordinate s3 operations
    #
    class S3Util
      # class methods
      class << self
        def s3
          @s3 ||= RightAws::S3Interface.new(
            Settings.access_key, Settings.secret_access_key,
            {:multi_thread => true, :logger => Log})
        end
        def bucket_and_path_from_uri uri
          uri =~ %r{^s3\w*://([\w\.\-]+)\W*(.*)} and return([$1, $2])
        end
        def store filename, uri
          Log.debug "    #{filename} => #{uri}"
          dest_bucket, dest_key = bucket_and_path_from_uri(uri)
          contents = File.open(filename)
          s3.store_object(:bucket => dest_bucket, :key => dest_key, :data => contents)
        end
      end
    end

  end
  Script.class_eval do
    include EmrCommand
  end
end
