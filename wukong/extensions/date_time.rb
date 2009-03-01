DateTime.class_eval do


  def self.parse_safely dt
    begin
      parse(dt)
    rescue
      nil
    end
  end
end
