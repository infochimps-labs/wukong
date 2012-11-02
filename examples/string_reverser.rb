require 'wukong'

Wukong.processor(:string_reverser) do
  # This would be nice to look/function like Rack
  # consume Tweet, :as => :json # :tsv, :csv, :xml
  
  field :host, String
  
  def setup
    log.formatter = ->(sev, t, prog, msg){ "#{t.utc} [#{sev}] :: #{msg}\n" }
    log.info("Inside the setup method"){ self.class.to_s }
  end

  def process(rec) 
    notify('metrics', bad_word: rec, level: :warn) if rec.match(/fuck|shit|piss/)

    if rec.match(/snark|grumkin/)
      log.warn("They don't exist!")
    end

    yield rec.reverse
  end

  def stop
    log.info("Inside the stop method")
  end

end
