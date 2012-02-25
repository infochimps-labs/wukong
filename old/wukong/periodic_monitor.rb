Settings.define :log_interval, :default => 10_000, :type => Integer, :description => 'How many iterations between log statements'
Settings.define :log_seconds,  :default => 30,     :type => Integer, :description => 'How many seconds between log statements'

#
# Periodic monitor
#
#
# This is very much a work in progress
#
class PeriodicMonitor
  attr_reader   :iter, :start_time, :options
  attr_accessor :interval
  attr_accessor :time_interval

  def initialize extra_options={}
    @options       = {}
    @options.deep_merge!( extra_options || {} )
    @iter          = 0
    @start_time    = now
    @last_report   = @start_time
    @interval      = (options[:log_interval] || Settings[:log_interval]).to_i
    @interval      = 1000 unless @interval >= 1
    @time_interval = (options[:log_seconds]  || Settings[:log_seconds]).to_i
  end

  def periodically *args, &block
    incr!
    if ready?
      @last_report = Time.now
      if block
        emit block.call(self, *args)
      else
        emit progress(*args)
      end
    end
  end

  def emit log_line
    Log.info log_line
  end

  def incr!
    @iter += 1
  end

  def ready?
    (iter % @interval == 0) || (since > time_interval)
  end

  def progress *stuff
    [
      "%15d" % iter,
      "%7.1f"% elapsed_time, "sec",
      "%7.1f"% rate, "/sec",
      now.to_flat,
      *stuff
    ].flatten.join("\t")
  end

  def elapsed_time
    now - start_time
  end
  def since
    now - @last_report
  end
  def now
    Time.now.utc
  end
  def rate
    iter.to_f / elapsed_time
  end
end
