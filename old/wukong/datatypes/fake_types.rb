module Wukong
  module Datatypes
    class Text       < String  ; end unless defined?(Text)
    class Blob       < String  ; end unless defined?(Blob)
    class Boolean    < Integer ; end unless defined?(Boolean)
    class BigDecimal < Float   ; end unless defined?(BigDecimal)
    class EpochTime  < Integer ; end unless defined?(EpochTime) 
    class FilePath   < String  ; end unless defined?(FilePath)  
    class Flag       < String  ; end unless defined?(Flag)      
    class IPAddress  < String  ; end unless defined?(IPAddress) 
    class URI        < String  ; end unless defined?(URI)       
    class Csv        < String  ; end unless defined?(Csv)       
    class Yaml       < String  ; end unless defined?(Yaml)      
    class Json       < String  ; end unless defined?(Json)      
    class Regex      < Regexp  ; end unless defined?(Regex)    
  end 
end
