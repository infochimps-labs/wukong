module Wukong
  #
  # Global encapsulates a shared global state across all executing processes,
  # whether on the same machine,
  #
  # Examples include:
  #
  # * values
  # * counters
  # * timers
  # * events (notifications / watches)
  #
  # Not all executors will be able to guarantee consistency or performance for
  # these operations.
  #
  # Do not get carried away with this: used foolishly, these can be death to
  # stability and performance.
  #
  #
  module Global
  end
end
