module Hanuman

  #
  # `Action` stages represent transforms of data.
  #
  # The can have singular or multiple inputs
  #
  class Action < Stage
    # alias register_action from register_stage
    class << self ; alias_method :register_action, :register_stage ; end
  end

end
