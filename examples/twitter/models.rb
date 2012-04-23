$LOAD_PATH.unshift File.expand_path('../../../../backend/icss/lib', File.dirname(__FILE__))
require 'icss'

class TwitterUser
  include Icss::ReceiverModel
  field :user_id,      Integer
  field :screen_name,  String
  field :created_at,   Time
  field :scraped_at,   String
  field :protected,    Boolean
  field :followers,    Integer
  field :friends,      Integer
  field :tweets_count, Integer
  field :geo_enabled,  Boolean
  field :time_zone,    String
  field :utc_offset,   String
  field :lang,         String
  field :location,     String
  field :url,          String

  def to_json(*args)
    to_hash.to_json(*args)
  end

  def receive_protected(val)
    self.protected = (val.to_s == 'true' || val.to_s == '1')
  end
  def protected? ; !! self.protected  ; end

end
