module Wukong
  module LocalCommand

    # ===========================================================================
    #
    # Local execution Options
    #

    # program, including arg, to sort input between mapper and reducer in local
    # mode. You could override to for example run 'sort -n' (numeric sort).
    def local_mode_sort_commandline
      'sort'
    end

    #
    # Commandline string to execute the job in local mode
    #
    # With an input path of '-', just uses $stdin
    # With an output path of '-', just uses $stdout
    #
    def local_commandline input_path, output_path
      cmd_input_str  = (input_path  == '-') ? "" : "cat '#{input_path}' | "
      cmd_output_str = (output_path == '-') ? "" : "> '#{output_path}'"
      %Q{ #{cmd_input_str} #{mapper_commandline} | #{local_mode_sort_commandline} | #{reducer_commandline} #{cmd_output_str} }
    end

  end
end
