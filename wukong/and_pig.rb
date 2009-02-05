require 'wukong/and_pig/pig_var'
require 'wukong/and_pig/functions'
require 'wukong/and_pig/operators'
require 'wukong/and_pig/data_types'

require 'wukong/and_pig/generate'

require 'wukong/and_pig/pig_struct'
require 'wukong/and_pig/symbol'
require 'wukong/and_pig/utils'

module Wukong
  #
  # Wukong::AndPig lets you generate and run pig[http://hadoop.apache.org/pig]
  # code from within ruby (and interactively, from the +irb+ console).
  #
  # It uses the same typed structures you've defined for Wukong to create
  # pig-types aware commands. For example, the Wukong class
  #
    class Customer < TypedStruct([ [:id, Integer],
      [:name, String], [:postal_code, Integer], [:balance, Float] ])
    end

  will generate a LOAD command for pig as

    Customer.pig_load('q4_reports/customers.tsv')
    # =>

  module AndPig
  end
end
