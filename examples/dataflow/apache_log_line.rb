#
# Parses logs in either the [Apache Common Log Format](http://en.wikipedia.org/wiki/Common_Log_Format)
# or [Apache Combined Log Format](http://httpd.apache.org/docs/2.2/logs.html#combined)
#
# Common:   `%h %l %u %t "%r" %>s %b`
# Combined: `%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"`
#
class ApacheLogLine
  include Gorillib::Model

  field  :client,        Hostname
  field  :rfc_1413,      String
  field  :userid,        String
  field  :log_timestamp, Time
  field  :http_method,   String
  field  :rsrc,          String
  field  :protocol,      String
  field  :response_code, Integer
  field  :size,          Integer
  # field  :referer,       String
  # field  :user_agent,    String

  def page_type
    case
    when rsrc =~ /\.(css|js)$/                  then :asset
    when rsrc =~ /\.(png|gif|ico)$/             then :image
    when rsrc =~ /\.(pl|s?html?|asp|jsp|cgi)$/  then :page
    else                                             :other
    end
  end

  #
  # Regular expression to parse an apache log line.
  #
  # local - - [24/Oct/1994:13:43:13 -0600] "GET index.html HTTP/1.0" 200 3185
  # 83.240.154.3 - - [07/Jun/2008:20:37:11 +0000] "GET /faq HTTP/1.1" 200 569 "http://infochimps.org/search?query=CAC" "Mozilla/5.0 (Windows; U; Windows NT 5.1; fr; rv:1.9.0.16) Gecko/2009120208 Firefox/3.0.16"
  # whidbey.whidbey.com    - - [04/Sep/1995:00:30:18 -0400] "GET /pub/sshay/images/btthumb.jpg"      200 4624
  # jgbustam-ppp.clark.net - - [04/Sep/1995:00:00:28 -0400] "GET /pub/jgbustam/famosos/alpha.html HTTP/1.0" 304 -
  #
  COMMON_LOG_RE = Regexp.compile(%r{\A
           (\S+)                        # client              83.240.154.3
         \s(\S+)                        # rfc_1413            -
         \s(\S+)                        # userid              -
      \s\[([\w\:\+\-\ \/]+)\]           # date part           [07/Jun/2008:20:37:11 +0000]
    \s\"(?:(\S+)                        # http_method         "GET
         \s(.+?)                        # rsrc                /faq
      (?:\s(HTTP/\d+\.\d+))?|-)\"       # protocol            HTTP/1.1"
         \s(\d+|-)                      # response_code       200
         \s(\d+|-)                      # size                569
      \z
      }x)

  COMBINED_LOG_RE = Regexp.compile(%r{\A
           (\S+)                        # client              83.240.154.3
         \s(\S+)                        # rfc_1413            -
         \s(\S+)                        # userid              -
      \s\[([\w\:\+\-\ \/]+)\]           # date part           [07/Jun/2008:20:37:11 +0000]
    \s\"(?:(\S+)                        # http_method         "GET
         \s([^\"]+?)                    # rsrc                /faq
      (?:\s(HTTP/\d+\.\d+))?|-)\"       # protocol            HTTP/1.1"
         \s(\d+|-)                      # response_code       200
         \s(\d+|-)                      # size                569
    (?:\s\"([^\"]*)\")                  # referer             "http://infochimps.org/search?query=CAC"
    (?:\s\"([^\"]*)\")                  # ua                  "Mozilla/5.0 (Windows; U; Windows NT 5.1; fr; rv:1.9.0.16) Gecko/2009120208 Firefox/3.0.16"
      \z
      }x)

  # LOG_RE = Regexp.compile(%r{\A(\S+)\s})

  MONTHS = { 'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'May' => 5, 'Jun' => 6, 'Jul' => 7, 'Aug' => 8, 'Sep' => 9, 'Oct' => 10, 'Nov' => 11, 'Dec' => 12, }

  # Converts a time like `10/Apr/2007:10:58:27 +0300` to something parseable
  def receive_log_timestamp(raw_ts)

    return super(nil) # FIXME -- here for debugging


    return super(nil) if raw_ts.nil?
    match = %r{(\d+)/(\w+)/(\d+):(\d+):(\d+):(\d+)\s([\+\-\w]+)}.match(raw_ts)
    unless match then warn "Can't parse date #{raw_ts}" ; return super(nil) ; end
    #
    day, month_name, year, hour, min, sec, tz = match.captures
    month = MONTHS[month_name]
    tz.insert(3, ':')  # -0600 to -06:00
    #
    # super "#{year}-#{month}-#{day} #{hour}:#{min}:#{sec} #{tz}"
    super Time.new(year.to_i, month, day.to_i, hour.to_i, min.to_i, sec.to_i, tz)
  end

  # @returns the log_timestamp in the common log format
  def unparsed_log_timestamp
    return if log_timestamp.blank?
    log_timestamp.strftime("%d/%b/%Y:%H:%M:%S %z")
  end

  # Use the regex to break line into fields
  # Emit each record as flat line
  def self.make(line)
    m = COMMON_LOG_RE.match(line) or return
    from_tuple *m.captures
  rescue ArgumentError => err
    raise unless err.message =~ /invalid byte sequence in UTF-8/
    # Log.debug BadRecord.make(line, err).inspect
  end
end
