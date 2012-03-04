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

    #
    # group             -- The group owner of the directory (string or id)
    # mode              -- The octal mode of the directory, e.g. '0755' default varies
    # owner             -- The owner for the directory
    # path              -- Name attribute: The path to the directory -- name
    # recursive         -- When deleting the directory, delete it recursively. When creating the directory, create recursively (ie, mkdir -p). Note: owner/group/mode only applies to the leaf directory, regardless of the value of this attribute
    #
    def directory
    end

    #
    # create            -- Create this file -- Yes
    # create_if_missing -- Create this file only if it does not exist. If it exists, do nothing.
    # delete            -- Delete this file
    # touch             -- Touch this file (update the mtime/atime)
    #
    # path              -- Name attribute: The path to the file -- name
    # backup            -- How many backups of this file to keep. Set to false if you want no backups. -- 5
    # group             -- The group owner of the file (string or id)
    # mode              -- The octal mode of the file - e.g. '0755' default varies
    # owner             -- The owner for the file
    # content           -- A string to write to the file. This will replace any previous content if set -- nil (don't manage content)
    #
    def file
    end

    #
    # Creates a filesystem link, symbolic by default.
    #
    # target_file       -- Name Attribute: The file name of the link -- name
    # to                -- The real file you want to link to
    # link_type         -- Either :symbolic or :hard. -- :symbolic
    # owner             -- The owner of the symlink
    # group             -- The group of the symlink
    #
    #
    #
    def link
    end

    #
    # path              -- Name attribute: The path to the file -- name
    # backup            -- How many backups of this file to keep. Set to false if you want no backups. -- 5
    # group             -- (optional) The group owner of the file (string or id)
    # mode              -- (optional) The octal mode of the file - e.g. '0755' default varies
    # owner             -- (optional) The owner for the file
    # source            -- The source URL -- the basename of the path attribute (see deprecated attributes)
    # checksum          -- (optional) the SHA-256 checksum of the file--if the local file matches the checksum, Chef will not download it -- nil
    #
    def remote_file
    end

    #
    # command           -- Name attribute: The command to execute -- name
    # code              -- Quoted script of code to execute. -- nil
    # interpreter       -- Script interpreter to use for code execution. -- nil
    # flags             -- command line flags to pass to the interpreter when invoking -- nil
    # creates           -- A file this command creates - if the file exists, the command will not be run. -- nil
    # cwd               -- Current working directory to run the command from. -- nil
    # environment       -- A hash of environment variables to set before running this command. -- nil
    # group             -- A group name or group ID that we should change to before running this command. -- nil
    # path              -- An array of paths to use when searching for the command. Note that these are not added to the command's environment $PATH. -- nil, uses system path
    # returns           -- The return value of the command (may be an array of accepted values) - this resource raises an exception if the return value(s) do not match. -- 0
    # timeout           -- How many seconds to let the command run before timing it out. -- 3600
    # user              -- A user name or user ID that we should change to before running this command. -- nil
    # umask             -- Umask for files created by the command -- nil
    #
    def execute
    end

    #
    # get               -- Send a GET request -- Yes
    # put               -- Send a PUT request
    # post              -- Send a POST request
    # delete            -- Send a DELETE request
    # head              -- Send a HEAD request
    # options           -- Send an OPTIONS request
    # Attributes
    # Attribute         -- Description -- Default Value
    # url               -- The URL to send the request to -- nil
    # message           -- Name attribute: The message to be sent to the URL (as the message parameter) -- name
    # headers           -- Hash of custom headers -- {}
    #
    def http_request
    end

    # start a longrunning service in a new process
    def spawn
    end

    # schedule a (job? task?)
    #
    # minute            -- The minute this entry should run (0 - 59)            *
    # hour              -- The hour this entry should run (0 - 23)              *
    # day               -- The day of month this entry should run (1 - 31)      *
    # month             -- The month this entry should run (1 - 12)             *
    # weekday           -- The weekday this entry should run (0 - 6) (Sunday=0) *
    # command           -- The command to run
    # user              -- The user to run command as. Note: If you change the crontab user then the original user will still have the same crontab running until you explicity delete that crontab        root
    # mailto            -- Set the MAILTO environment variable
    # path              -- Set the PATH environment variable
    # home              -- Set the HOME environment variable
    # shell             -- Set the SHELL environment variable
    #
    def schedule
    end

    # path              -- Name attribute: The path to the file -- name
    # source            -- Template source file. Found in templates/default for the cookbook. -- nil
    # group             -- The group owner of the file (string or id)
    # mode              -- The octal mode of the file - e.g. '0755' default varies
    # owner             -- The owner for the file
    # variables         -- Variables to use in the template.
    #
    def template
    end

  end

  module Task < Stage

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
    class Base

      #
      # * `:nothing` -- do nothing - useful if you want to specify a resource, but only notify it of other actions.
      #
      # In the absence of another default action, `:nothing` is the default.
      #
      # @param [:delayed, :immediately] timing
      def action
      end

      # Notify another resource to take an action if this resource changes state for any reason.
      #
      # @example
      #   notifies :action, "resource_type[resource_name]", :notification_timing
      def notifies ; end
      # Take action on this resource if another resource changes state. Works similarly to notifies, but the direction of the relationship is reversed.
      def subscribes ;  end

    end

    #
    #
    # dependency times - newer-than edge?
    #
    class FileTask < Wukong::Task::Base
    end
  end



  def self.job(*args, &block)
    Job.new(*args, &block)
  end
end
