require 'spec_helper'
require 'wukong'
require 'wukong/model/faker'

describe 'Wukong::Faker', :helpers => true do

  context 'specifies fakers' do
    subject{ Class.new{ include Gorillib::Model; include Wukong::Faker } }

    it 'using type if no faker given' do
      subject.field :last_name, String
      Gorillib::Factory::StringFactory.should_receive(:fake_value)
      subject.fake_value
    end

    it 'with proc' do
      my_proc = ->{ %w[John Paul George Ringo] }
      subject.field :first_name, String, :faker => my_proc
      my_proc.should_receive(:call)
      subject.fake_value
    end

    it 'with helper name' do
      subject.field :longitude, String, :faker => :fake_longitude
      Wukong::Faker::Helpers.should_receive(:fake_longitude)
      subject.fake_value
    end

    it 'with explicit faker factory' do
      subject.field :longitude, String, :faker => Gorillib::Factory::IntegerFactory
      Gorillib::Factory::IntegerFactory.should_receive(:fake_value)
      subject.fake_value
    end

    it 'with explicit method' do
      subject.define_singleton_method(:fake_orgasm){ 'OHHH YEAHHH' }
      subject.field :orgasm, String
      subject.should_receive(:fake_orgasm)
      subject.fake_value
    end
  end


  be_ish_matcher :guid, /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/

  be_ish_matcher :fileext,    %r{^[\w\.\-]+$}
  be_ish_matcher :basename,   %r{^\w+\.\w+$}
  be_ish_matcher :dirname,    %r{^/(\w+/){1,}\w+$}
  be_ish_matcher :filename,   %r{^/(\w+/){1,}\w+\.\w+$}

  be_ish_matcher :identifier,  /\A[a-z]\w*\z/

  be_ish_matcher :hostname,    /^(\w+\.)+\w+$/
  be_ish_matcher :ip_address,  /^(\d+\.){3}\d+$/

  context 'extensions to Gorillib::Factory' do
    context Gorillib::Factory::StringFactory do
      the(:fake_value){ should =~ /^\w+$/ }
    end
    context(Gorillib::Factory::GuidFactory) do
      the(:fake_value){ should be_guid_ish }
    end
    context(Gorillib::Factory::IpAddressFactory) do
      the(:fake_value){ should be_ip_address_ish }
    end
    context(Gorillib::Factory::HostnameFactory) do
      the(:fake_value){ should be_hostname_ish }
    end

    context(Gorillib::Factory::SymbolFactory) do
      the(:fake_value){ should be_a Symbol }
      the(:fake_value){ should be_identifier_ish }
    end

    context(Gorillib::Factory::IntegerFactory) do
      the(:fake_value){ should be_a Integer }
      the(:fake_value){ should be < 100 }
    end

    context(Gorillib::Factory::TimeFactory) do
      the(:fake_value){ should be_a Time }
      the(:fake_value){ should be_within(5).of(Time.now) }
    end

    context(Gorillib::Factory::NilFactory    ){ the(:fake_value){ should equal(nil) } }
    context(Gorillib::Factory::TrueFactory   ){ the(:fake_value){ should equal(true) } }
    context(Gorillib::Factory::FalseFactory  ){ the(:fake_value){ should equal(false) } }
    context(Gorillib::Factory::BooleanFactory){ the(:fake_value){ should be_in([true, false]) } }
  end


  context Wukong::Faker::Helpers do
    subject{ Wukong::Faker::Helpers }

    its(:fake_integer){ should be_a(Integer) }
    its(:fake_integer){ should be < 100 }
    it{ subject.fake_integer(:min => 90, :max => 90).should == 90 }
    it{ subject.fake_integer(:min => 91, :max => 99).should be_in(91..99) }

    its(:fake_float){ should be_a(Float) }
    its(:fake_float){ should be < 1.0 }
    it{ subject.fake_float(:min => 90, :max => 90).should == 90 }
    it{ subject.fake_float(:min => 91, :max => 99).should be_in(91..99) }

    its(:fake_latitude){       should be_a(Float) }
    its(:fake_latitude){       should be_in(32 .. 45) }
    its(:fake_longitude){      should be_a(Float) }
    its(:fake_longitude){      should be_in(-117 .. -68) }

    its(:fake_country_id){     should be_a(String) }

    its(:fake_area_code){      should be_a(Integer) }
    its(:fake_area_code){      should be_in( 201 .. 987) }

    its(:fake_identifier){     should be_identifier_ish }
    its(:fake_sentence){       should =~ /(\S+\s+){1,5}\S+\./ }
    its(:fake_sentence){       should =~ /(\S+\.)/ }

    its(:fake_fileext ){       should be_a(String) }
    its(:fake_basename){       should be_a(String) }
    its(:fake_dirname ){       should be_a(String) }
    its(:fake_filename){       should be_a(String) }
    its(:fake_fileext ){       should be_fileext_ish }
    its(:fake_basename){       should be_basename_ish }
    its(:fake_dirname ){       should be_dirname_ish }
    its(:fake_filename){       should be_filename_ish }

    its(:fake_hostname){       should be_hostname_ish }
    its(:fake_ip_addresss){    should be_ip_address_ish }
    its(:fake_version_number){ should be_a(String) }
    its(:fake_version_number){ should =~ /^\d+\.\d+$/ }

  end
end
