
require 'wukong/and_pig/pig_var'
require 'wukong/and_pig/functions'
require 'wukong/and_pig/operators'
require 'wukong/and_pig/data_types'

require 'wukong/and_pig/generate'

require 'wukong/and_pig/pig_struct'
require 'wukong/and_pig/symbol'
require 'wukong/and_pig/utils'

module Wukong
  module AndPig
    def pig_comment comment
      puts comment.gsub(/(^|\n)(#([\t ]|$))?/, "\n--  ")
    end
  end
end
