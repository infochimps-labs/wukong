require 'wukong/widgets/sinks/hbase_record_sink.rb'

Wukong.chain(:friend_graph) do
  tail(:scrapables) do
    directory   'scrapables/ids-%{t:ymd}.tsv'
  end

  requester = decorator('tw_requester.rb') do
    input  :scrape_url,       Url
    output :raw_json_request, JsonString
    config do
      define :request_types, :default => [:follower_ids, :friend_ids], :doc => 'which requests to make: follower_ids, user_timeline, etc'
    end
  end

  retriable_requester = retriable do
    with        :timeouts => [1,2,3]
    on_failure  :sleep
    guest       requester
  end

  tail(:scrapables)> retriable_requester > processor('tw_parse.rb') > hbase_record_sink
end

Wukong.processor(:tw_parse) do
  def process
  end
end
