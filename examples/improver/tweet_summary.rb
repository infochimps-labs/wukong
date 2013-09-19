
#
# Stupidly simple class for holding a twitter user's tweet summary
#
class UserTweetSummary  
  attr_accessor :fields

  def initialize fields
    @fields = fields    
  end
    
  def update tweets
    deletes_this_batch = 0
    tweets_this_batch  = 0
    tweets.each do |tweet|
      deletes_this_batch += (tweet.is_deleted ? 1 : 0)
      tweets_this_batch  += 1
    end
    fields['deletes'] += deletes_this_batch
    fields['tweets']  += (tweets_this_batch - deletes_this_batch)
    self
  end

  def to_json *args
    fields.to_json     
  end  
end

#
# Holds a tweet and whether
# or not it's been deleted
#
class Tweet
  attr_accessor :is_deleted
  def initialize hash
    @is_deleted = hash.keys.include?("delete")
  end
end


#
# Improver processor
#
class TweetSummarizer < Wukong::Processor::Improver
  attr_accessor :user_id
  
  def zero
    super
    {
      'tweets'  => 0,
      'deletes' => 0
    }
  end

  def accumulate record
    @user_id = record[0]
    json     = record[1]
    self.group << Tweet.new(JSON.parse(json))
  end

  def improve summary, deltas    
    UserTweetSummary.new(JSON.parse(summary)).update(deltas)
  end  
end

#
# Is this necessary?
#
TweetSummarizer.register(:tweet_summarizer)

Wukong.dataflow(:summarize_tweets) do
  tweet_summarizer | to_json
end
