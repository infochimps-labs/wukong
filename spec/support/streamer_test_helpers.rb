
shared_context 'streamer', :streamers => true do
  let(:identity_streamer){ Wukong::Streamer::Identity.new }

  let(:mock_record){ mock }
end
