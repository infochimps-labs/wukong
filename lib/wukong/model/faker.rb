require 'forgery'
require 'uuidtools'

module Wukong
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
          if self.respond_to?("fake_#{field_name}")
            val = self.send("fake_#{field_name}")
          else
            faker = field.faker || Gorillib::Factory(field.type)
            val = faker.is_a?(Proc) ? faker.call(*field.faker_args) : faker.fake_value(*field.faker_args)
          end
          attrs[field_name] = val
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
        min, max = [ opts[:min]||0, opts[:max]||100 ].sort
        min + Kernel.rand(max-min)
      end
      def fake_float(opts={})
        min, max = [ opts[:min]||0.0, opts[:max]||1.0 ].sort
        min + (max * Kernel.rand)
      end

      #  A latitude unif. dist from San Diego  lat 32 lng -117 to Maine lat 44 lng -68 -- sorry non-yanks
      def fake_latitude(opts={})  ; fake_float({:min =>   32.0, :max =>  45.0}.merge(opts)) ; end
      #  A longitude unif. dist from San Diego lat 32 lng -117 to Maine lat 44 lng -68 -- sorry non-yanks
      def fake_longitude(opts={}) ; fake_float({:min => -117.0, :max => -68.0}.merge(opts)) ; end

      def fake_country_id()       ; Forgery::Internet.cctld ; end       # KLUDGE: uses tlds, not country codes
      def fake_metro_code()       ; fake_integer      ; end
      def fake_area_code()        ; fake_integer(:min => 200, :max => 987) ; end

      def fake_word()             ; Forgery::LoremIpsum.word(:random => true) ; end
      def fake_identifier()       ; fake_word.downcase.gsub(/\W/,'_').gsub(/^[^a-z]/, 'a') ; end
      def fake_sentence()         ; Forgery::LoremIpsum.sentence(:random => true) ; end
      def fake_paragraph()        ; Forgery::LoremIpsum.paragraph(:random => true) ; end

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
  def HostnameFactory.fake_value()       ; receive(Forgery::Internet.domain_name) ; end
  def IpAddressFactory.fake_value()      ; receive(Forgery::Internet.ip_v4) ; end

  def SymbolFactory.fake_value()         ; receive(Wukong::Faker::Helpers.fake_identifier) end
  def PathnameFactory.fake_value()       ; receive( File.join('/', * 3.times.map{ Wukong::Faker::Helpers.fake_identifier }) ) end

  def IntegerFactory.fake_value(opts={}) ; receive(Wukong::Faker::Helpers.fake_integer(opts)) ; end
  def BignumFactory.fake_value(opts={})  ; super({:min => 2**68, :max => 2**90}.merge(opts)) ; end

  def FloatFactory.fake_value(opts={})   ; receive(Wukong::Faker::Helpers.fake_float(opts)) ; end
  def ComplexFactory.fake_value()        ; receive(Kernel.rand, Kernel.rand) ; end
  def RationalFactory.fake_value()       ; receive(Kernel.rand.to_r)         ; end

  def TimeFactory.fake_value()           ; receive(Time.now) ; end

  def NilFactory.fake_value()            ; nil ; end
  def TrueFactory.fake_value()           ; true ; end
  def FalseFactory.fake_value()          ; false ; end
  def ExceptionFactory.fake_value()      ; Exception.constants.sample ; end

  def BooleanFactory.fake_value()        ; receive(Forgery::Basic.boolean) ; end
end

class Gorillib::Model::Field
  field :faker,      Whatever, :doc => "Factory for creating a fake value; anything responding to #fake_value()", :tester => true
  field :faker_args, Array,    :doc => "Parameters to splat in for calls to the faker factory", :default => []
end
