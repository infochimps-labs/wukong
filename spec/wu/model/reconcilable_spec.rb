require 'spec_helper'
require 'gorillib/model'
require 'wu/model/reconcilable'
require 'support/model_test_helpers'

describe Gorillib::Model::Reconcilable, :model_spec do

  before do
    smurfhouse_class.class_eval do
      include Gorillib::Model::Reconcilable
    end
    smurf_class.class_eval do
      include Gorillib::Model::Reconcilable
      field :cromulence, Integer
      field :smurfhouse, Gorillib::Test::Smurfhouse
    end
  end
  let(:empty_smurf){ smurf_class.new(name: nil) }
  let(:angry_smurf){ smurf_class.new(name: 'Angry Smurf', smurfiness: 20, weapon: :smurfchucks) }
  let(:handy_smurf){ smurf_class.new(name: 'Handy Smurf', smurfiness: 20, weapon: :monkeysmurf) }
  subject{           smurf_class.new(name: 'Handy Smurf', smurfiness: 20, weapon: :monkeysmurf) }

  context '#reconcilable_attributes' do
    it 'returns only unset, non-nil values' do
      subject.weapon = nil
      subject.reconcilable_attributes.should == { name: 'Handy Smurf', smurfiness: 20 }
      subject.compact_attributes.should      == { name: 'Handy Smurf', smurfiness: 20, weapon: nil }
      empty_smurf.reconcilable_attributes.should == {}
    end
  end

  context '#conflicting_attribute!' do
    it 'warns by default' do
      stdout, stderr = capture_output{ subject.conflicting_attribute!(:weapon, :monkeysmurf, :smurfwrench) }
      stderr.string.should =~ /conflicting.* weapon: had :monkeysmurf got :smurfwrench\b/
    end
    it 'returns false always by default' do
      subject.stub(:warn)
      subject.conflicting_attribute!(:weapon, :monkeysmurf, :smurfwrench).should == false
    end
  end

  context '#adopt' do
    it 'returns true on compatible, false on incompatible' do
      subject.stub(:warn)
      subject.adopt(empty_smurf).should be_true
      subject.adopt(angry_smurf).should be_false
    end

    it 'calls adopt_foo instead of adopt_attribute(:foo, ...) if present' do
      subject.should_receive(:adopt_weapon).with(:smurfchucks,  angry_smurf).and_return true
      subject.should_receive(:adopt_name  ).with('Angry Smurf', angry_smurf).and_return true
      subject.adopt(angry_smurf).should be_true
    end

    context 'on compatible objects' do
      before{ subject.should_not_receive(:conflicting_attribute!) }
      it 'makes no changes from unset or nil values' do
        subject.adopt(empty_smurf).should be_true
        subject.should == handy_smurf
      end
      it 'makes no changes from equal values' do
        subject.adopt(handy_smurf).should be_true
        subject.should == handy_smurf
      end
      it 'sets unset attributes to the other value' do
        handy_smurf.cromulence = 99
        subject.attribute_set?(:cromulence).should be_false
        subject.adopt(handy_smurf).should be_true
        subject.should == handy_smurf
        subject.cromulence.should == 99
      end
      it 'sets nil attributes to the other value' do
        handy_smurf.cromulence = 99
        subject.cromulence = nil
        subject.attribute_set?(:cromulence).should be_true
        subject.adopt(handy_smurf).should be_true
        subject.should == handy_smurf
        subject.cromulence.should == 99
      end
      it 'asks adoptable attribute to adopt other value' do
        handy_smurf.smurfhouse  = smurfhouse_class.new(color: :brown)
        sh = subject.smurfhouse = smurfhouse_class.new(shape: :mushroom)
        subject.adopt(handy_smurf).should be_true
        subject.smurfhouse.attributes.should == { shape: :mushroom, color: :brown }
        subject.smurfhouse.should equal(sh)
      end
      it 'does not call block' do
        subject.adopt(empty_smurf){ raise 'should not call block' }
      end
    end

    context 'on incompatible objects' do
      it 'returns the value of conflicting_attribute!' do
        subject.weapon = :smurfwrench
        subject.should_receive(:conflicting_attribute!).with(:weapon, :smurfwrench, :monkeysmurf).and_return(false)
        subject.adopt(handy_smurf).should be_false
      end
      it 'returns the value of conflicting_attribute!' do
        subject.weapon = :smurfwrench
        subject.should_receive(:conflicting_attribute!).with(:weapon, :smurfwrench, :monkeysmurf).and_return(true)
        subject.adopt(handy_smurf).should be_true
      end
      it 'keeps its own value' do
        subject.stub(:conflicting_attribute!)
        subject.weapon = :smurfwrench
        subject.adopt(handy_smurf)
        subject.weapon.should == :smurfwrench
      end
      it 'adoptible attributes reconcile' do
        handy_smurf.smurfhouse  = smurfhouse_class.new(color: :brown)
        sh = subject.smurfhouse = smurfhouse_class.new(shape: :mushroom, color: :red)
        sh.should_receive(:conflicting_attribute!).with(:color, :red, :brown)
        #
        subject.adopt(handy_smurf).should be_false
        subject.smurfhouse.attributes.should == { shape: :mushroom, color: :red }
        subject.smurfhouse.should equal(sh)
      end
      it 'adoptible attributes reconcile and warn' do
        subject.should_not_receive(:conflicting_attribute!)
        handy_smurf.smurfhouse  = smurfhouse_class.new(color: :brown)
        sh = subject.smurfhouse = smurfhouse_class.new(shape: :mushroom, color: :red)
        sh.should_receive(:conflicting_attribute!).with(:color, :red, :brown)
        #
        subject.adopt(handy_smurf)
      end
      it 'does not take a block' do
        subject.stub(:warn)
        subject.adopt(angry_smurf){ raise 'should not call block' }
      end
    end
  end

  context '#adopt_attribute' do
    context 'takse a block (useful in overrides):' do
      it 'on compatible values, block is not called' do
        subject.should_not_receive(:conflicting_attribute!)
        subject.send(:adopt_attribute, :weapon, :monkeysmurf) do
          raise 'should not call block'
        end
      end
      it 'on incompatible values, block is called instead of conflicting_attribute!' do
        subject.should_not_receive(:conflicting_attribute!)
        subject.send(:adopt_attribute, :weapon, :smurfwrench) do
          mock_val
        end.should == mock_val
      end
    end
  end


end
