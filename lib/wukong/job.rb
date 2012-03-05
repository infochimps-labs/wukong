module Wukong
  #
  #
  #
  #
  class Job
    attr_reader :tasks

    def task(*args, &block)
      Task.new(*args, &block)
    end

  end

  #
  #
  # action
  # only_if           -- Only execute this task if the given block's result is truthy
  # not_if            -- Do not execute this task if the given block's result is truthy
  #
  # ignore_failure    -- If true, we will continue running the recipe if this resource fails for any reason. (defaults to false)
  # provider          -- The class name of a provider to use for this resource.
  # retries           -- Number of times to catch exceptions and retry the resource (defaults to 0). Requires Chef >= 0.10.4.
  # retry_delay       -- Retry delay in seconds (defaults to 2). Requires Chef >= 0.10.4.
  # supports          -- A hash of options that hint providers as to the capabilities of this resource.
  #
  module Task

    #
    # * `:nothing` -- do nothing - useful if you want to specify a resource, but only notify it of other actions.
    #
    # In the absence of another default action, `:nothing` is the default.
    #
    # @param [:delayed, :immediately] timing
    def trigger
    end

    def run
      # if dry_run? ; Log.warn "" ; return ; end
      # ...
    end

    # Notify another resource to take an action if this resource changes state for any reason.
    #
    # @example
    #   notifies :action, "resource_type[resource_name]", :notification_timing
    def notifies ; end
    # Take action on this resource if another resource changes state. Works similarly to notifies, but the direction of the relationship is reversed.
    def subscribes ;  end

    def depends(tasks)
      tasks = Array(tasks)
    end

    module ClassMethods
    end
    def self.included(base)
      base.send(:include, Wukong::Stage)
      base.extend(ClassMethods)
    end
  end


  module Task
    #
    #
    class DirectoryTask
      include Wukong::Task
      #
      action :create,                     :description => "Create this directory only if it does not exist. If it exists, do nothing"
      action :update,                     :description => "Update this directory, whether it exists or not"
      action :delete,                     :description => "Delete this directory, whether it exists or not"
      self.default_action = :create
      #
      field :path,      String,           :description => "The path to the directory; by default, the name"
      field :mode,      String,           :description => "The octal mode of the directory, e.g. '0755'. Numeric values are *not allowed* -- there's too much danger of saying '755' when you mean 'octal 0755'"
      field :recursive, :boolean,         :description => "recursive=true to operate on parents and leaf, false to operate on leaf only", :default => false,
        :summary => %Q{- delete: remove the base directory and then recursively delete its parents until one is non-empty.
                       - create: create recursively (ie, mkdir -p). Note: owner/group/mode only applies to the leaf directory, regardless of the value of this attribute.}
    end

    #
    class FileTask
      include Wukong::Task
      action :create,                     :description => "Create this file only if it does not exist. If it exists, do nothing"
      action :update,                     :description => "Update this file, whether it exists or not"
      action :delete,                     :description => "Delete this file, whether it exists or not"
      action :touch,                      :description => "Touch this file (update the mtime/atime)"
      self.default_action = :create
      #
      field :path,        String,         :description => "Path to the file; by default, the resource's name"
      field :mode,        String,         :description => "Octal mode of the file - e.g. '0755' default varies"
      # field :backup,    String,         :description => "How many backups of this file to keep. Set to false if you want no backups", :default => "5"
    end

    #
    # Creates a filesystem link, symbolic by default.
    #
    class LnTask
      include Wukong::Task
      action :create,                     :description => "Create this link only if it does not exist. If it exists, do nothing"
      action :update,                     :description => "Update this link, whether it exists or not"
      action :delete,                     :description => "Delete this link, whether it exists or not"
      self.default_action = :create
      #
      field :target_file, String,         :description => "Path to the created link; by default, same as options[:name]"
      field :to,          String,         :description => "The real file you want to link to"
      field :link_type,   Symbol,         :description => "create a :symbolic or :hard link",       :default => :symbolic
    end

    #
    # Create file from a given template:
    #
    class TemplateTask
      include Wukong::Task
      action :create,                     :description => "Create this file only if it does not exist. If it exists, do nothing"
      action :update,                     :description => "Update this file, whether it exists or not"
      action :delete,                     :description => "Delete this file, whether it exists or not"
      self.default_action = :create
      #
      field :path,        String,         :description => "Path to the file; by default, same as options[:name]"
      field :source,      String,         :description => "Template source file"
      field :variables,   String,         :description => "Variables to use in the template"
      #
      field :mode,        String,         :description => "Octal mode of the file - e.g. '0755' default varies"
      # field :backup,    String,         :description => "How many backups of this file to keep. Set to false if you want no backups", :default => 5
    end

    #
    # Create a file from a remote file
    #
    class RemoteFileTask
      include Wukong::Task
      action :create,                     :description => "Create this file only if it does not exist. If it exists, do nothing"
      action :update,                     :description => "Update this file, whether it exists or not"
      action :delete,                     :description => "Delete this file, whether it exists or not"
      self.default_action = :create
      #
      field :path,        String,         :description => "Path to the file; by default, same as options[:name]"
      field :mode,        String,         :description => "(optional) The octal mode of the file - e.g. '0755' default varies"
      # field :checksum,  String,         :description => "(optional) the SHA-256 checksum of the file--if the local file matches the checksum, Chef will not download it"
      # field :backup,    String,         :description => "How many backups of this file to keep. Set to false if you want no backups", :default => 5
    end

    #
    # Send an HTTP request
    #
    class HttpRequestTask
      include Wukong::Task
      action :request,                    :description => "Send request using the :method option"
      action :get,                        :description => "Send a GET request"
      action :put,                        :description => "Send a PUT request"
      action :patch,                      :description => "Send a PATCH request"
      action :post,                       :description => "Send a POST request"
      action :delete,                     :description => "Send a DELETE request"
      action :head,                       :description => "Send a HEAD request"
      action :options,                    :description => "Send an OPTIONS request"
      self.default_action = :get
      #
      field :url,         String,         :description => "The URL to send the request to"
      field :message,     String,         :description => "The message to be sent to the URL (as the message parameter)"
      field :headers,     Hash,           :description => "Hash of custom headers", :default => Hash.new
      field :method,      String,         :description => ""
    end

    #
    # run a command
    #
    class ExecuteTask
      include Wukong::Task
      action :run,        :description => "runs the command"
      action :revert,     :description => "reverse the effects of the primary command. If the `undo_command` field is unset, throws an error."
      #
      field :command,     String,         :description => "The command to execute"
      field :revert_cmd,  String,        :description => "Command to undo the effects of the primary command"
      field :code,        String,         :description => "Quoted script of code to execute"
      field :interpreter, String,         :description => "Script interpreter to use for code execution"
      field :flags,       [String, Hash], :description => "command line flags to pass to the interpreter when invoking. If a Hash, will be turned into `--key 'value'` pairs; all keys must be symbols or strings and all values must be strings"
      field :creates,     String,         :description => "A file this command creates - if the file exists, the command will not be run"
      field :cwd,         String,         :description => "Current working directory to run the command from"
      field :environment, String,         :description => "A hash of environment variables to set before running this command"
      field :returns,     Integer,        :description => "The return value of the command (may be an array of accepted values) - this resource raises an exception if the return value(s) do not match", :default => 0
      field :timeout,     Integer,        :description => "How many seconds to let the command run before timing it out", :default => 3600
      field :umask,       String,         :description => "Umask for files created by the command"
    end

    #
    # schedule a (job? task?)
    #
    class ScheduleTask
      include Wukong::Task
      action :create,                     :description => "Create this scheduled task only if it does not exist. If it exists, do nothing"
      action :update,                     :description => "Update this scheduled task, whether it exists or not"
      action :delete,                     :description => "Delete this scheduled task, whether it exists or not"
      self.default_action = :create
      #
      field :minute,      Integer,        :description => "The minute this entry should run (0 - 59)            *"
      field :hour,        Integer,        :description => "The hour this entry should run (0 - 23)              *"
      field :day,         Integer,        :description => "The day of month this entry should run (1 - 31)      *"
      field :month,       Integer,        :description => "The month this entry should run (1 - 12)             *"
      field :weekday,     Integer,        :description => "The weekday this entry should run (0 - 6) (Sunday=0) *"
      field :command,     String,         :description => "The command to run"
      field :user,        String,         :description => "The user to run command as. Note: If you change the crontab user then the original user will still have the same crontab running until you explicity delete that crontab        root"
      field :mailto,      String,         :description => "Set the MAILTO environment variable"
      field :path,        String,         :description => "Set the PATH environment variable"
      field :home,        String,         :description => "Set the HOME environment variable"
      field :shell,       String,         :description => "Set the SHELL environment variable"
    end

    # start a longrunning service in a new process
    class SpawnTask
      include Wukong::Task
    end

    #
    # The incoming_name accepts
    #
    # * a string
    # * a regexp
    #
    # The target_name accepts
    #
    # * a string
    # * a `Proc` to mangle the name
    #
    # @example
    #
    #     rule (/part-[mr]-\d+/ => lambda{|name| rename_part(name) }) do |r|
    #       # ...
    #     end
    class RuleTask
      include Wukong::Task
    end
  end



  def self.job(*args, &block)
    Job.new(*args, &block)
  end
end
