module Wukong
  module Parser
    module FlatPack
      module Tokens
        TOKEN_CLASSES = {}

        def self.token_for_indicator(indicator)
          return TOKEN_CLASSES[indicator].new
        end

        class Token
          attr_accessor :position
          attr_accessor :length
          attr_accessor :indicator

          def self.indicator= indicator
            TOKEN_CLASSES[indicator] = self
            @indicator = indicator
          end
        end

        class FixedPointToken < Token
          attr_accessor :power
          attr_accessor :strict

          self.indicator = 'D'

          #TODO: Allow negative powers
          def re
            strict ? "(?:(?:\\+|-)\\d{#{@length-1}}|\\d{#{@length}})" : ".{#{@length}}"
          end

          def translate str
            return nil if str.strip == ""
            base = str.to_f
            return base / (10**@power)
          end
        end

        class BasicToken < Token
          attr_accessor :modifier

          def re token= '.'
            if not @length.nil?
              return "#{token}{#{@length}}"
            elsif not @modifier.nil?
              return "#{token}#{@modifier}"
            else
              return token
            end
          end

        end

        class IntToken < BasicToken
          self.indicator = 'i'
          RE = '(?:\+|-)?\\d'

          def re
            if not @length.nil?
              return "(?:(?:\\+|-)\\d{#{@length-1}}|\\d{#{@length}})"
            elsif not @modifier.nil?
              return "#{RE}#{@modifier}"
            else
              return RE
            end
          end

          def translate str
            return Integer(str)
          rescue ArgumentError => err
            return str.to_i
          end
        end

        class StringToken < BasicToken
          self.indicator = 's'

          def translate str
            return str
          end
        end

        class  FloatToken < BasicToken
          self.indicator = 'f'
          #TODO: Implement floats

          def get_re
            #TODO: Implement 
          end

          def translate
            #TODO: Implement
          end
        end

        class BoolToken < BasicToken
          self.indicator = 'b'
          TRUE_TOKENS = ['t','y','1'] 
          FALSE_TOKENS = ['f','n','0']

          #TODO: Add back multi-char options and think through allowing padding
          #TODO: Allow users to override true and false

          def re
            return "(?:#{(TRUE_TOKENS + TRUE_TOKENS.map {|c| c.upcase} +
              FALSE_TOKENS + FALSE_TOKENS.map{|c| c.upcase}).join('|')})"
          end

          def translate str
            if TRUE_TOKENS.include?(str.downcase)
              return true
            elsif FALSE_TOKENS.include?(str.downcase)
              return false
            else
              return nil
            end
          end
        end

        class IgnoreToken < BasicToken
          self.indicator = '_'

          # ignore symbols are removed from the final output
          def translate str
            return :ignore
          end
        end
      end
    end
  end
end
