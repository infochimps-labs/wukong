# extract each record from request contents
# and stream it to output
class TwitterRequestParser < Wukong::Streamer::StructStreamer
  def process request
    request.parse do |obj|
      yield obj
    end
  end
end

# Incoming Request:
class TwitterFollowersRequest < Struct.new(
    :url, :scraped_at, :response_code, :response_message, :moreinfo, :contents)
  include Monkeyshines::ScrapeRequest
end

# Outgoing classes:
class TwitterUser < TypedStruct.new( :id, :scraped_at, :screen_name, :protected, :created_at,
    :followers_count, :friends_count, :statuses_count, :favourites_count )
end
class Tweet < TypedStruct.new(:id, :created_at, :twitter_user_id, :favorited, :truncated,
    :text, :source, :in_reply_to_user_id, :in_reply_to_status_id, :in_reply_to_screen_name)
end

# Parsing code:
TwitterFollowersRequest.class_eval do
  include Monkeyshines::RawJsonContents
  def parse &block
    parsed_contents.each do |user_tweet_hash|
      yield AFollowsB.new         user_tweet_hash["id"], self.moreinfo[:request_user_id]
      yield TwitterUser.from_hash user_tweet_hash
      yield Tweet.from_hash       user_tweet_hash
    end
  end
end

# This makes the script go.
Wukong::Script.new(TwitterRequestParser, TwitterRequestUniqer).run
