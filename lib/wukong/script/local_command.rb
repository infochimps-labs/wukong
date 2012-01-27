module Wukong
  #
  # Local execution Options
  #
  module LocalCommand

    Settings.define :sort_command, :default => 'sort'
    Settings.define :sort_args,    :default => [], :description => 'Extra params to send to the sort function eg: Settings.sort_args = ["-t", "\t", "-S", "200M"]'

    def execute_local_workflow
      Log.info "  Reading STDIN / Writing STDOUT"
      execute_command!(local_commandline)
    end

    # program, including arg, to sort input between mapper and reducer in local
    # mode. You could override to for example run 'sort -n' (numeric sort).
    def local_mode_sort_commandline
      [ Settings.sort_command, Settings.sort_args ].flatten.join(" ")
    end

    #
    # Commandline string to execute the job in local mode
    #
    # With an input path of '-', just uses $stdin
    # With an output path of '-', just uses $stdout
    #
    def local_commandline
      @input_paths = input_paths.map(&:strip).join(' ')
      cmd_input_str  = (input_paths == '-') ? "" : "cat '#{input_paths}' | "
      cmd_output_str = (output_path == '-') ? "" : "> '#{output_path}'"

      if (reducer || options[:reduce_command])
        %Q{ #{cmd_input_str} #{mapper_commandline} | #{local_mode_sort_commandline} | #{reducer_commandline} #{cmd_output_str} }
      else
        %Q{ #{cmd_input_str} #{mapper_commandline} | #{local_mode_sort_commandline} #{cmd_output_str} }
      end

    end

  end
end
