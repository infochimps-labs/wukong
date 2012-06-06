class TwitterUser
  include Gorillib::Model

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

  def receive_protected(val)
    self.protected = (val.to_s == 'true' || val.to_s == '1')
  end
  def protected? ; !! self.protected  ; end

end
