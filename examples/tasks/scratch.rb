#!/usr/bin/env ruby

require File.expand_path('../examples_helper', File.dirname(__FILE__))
require 'wukong/job'

Wukong.job do

  task('nl') do
    description 'assign line numbers'
    input       Wukong.path_to(:example_data, 'jabberwocky.txt')
    output      TMP_DIR('')
  end

end
