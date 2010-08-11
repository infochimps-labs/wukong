require 'right_aws'
require 'configliere/config_block'
Settings.read(File.expand_path('~/.wukong/emr.yaml'))
Settings.define :emr_credentials_file, :description => 'A .json file holding your AWS access credentials. See http://bit.ly/emr_credentials_file for format'
Settings.define :access_key,           :description => 'AWS Access key',        :env_var => 'AWS_ACCESS_KEY_ID'
Settings.define :secret_access_key,    :description => 'AWS Secret Access key', :env_var => 'AWS_SECRET_ACCESS_KEY'
Settings.define :emr_runner,           :description => 'Path to the elastic-mapreduce command (~ etc will be expanded)'
Settings.define :emr_root,             :description => 'S3 url to use as the base for Elastic MapReduce storage'
Settings.define :key_pair_file,        :description => 'AWS Key pair file', :finally => lambda{ Settings.key_pair_file = File.expand_path(Settings.key_pair_file.to_s) if Settings.key_pair_file }
Settings.define :key_pair,             :description => "AWS Key pair name. If not specified, it's taken from key_pair_file's basename", :finally => lambda{ Settings.key_pair ||= File.basename(Settings.key_pair_file.to_s, '.pem') if Settings.key_pair_file }
Settings.define :instance_type,        :description => 'AWS instance type to use', :default => 'm1.small'
Settings.define :master_instance_type, :description => 'Overrides the instance type for the master node', :finally => lambda{ Settings.master_instance_type ||= Settings.instance_type }
Settings.define :jobflow
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
      S3Util.store(File.expand_path('~/ics/wukong/bin/bootstrap.sh'), bootstrap_s3_uri)
    end

    def execute_emr_runner
      command_args = []
      command_args << Settings.dashed_flags(:hadoop_version, :enable_debugging, :step_action, [:emr_runner_verbose, :verbose], [:emr_runner_debug, :debug]).join(' ')
      command_args += emr_credentials
      if Settings.jobflow
        command_args << Settings.dashed_flag_for(:jobflow)
      else
        command_args << Settings.dashed_flag_for(:alive)
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
        "--arg '-D mapred.reduce.tasks=0'"
      ]
      Log.info 'Follow along at http://localhost:9000/job'
      execute_command!( File.expand_path(Settings.emr_runner), *command_args )
    end

    def emr_ship_jars
      S3Util.store(File.expand_path('/tmp/wukong-libs.jar'), wukong_libs_s3_uri)
      # "--cache-archive=#{wukong_libs_s3_uri}#vendor",
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

    def mapper_s3_uri
      emr_s3_path(job_handle+'-mapper.rb')
    end
    def reducer_s3_uri
      emr_s3_path(job_handle+'-reducer.rb')
    end
    def log_s3_uri
      emr_s3_path('log', job_handle)
    end
    def bootstrap_s3_uri
      emr_s3_path('bin', "bootstrap-#{job_handle}.sh")
    end
    def wukong_libs_s3_uri
      emr_s3_path('bin', "wukong-libs.jar")
    end

    def emr_s3_path *path_segs
      File.join(Settings.emr_root, path_segs.flatten.compact)
    end

    module ClassMethods

      # Standard hack to create ClassMethods-on-include
      def self.included base
        base.class_eval do
          extend ClassMethods
        end
      end
    end

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
