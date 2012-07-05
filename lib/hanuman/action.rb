module Hanuman

  #
  # `Action` stages represent transforms of data.
  #
  #
  #
  class Action < Stage

    def source?() false ; end
    def sink?()   false ; end

    class << self ; alias_method :register_action, :register_stage ; end
  end

end
