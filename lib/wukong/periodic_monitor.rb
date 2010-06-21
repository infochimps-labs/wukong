Settings.define :log_interval, :default => 1000, :type => Integer, :description => 'How many iterations between log statements'

#
# Periodic monitor
#
#
# This is very much a work in progress
#
class PeriodicMonitor
  attr_reader   :iter, :start_time, :options
  attr_accessor :interval

  def initialize extra_options={}
    @options      = {}
    @options.deep_merge!( extra_options || {} )
    @iter         = 0
    @start_time   = now
    @interval     = (options[:log_interval] || Settings[:log_interval]).to_i
    @interval = 1000 unless @interval >= 1
  end

  def periodically *args, &block
    incr!
    if ready?
      if block
        block.call(iter, *args)
      else
        $stderr.puts progress(*args)
      end
    end
  end

  def incr!
    @iter += 1
  end

  def ready?
    iter % @interval == 0
  end

  def progress *stuff
    [
      "%15d" % iter,
      "%7.1f"% elapsed_time, "sec",
      "%7.1f"%(iter.to_f / elapsed_time), "/sec",
      now.to_flat,
      *stuff
    ].join("\t")
  end

  def elapsed_time
    now - start_time
  end
  def now
    Time.now.utc
  end
end
