#!/usr/bin/env ruby

require File.expand_path('../examples_helper', File.dirname(__FILE__))
require 'wukong/job'

Wukong.job do

  directory(path_to(:output_dir, 'scratch/jabberwocky')) do

  end

  task('nl') do
    description 'assign line numbers'
    input       Wukong.path_to(:data_dir, 'jabberwocky.txt')
    output      TMP_DIR('')
  end



  gemset()
  bundler_gem() # bun

end
