require 'wukong'

Wukong.processor(:reverser) do
  # This would be nice to look/function like Rack
  # consume Tweet, :as => :json # :tsv, :csv, :xml
  
  field :host, String
  
  def setup
    log.info("Inside the setup method")
  end

  def process(rec) 
    # notify('metrics', bad_word: rec) if rec.match(/fuck|shit|piss/)

    if rec.match(/snark|grumkin/)
      log.warn("They don't exist!")
    end

    yield rec.reverse
  end

  def stop
    log.info("Inside the stop method")
  end

end

Wukong.dataflow(:string_reverser) do  
  reverser > logger
end
