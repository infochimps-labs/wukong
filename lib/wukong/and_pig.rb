require 'wukong/and_pig/pig_var'
require 'wukong/and_pig/as'
require 'wukong/and_pig/functions'
require 'wukong/and_pig/operators'
require 'wukong/and_pig/data_types'
require 'wukong/and_pig/pig_struct'
require 'wukong/and_pig/generate'
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
  #   class Customer < TypedStruct.new( [:id, Integer],
  #     [:name, String], [:postal_code, Integer], [:balance, Float] )
  #   end
  #
  # will generate a LOAD command for pig as
  #
  #   Customer1.pig_load('q4_reports/customers.tsv').set!
  #   # => Q4ReportsCustomers2 = LOAD 'q4_reports/customers.tsv'
  #        AS (id: int, name: chararray, postal_code: int, balance: float) ;
  #
  # You can write anonymous chains
  #
  #   q1 = Customer1.
  #     pig_load('q4_reports/customers.tsv').set!.
  #     distinct.set! ;
  #   q1.
  #     group(:by => :postal_code).set!.
  #     generate([:group, :postal_code], ["COUNT(#{q1.relation})", :customers_per_zip]).set!.
  #     store!
  #
  #   Q4ReportsCustomers35    = LOAD    'q4_reports/customers.tsv' AS (id: int,name: chararray,postal_code: int,balance: float) ;
  #   Q4ReportsCustomers36    = DISTINCT Q4ReportsCustomers35 ;
  #   Q4ReportsCustomers37    = GROUP    Q4ReportsCustomers36 BY postal_code ;
  #   Q4ReportsCustomers38    = FOREACH  Q4ReportsCustomers37 GENERATE
  #       group AS postal_code,
  #       COUNT(Q4ReportsCustomers36) AS customers_per_zip ;
  #
  # ---------------------------------------------------------------------------
  #
  # Note on pig:
  #
  # 1) Reverse the order of your tables in your join statement. Pig always
  #    streams the keys of the last input, (materializing in memory the keys of
  #    the first), so if one of your inputs has less instances of of a given key
  #    this may help.
  #
  # 2) Reduce the number of maps and reducers per machine and give it all the
  #    memory you can.
  #
  #
  module AndPig
  end
end

