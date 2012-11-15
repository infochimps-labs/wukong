require 'spec_helper'

describe Wukong do

  it_behaves_like Hanuman::Shortcuts

  it{ should respond_to(:processor) }
  it{ should respond_to(:dataflow)  }

end
