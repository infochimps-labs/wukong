module Wukong
  #
  # Export model's structure for other data frameworks:
  # SQL and Pig
  #
  module Schema
    def to_sql
    end


    # Export schema as Pig
    def to_pig
      members.zip(mtypes).map do |member, type|
        member.to_s + ': ' + type.to_pig
      end.join(', ')
    end

    def pig_klass
      self.to_s.gsub(/.*::/, '')
    end

    def pig_load filename=nil
      cmd = [
        "%-23s" % pig_klass,
        "= LOAD", filename || pig_klass.underscore.pluralize,
        "AS ( rsrc:chararray,",     self.to_pig, ')',
      ].join(" ")
    end
  end
end

class << Integer ; def to_pig() 'int'           end ; end
class << Bignum  ; def to_pig() 'long'          end ; end
class << Float   ; def to_pig() 'float'         end ; end
class << String  ; def to_pig() 'chararray'     end ; end
class << Symbol  ; def to_pig() self            end ; end
class << Date    ; def to_pig() 'long'          end ; end
