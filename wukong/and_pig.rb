
class << Tweet
  attr_accessor :member_types
  self.member_types = [ :chararray, :int, :long, :int, :int, :int, :int, :int, :chararray, :chararray ]
end

class PigEmitter

  def path_str path
    path.flatten.compact.join('/')
  end

  def flat_typespec klass
    klass.members.zip(klass.member_types).map do |attr, type|
      "%s: %s" % [attr, type]
    end.join(',')
  end


  def load thing, klass, src_path
    "%-24s= LOAD '%s' AS (%s)" % [thing.to_s, path_str(src_path), flat_typespec(klass)]
  end

  def checkpoint! thing, klass, dest_path

  end
end
