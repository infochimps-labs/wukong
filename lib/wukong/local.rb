module Wukong

  # Provides methods for supporting the running of Wukong processors
  # and dataflows entirely locally, without any frameworks like Hadoop
  # or Storm.
  module Local
    include Plugin
  end
end

require 'wukong/local/runner'
