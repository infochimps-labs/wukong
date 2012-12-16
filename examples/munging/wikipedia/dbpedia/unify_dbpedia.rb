#!/usr/bin/env ruby
require_relative './dbpedia_common'
require 'gorillib/model/positional_fields'
require 'gorillib/string/inflections'

class DbpediaArticle
  include Gorillib::Model
  field :page_id,         :integer
  field :wikipedia_id,    :string
  field :namespace,       :integer
  field :title,           :string
  field :lang,            :string
  field :revision_id,     :integer
  field :longitude,       :float
  field :latitude,        :float
  field :quadkey,         :string
  field :url,             :string
  field :description,     :string
  field :abstract,        :string
  #
  field :extended_props,  :array, default: ->{ Array.new }
  #
  field :links_into,      :array, default: ->{ Array.new }
  field :links_from,      :array, default: ->{ Array.new }
  field :disamb_ofs,      :array, default: ->{ Array.new }
  field :redirect_ofs,    :array, default: ->{ Array.new }
  field :weblinks_into,   :array, default: ->{ Array.new }
  field :homepage,        :string
  field :sameas,          :hash,  default: ->{ Hash.new }
  field :categories,      :array, default: ->{ Array.new }
  field :relations,       :array, default: ->{ Array.new }

  def write_attribute(attr, *args)
    warn [attr] if not self.class.field_names.include?(attr.to_sym)
    super
  end
end

module Dbpedia

  module ::Gorillib::Factory
    class JsonStringFactory < StringFactory
      register_factory!(:json_string)
      def receive(obj)
        val = super(obj)
        return val unless native?(val)
        MultiJson.decode('['+val+']').first
      end
    end
  end

  module Element
    ELEMENTS = {}

    class Base
      include Gorillib::Model
      include Gorillib::Model::PositionalFields
      class_attribute :kind
      field :wikipedia_id, :string

      def self.inherited(base)
        super
        base.kind = base.name.underscore.gsub(%r{.*/}, '')
        Dbpedia::Element::ELEMENTS[base.kind] = base
      end

    end
    def self.make(wikipedia_id, kind, *vals)
      klass = ELEMENTS[kind] or raise(ArgumentError, "Can't find class for #{kind.inspect}")
      klass.new(wikipedia_id, *vals)
    end

    class Property < Base
      field :prop_name,    :symbol
      field :datatype,     :symbol
      def populate(article)
        article.extended_props |= [ [prop_name, val, datatype].compact_blank ]
      end
    end
    class PropertyInteger   < Property ; field :val, :integer ;  end
    class PropertyBoolean   < Property ; field :val, :boolean ;  end
    class PropertyFloat     < Property ; field :val, :float   ;  end
    class PropertyDate      < Property ; field :val, :string  ;  end
    class PropertyYear      < Property ; field :val, :string  ;  end
    class PropertyYearmonth < Property ; field :val, :string  ;  end
    class PropertyMonthday  < Property ; field :val, :string  ;  end
    class PropertyString    < Property ; field :val, :json_string ; end

    class DirectProperty < Base
      def populate(article)
        article.write_attribute(kind, val)
      end
    end
    class Title < DirectProperty
      field :val,           :json_string
      field :url,           :string
      field :lang,          :string
      field :revision_id,   :string
      def populate(article)
        super
        article.url         = url
        article.lang        = lang
        article.revision_id = revision_id
      end
    end
    class PageId        < DirectProperty ; field :val,  :integer ; end
    class Description   < DirectProperty ; field :val,  :json_string ; end
    class Abstract      < DirectProperty ; field :val,  :json_string ; end

    class GeoCoordinates < Base
      field :longitude, :float
      field :latitude,  :float
      field :quadkey,   :string
      def populate(article)
        article.longitude = longitude; article.latitude = latitude; article.quadkey = quadkey
      end
    end

    # class Wordnet
    # end
    class Relation < Base
      field :rel,       :string
      field :into_wpid, :string
    end
    class CategoryReln < Relation
      def populate(article) ; article.relations |= [{ rel: rel, into: into_wpid }] ; end
    end
    class Category < Relation
      def populate(article) ; article.categories |= ["wp-#{into_wpid}"] ; end
    end
    class InstanceOf < Base
      field :scheme, :string
      field :obj_class, :string
      def populate(article) ; article.categories |= ["#{scheme}-#{obj_class}"] ; end
    end

    class Redirects < Relation
      def populate(article) ; article.redirect_ofs |= [into_wpid] ; end
    end
    class Disambiguation < Relation
      def populate(article) ; article.disamb_ofs   |= [into_wpid] ; end
    end
    class PageLink < Relation
      def populate(article) ; article.links_into |= [into_wpid] ; end
    end



    class Weblink < Base
      field :rel,      :string
      field :into_url, :string
    end

    class ExternalLink < Weblink
      def populate(article) ; article.weblinks_into |= [into_url] ; end
    end
    class Homepage < Weblink
      def populate(article) ; article.homepage = [into_url] ; end
    end

  end

  class UnifyDbpedia < Wukong::Streamer::AccumulatingReducer
    include Wu::Munging::Utils
    #
    def start!(key, *)
      super
      @article = DbpediaArticle.new(wikipedia_id: key)
    end

    def accumulate(wikipedia_id, kind, *info)
      return if %w[disambiguation homepage abstract description ].include?(kind)
      item = Dbpedia::Element.make(wikipedia_id, kind, *info)
      item.populate(@article)
    rescue StandardError => err
      warn err.inspect
    end

    def finalize
      hsh = @article.to_wire.compact_blank
      return unless hsh.keys.size > 8
      yield [safe_json_encode(hsh, pretty: true)]
    end
  end

end

Wukong::Script.new(Dbpedia::UnifyDbpedia, nil).run
