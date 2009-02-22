module Wukong
  module LocalCommand

    # ===========================================================================
    #
    # Local execution Options
    #

    def local_command input_path, output_path
      %Q{ cat #{input_path} | #{map_command} | sort | #{reduce_command} > '#{output_path}'}
    end

  end
end
