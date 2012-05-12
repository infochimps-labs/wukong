Wukong.dataflow(:friend_graph) do
  files(:scrapables) do
    directory   'scrapables/ids-%{t:ymd}.tsv'
  end

  decorator('tw_requester.rb') do
    request [:follower_ids, :friend_ids]
  end

  requester = retriable(decorator('requester.rb')) do
    with        :timeouts => [1,2,3]
    on_failure  :sleep
  end

  tail(:scrapables) > requester > decorator('tw_parse.rb') > hbase_record_sink
end


# Wukong.dataflow(:geo_decorator) do
#
#   source(:http_listener) do
#     port     9020
#     output   'http_listener-%{t:ymd}.json'
#   end
#
#
#
# end
