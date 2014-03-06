require 'spec_helper'

describe Hanuman do
  
  it_behaves_like Hanuman::Shortcuts

  it{ should respond_to(:stage) }
  it{ should respond_to(:graph) }

end
