class ApacheLogLine
  include Gorillib::Model

  field  :ip_address,    IpAddress
  field  :junk_1,        String
  field  :junk_2,        String
  field  :log_timestamp, Time
  field  :http_method,   String
  field  :protocol,      String
  field  :path,          String
  field  :response_code, Integer
  field  :size,          Integer
  field  :referer,       String
  field  :user_agent,    String

  def page_type
    case
    when path =~ /\.(css|js)$/                  then :asset
    when path =~ /\.(png|gif|ico)$/             then :image
    when path =~ /\.(pl|s?html?|asp|jsp|cgi)$/  then :page
    else                                             :other
    end
  end

  #
  # Regular expression to parse an apache log line.
  #
  # 83.240.154.3 - - [07/Jun/2008:20:37:11 +0000] "GET /faq HTTP/1.1" 200 569 "http://infochimps.org/search?query=CAC" "Mozilla/5.0 (Windows; U; Windows NT 5.1; fr; rv:1.9.0.16) Gecko/2009120208 Firefox/3.0.16"
  #
  LOG_RE = Regexp.compile(%r{\A
           (\S+)                        # ip                  83.240.154.3
         \s(\S+)                        # j1                  -
         \s(\S+)                        # j2                  -
       \s\[([\w\:\+\ \/]+)\]            # date part           [07/Jun/2008:20:37:11 +0000]
    \s\"(?:(\S+)                        # http_method         "GET
         \s(\S+)                        # path                /faq
         \s(\S+)|-)"                    # protocol            HTTP/1.1"
         \s(\d+)                        # response_code       200
         \s(\d+)                        # size                569
       \s\"([^\"]*)\"                   # referer             "http://infochimps.org/search?query=CAC"
       \s\"([^\"]*)\"                   # ua                  "Mozilla/5.0 (Windows; U; Windows NT 5.1; fr; rv:1.9.0.16) Gecko/2009120208 Firefox/3.0.16"
      \z}x)

  MONTHS = { 'Jan' => '01', 'Feb' => '02', 'Mar' => '03', 'Apr' => '04', 'May' => '05', 'Jun' => '06', 'Jul' => '07', 'Aug' => '08', 'Sep' => '09', 'Oct' => '10', 'Nov' => '11', 'Dec' => '12', }

  # Converts a time like `10/Apr/2007:10:58:27 +0300` to something parseable
  def receive_log_timestamp(raw_ts)
    match = %r{(\d+)/(\w+)/(\d+):(\d+):(\d+):(\d+)\s([\+\-\w]+)}.match(raw_ts)
    day, month_name, year, hour, min, sec, tz = match.captures
    month = MONTHS[month_name]
    super "#{year}-#{month}-#{day} #{hour}:#{min}:#{sec} #{tz}"
  end

  # Use the regex to break line into fields
  # Emit each record as flat line
  def self.make(line)
    m = LOG_RE.match(line.chomp)
    from_tuple *m.captures
  end
end
