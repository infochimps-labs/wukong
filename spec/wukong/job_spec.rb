require File.expand_path('../spec_helper', File.dirname(__FILE__))
require 'wukong'

describe Wukong::Job, :helpers => true do

  context '#output_dir' do
    it 'has filename helpers'
  end

  context '#dry_run' do
    it 'does nothing when dry run flag is set'

    it 'announces each foregone action using Log.info'
  end
end
