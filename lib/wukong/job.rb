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
  class Task < Stage

    #
    # * `:nothing` -- do nothing - useful if you want to specify a resource, but only notify it of other actions.
    #
    # In the absence of another default action, `:nothing` is the default.
    #
    # @param [:delayed, :immediately] timing
    def action
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

  end


  Task.class_eval do
    #
    #
    class DirectoryTask < Wukong::Task
      action :create,     String,         :description => "Create this directory only if it does not exist. If it exists, do nothing"
      action :update,     String,         :description => "Update this directory"
      action :delete,     String,         :description => "Delete this directory"
      self.default_action = :create
      #
      field :path, String,                :description => "The path to the directory; by default, the name"
      field :mode, String,                :description => "The octal mode of the directory, e.g. '0755'. Numeric values are *not allowed* -- there's too much danger of saying '755' when you mean 'octal 0755'"
      field :recursive, :boolean,         :description => "recursive=true to operate on parents and leaf, false to operate on leaf only", :default => false,
        :summary => %Q{- delete: remove the base directory and then recursively delete its parents until one is non-empty.
                       - create: create recursively (ie, mkdir -p). Note: owner/group/mode only applies to the leaf directory, regardless of the value of this attribute.}
    end

    #
    class FileTask < Wukong::Task
      action :create,     String,         :description => "Create this file only if it does not exist. If it exists, do nothing"
      action :update,     String,         :description => "Update this file"
      action :delete,     String,         :description => "Delete this file"
      action :touch,      String,         :description => "Touch this file (update the mtime/atime)"
      self.default_action = :create
      #
      field :path,        String,         :description => "Path to the file; by default, the resource's name"
      field :mode,        String,         :description => "Octal mode of the file - e.g. '0755' default varies"
      # field :backup,    String,         :description => "How many backups of this file to keep. Set to false if you want no backups", :default => "5"
    end

    #
    # Creates a filesystem link, symbolic by default.
    #
    class LnTask < Wukong::Task
      action :create,     String,         :description => "Create this link only if it does not exist. If it exists, do nothing"
      action :update,     String,         :description => "Update this link"
      action :delete,     String,         :description => "Delete this link"
      self.default_action = :create
      #
      field :target_file, String,         :description => "Path to the created link; by default, same as options[:name]"
      field :to,          String,         :description => "The real file you want to link to"
      field :link_type,   Symbol,         :description => "create a :symbolic or :hard link",       :default => :symbolic
    end

    #
    # Create file from a given template:
    #
    class TemplateTask < Wukong::Task
      action :create,     String,         :description => "Create this file only if it does not exist. If it exists, do nothing"
      action :update,     String,         :description => "Update this file"
      action :delete,     String,         :description => "Delete this file"
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
    class RemoteFileTask < Wukong::Task
      action :create,     String,         :description => "Create this file only if it does not exist. If it exists, do nothing"
      action :update,     String,         :description => "Update this file"
      action :delete,     String,         :description => "Delete this file"
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
    class HttpRequestTask < Wukong::Task
      action :request,    String,         :description => "Send request using the :method option"
      action :get,        String,         :description => "Send a GET request"
      action :put,        String,         :description => "Send a PUT request"
      action :patch,      String,         :description => "Send a PATCH request"
      action :post,       String,         :description => "Send a POST request"
      action :delete,     String,         :description => "Send a DELETE request"
      action :head,       String,         :description => "Send a HEAD request"
      action :options,    String,         :description => "Send an OPTIONS request"
      self.default_action = :get
      #
      field :url,         String,         :description => "The URL to send the request to"
      field :message,     String,         :description => "The message to be sent to the URL (as the message parameter)"
      field :headers,     Hash,           :description => "Hash of custom headers", :default => Hash.new
      field :method,      String,         :description => ""
    end

    #
    #
    class ExecuteTask < Wukong::Task
      field :command,     String,         :description => "The command to execute"
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

    # schedule a (job? task?)
    #
    class ScheduleTask < Wukong::Task
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
    class SpawnTask < Wukong::Task
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
    class RuleTask < Wukong::Task

    end

    #
    #
    # dependency times - newer-than edge?
    #
    class FileTask < Wukong::Task
    end
  end



  def self.job(*args, &block)
    Job.new(*args, &block)
  end
end
