class Logline < Struct.new(
    :ip, :dt, :tm, :http_method, :protocol, :path, :response_code, :size, :referer, :ua, :tz, :j1, :j2)
  # 1    2    3    4              5          6      7               8         9         10    11

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
       \s\[(\d+)/(\w+)/(\d+)            # date part           [07/Jun/2008
          :(\d+):(\d+):(\d+)            # time part           :20:37:11
         \s(\+.*)\]                     # timezone            +0000]
    \s\"(?:(\S+)                        # http_method         "GET
         \s(\S+)                        # path                /faq
         \s(\S+)|-)"                    # protocol            HTTP/1.1"
         \s(\d+)                        # response_code       200
         \s(\d+)                        # size                569
       \s\"([^\"]*)\"                   # referer             "http://infochimps.org/search?query=CAC"
       \s\"([^\"]*)\"                   # ua                  "Mozilla/5.0 (Windows; U; Windows NT 5.1; fr; rv:1.9.0.16) Gecko/2009120208 Firefox/3.0.16"
      \z}x)
  MONTHS = { 'Jan' => '01', 'Feb' => '02', 'Mar' => '03', 'Apr' => '04', 'May' => '05', 'Jun' => '06', 'Jul' => '07', 'Aug' => '08', 'Sep' => '09', 'Oct' => '10', 'Nov' => '11', 'Dec' => '12', }

  # Use the regex to break line into fields
  # Emit each record as flat line
  def self.parse line
    m = LOG_RE.match(line.chomp) or return BadRecord.new(line)
    (ip, j1, j2,
      ts_day, ts_mo, ts_year,
      ts_hour, ts_min, ts_sec, tz,
      http_method, path, protocol,
      response_code, size,
      referer, ua, *cruft) = m.captures
    dt = [ts_year, MONTHS[ts_mo], ts_day].join("")
    tm = [ts_hour, ts_min, ts_sec].join("")
    self.new( ip,  dt,  tm,  http_method,  protocol,  path,  response_code,  size,  referer,  ua,  tz, j1, j2 )
  end

end
