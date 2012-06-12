require 'forgery'
require 'uuidtools'

# Bolt extra parameters onto field declaration

class Gorillib::Model::Field
  field :faker,      Whatever, :doc => "Factory for creating a fake value; anything responding to #fake_value()", :tester => true
  field :faker_args, Array,    :doc => "Parameters to splat in for calls to the faker factory", :default => []

  def fake_value
    faker = read_attribute(:faker)
    case faker
    when nil          then self.type.fake_value(*faker_args)
    when Symbol       then Wukong::Faker::Helpers.public_send(faker, *faker_args)
    when Proc, Method then faker.call(*faker_args)
    else                   faker.fake_value(*faker_args)
    end
  end
end

module Wukong
  #
  # @example
  #
  #   class Person
  #     include Gorillib::Model
  #     include Wukong::Faker
  #     field :first_name, String, :faker => ->{ %w[John Paul George Ringo] }
  #     field :last_name,  String
  #     field :user_id,    String, :faker => :fake_identifier
  #
  module Faker
    extend Gorillib::Concern

    module ClassMethods

      def fake_value
        new.update_attributes(fake_attrs)
      end

    protected
      #
      # For the example of a field `:foo` of type `HappyType`, calls the first of:
      # * the instance method :fake_foo if it exists.
      # * `fake_value` on the `:faker => XX` parameter in `:foo`'s field definition.
      # * `fake_value` on the field's type
      #
      # If the faker is simple, or if there's a standard faker for what you want,
      # When a generic faker won't do, or is complicated, use
      def fake_attrs
        attrs = {}
        fields.each do |field_name, field|
          attrs[field_name] = self.respond_to?("fake_#{field_name}") ? send("fake_#{field_name}") : field.fake_value
        end
        attrs
      end

      # defines a method to return an arbitrary value from the given list.
      def fake_from_list(field_name, values)
        define_singleton_method("fake_#{field_name}"){ values.sample }
      end
    end

    module Helpers
      extend self

      def fake_integer(opts={})
        opts = { :min => 0, :max => 1 }.merge(opts)
        min, max = [ opts[:min].to_i, opts[:max].to_i ].sort
        return min if min == max
        min + Kernel.rand(max-min)
      end
      def fake_float(opts={})
        opts = { :min => 0.0, :max => 1.0 }.merge(opts)
        min, max = [ opts[:min].to_f, opts[:max].to_f ].sort
        min + ((max-min) * Kernel.rand)
      end

      #  A latitude unif. dist from San Diego  lat 32 lng -117 to Maine lat 44 lng -68 -- sorry non-yanks
      def fake_latitude(opts={})  ; fake_float({:min =>   32.0, :max =>  45.0}.merge(opts)) ; end
      #  A longitude unif. dist from San Diego lat 32 lng -117 to Maine lat 44 lng -68 -- sorry non-yanks
      def fake_longitude(opts={}) ; fake_float({:min => -117.0, :max => -68.0}.merge(opts)) ; end

      def fake_country_id()       ; Forgery::Internet.cctld ; end       # KLUDGE: uses tlds, not country codes
      def fake_area_code()        ; fake_integer(:min => 200, :max => 987) ; end

      def fake_word()             ; Forgery::LoremIpsum.word(:random => true) ; end
      def fake_identifier()       ; fake_word.downcase.gsub(/\W/,'_').gsub(/^[^a-z]/, 'a') ; end
      def fake_sentence()         ; Forgery::LoremIpsum.sentence(:random => true) ; end
      def fake_paragraph()        ; Forgery::LoremIpsum.paragraph(:random => true) ; end

      def fake_fileext()          ; %w[ rb html py sh com bat doc txt pdf xml exe app].sample ; end
      def fake_basename()         ; "#{fake_identifier}.#{fake_fileext}" ; end
      def fake_dirname()          ; File.join('/', * 3.times.map{ fake_identifier }) ; end
      def fake_filename()         ; File.join(fake_dirname, fake_basename) ; end

      def fake_hostname()         ; Forgery::Internet.domain_name ; end
      def fake_ip_addresss()      ; Forgery::Internet.ip_v4       ; end
      def fake_version_number()   ; "%.1f" % fake_float(:min => 0.2, :max => 9.4) ; end

    end
  end
end

module Gorillib::Factory
  class BaseFactory
    def fake_value(opts={})
      if not @faker_warned then warn "No faker for #{self}" ; @faker_warned = true ; end
      nil
    end
  end

  def StringFactory.fake_value()         ; receive(Wukong::Faker::Helpers.fake_word) ; end
  def GuidFactory.fake_value()           ; receive(UUIDTools::UUID.random_create.to_s) ; end
  def HostnameFactory.fake_value()       ; receive(Wukong::Faker::Helpers.fake_hostname) ; end
  def IpAddressFactory.fake_value()      ; receive(Wukong::Faker::Helpers.fake_ip_addresss) ; end

  def SymbolFactory.fake_value()         ; receive(Wukong::Faker::Helpers.fake_identifier) end
  def PathnameFactory.fake_value()       ; receive(Wukong::Faker::Helpers.fake_filename) end

  def IntegerFactory.fake_value(opts={}) ; receive(Wukong::Faker::Helpers.fake_integer(opts)) ; end
  def BignumFactory.fake_value(opts={})  ; super({:min => 2**68, :max => 2**90}.merge(opts)) ; end

  def FloatFactory.fake_value(opts={})   ; receive(Wukong::Faker::Helpers.fake_float(opts)) ; end
  def ComplexFactory.fake_value()        ; receive(Kernel.rand, Kernel.rand) ; end
  def RationalFactory.fake_value()       ; receive(Kernel.rand.to_r)         ; end

  def TimeFactory.fake_value()           ; receive(Time.now) ; end

  def ExceptionFactory.fake_value()      ; Exception.constants.sample ; end
  
  def NilFactory.fake_value()            ; nil ; end
  def TrueFactory.fake_value()           ; true ; end
  def FalseFactory.fake_value()          ; false ; end
  def BooleanFactory.fake_value()        ; [true, false].sample ; end
end
