Wukong.processor(:string_reverser) do

  def setup
    log.info("Inside the setup method")
    @count = 0
    EM.add_periodic_timer(10){ notify('metrics', count: @count) }
  end

  def process(record) 
    @count += 1
    yield record.reverse
    yield nil
  end

  def finalize
    log.info("Finalizing flow")
  end
  
  def stop
    log.info("Inside the stop method")
  end

end
