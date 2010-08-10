require 'right_aws'
Settings.define :emr
Settings.read(File.expand_path('~/.wukong/emr.yaml'))

module Wukong
  #
  # EMR Options
  #
  module EmrCommand

    def execute_emr_workflow
      Log.info Settings.inspect
      copy_script_to_cloud
      execute_emr_runner
    end

    def copy_script_to_cloud
      Log.info "  Copying this script to the cloud."
      S3Util.store(this_script_filename, mapper_s3_uri)
      S3Util.store(this_script_filename, reducer_s3_uri)
    end

    def execute_emr_runner
      Log.info "  Executing runner."
      Log.dump File.expand_path(Settings.emr[:emr_runner])
    end

    def mapper_s3_uri
      s3_path(File.basename($0))
    end

    def reducer_s3_uri
      s3_path(File.basename($0))
    end

    def s3_path *path_segs
      File.join(Settings.emr[:emr_root], path_segs.flatten.compact)
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
            access_key, secret_access_key,
            {:multi_thread => true, :logger => Log})
        end

        def bucket_and_path_from_uri uri
          uri =~ %r{^s3\w*://([\w\.\-]+)\W*(.*)} and return([$1, $2])
        end

        def store filename, uri
          dest_bucket, dest_key = bucket_and_path_from_uri(uri)
          contents = File.open(filename)
          Log.dump dest_bucket, dest_key, contents
          s3.store_object(:bucket => dest_bucket, :key => dest_key, :data => contents)
        end

        def access_key
          Settings.emr[:access_key] || ENV['AWS_ACCESS_KEY_ID']
        end
        def secret_access_key
          Settings.emr[:secret_access_key] || ENV['AWS_SECRET_ACCESS_KEY']
        end

      end
    end
  end
  Script.class_eval do
    include EmrCommand
  end
end
