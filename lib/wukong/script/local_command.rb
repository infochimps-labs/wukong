require 'rbconfig'

module Wukong
  module LocalCommand

    # ===========================================================================
    #
    # Local execution Options
    #

    def local_command input_path, output_path
      ruby_path = File.join(Config::CONFIG["bindir"],
                            Config::CONFIG["RUBY_INSTALL_NAME"]+
                            Config::CONFIG["EXEEXT"])
      %Q{ cat #{input_path} | #{ruby_path} #{map_command} | sort | #{ruby_path} #{reduce_command} > '#{output_path}'}
    end

  end
end
