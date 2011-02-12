
module Faraday
  class Adapter

    # test = Faraday::Connection.new do |f|
    #   f.use Faraday::Adapter::Dummy do |dummy|
    #     dummy.status 404
    #     dummy.delay  1
    #   end
    # end
    #
    # # this will delay 0.2s, returning 404 with
    # resp = text.get("/your/mom", :dummy_delay => 0.2)
    # resp.body # => {"method":"get","url":"/your/mom","request_headers":{"Dummy-Delay":"0.2","dummy_delay":0.2},"request":{"proxy":null},"ssl":{}}
    #
    # More example:
    #
    # test = Faraday::Connection.new do |f|
    #   f.use Faraday::Adapter::Dummy, :status => 503
    # end
    #
    # test = Faraday::Connection.new do |f|
    #   f.use Faraday::Adapter::Dummy do |dummy|
    #     dummy.delay = Proc.new{|env| 0.1 + 0.8 * rand() }
    #   end
    # end
    #
    class Dummy < Middleware
      include Addressable
      attr_reader :config
      def self.loaded?() false end

      # gets value from environment if set, configured instance variable otherwise
      def value_for env, key
        val = env[:request_headers]["Dummy-#{header_hash_key(key)}"] || config[key]
        if val.respond_to?(:call)
          val = val.call(env)
        end
        val
      end

      # With an optional delay, constructs a [status, headers, response] based on the first of:
      # * request header field (Dummy-Status, Dummy-Headers, Dummy-Resonse)
      # * adapter's configuration:
      # * Unless one of the above is set, body will return a json string taken from the request hash
      #
      def call(env)
        status  = value_for(env, :status)
        headers = value_for(env, :headers)
        headers = JSON.load(headers) if headers.is_a? String
        body    = value_for(env, :body) ||
          env.dup.tap{|hsh| [:response, :parallel_manager, :body].each{|k| hsh.delete k} }.to_json
        delay   = value_for(env, :delay).to_f
        sleep delay if delay > 0
        headers[:dummy_delay] = delay
        env.update(
          :status           => status,
          :response_headers => headers,
          :body             => body)
        @app.call(env)
      end

      class Configurator < Struct.new(:status, :headers, :delay, :body)
        def status(val=nil)  self.status  = val if val ; super() end
        def headers(val=nil) self.headers = val if val ; super() end
        def body(val=nil)    self.body    = val if val ; super() end
        def delay(val=nil)   self.delay   = val if val ; super() end
        def self.from_hash hsh
          new().tap{|config| hsh.each{|k,v| config.send("#{k}=", v) } }
        end
      end

      def initialize(app, defaults={}, &block)
        super(app)
        @config = Configurator.from_hash(defaults.reverse_merge(:status => 200, :delay => 0, :headers => {}))
        configure(&block) if block
      end

      def configure
        yield config
      end

      # same as in Faraday::Utils -- turns :dummy_response_status into 'Dummy-Response-Status'
      def header_hash_key(str)
        str.to_s.split('_').each{|w| w.capitalize! }.join('-')
      end

      def create_multipart(env, params, boundary = nil)
        stream = super
        stream.read
      end
    end
  end
end
