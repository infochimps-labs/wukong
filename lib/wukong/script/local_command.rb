module Wukong
  module LocalCommand

    # ===========================================================================
    #
    # Local execution Options
    #

    # program, including arg, to sort input between mapper and reducer in local
    # mode. You could override to for example run 'sort -n' (numeric sort).
    def sort_command
      'sort'
    end

    def local_command input_path, output_path
      cmd_input_str  = (input_path  == '-') ? "" : "cat '#{input_path}' | "
      cmd_output_str = (output_path == '-') ? "" : "> '#{output_path}'"
      %Q{ #{cmd_input_str} #{map_command} | #{sort_command} | #{reduce_command} #{cmd_output_str} }
    end

  end
end
