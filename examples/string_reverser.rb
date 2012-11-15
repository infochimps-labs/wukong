Wukong.processor(:string_reverser) do

  def setup
    log.info("Inside the setup method")
  end

  def process(rec) 
    notify('metrics', bad_word: rec, level: :warn) if rec.match(/fuck|shit|piss/)
    yield rec.values
  end

  def finalize
    log.info("Finalizing flow")
  end
  
  def stop
    log.info("Inside the stop method")
  end

end

Wukong.dataflow(:chained) do

  from_json > string_reverser > to_tsv > topic(topic: 'foobar')
  
end
