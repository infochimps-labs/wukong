module Wukong
  RESOURCE_CLASS_MAP = { }

  #
  # Find the class from its underscored name. Note the klass is non-modularized.
  # You can also pre-seed RESOURCE_CLASS_MAP
  #
  def self.class_from_resource rsrc
    # This method has been profiled, so don't go making it more elegant unless you're doing same.
    klass_name = rsrc.to_s
    return RESOURCE_CLASS_MAP[klass_name] if RESOURCE_CLASS_MAP.include?(klass_name)
    # kill off all but the non-modularized class name and camelize
    klass_name.gsub!(/(?:^|_)(.)/){ $1.upcase }
    begin
      # convert it to class name
      klass = klass_name.constantize
    rescue Exception => e
      warn "Bogus class name '#{klass_name}'? #{e}"
      klass = nil
    end
    RESOURCE_CLASS_MAP[klass_name] = klass
  end

end
