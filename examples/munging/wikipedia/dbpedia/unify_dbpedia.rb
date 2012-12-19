#!/usr/bin/env ruby
require_relative './dbpedia_common'
require 'gorillib/model/positional_fields'
require 'gorillib/string/inflections'
require 'wu/wikipedia/models'

Wu::Wikipedia::DbpediaArticle.class_eval do
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
    class PropertyBool      < Property ; field :val, :boolean ;  end
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
    class Description   < DirectProperty ; field :val,  :json_string ; end
    class Abstract      < DirectProperty ; field :val,  :json_string ; end

    class Title < DirectProperty
      field :val,           :json_string
      field :url,           :string
      field :lang,          :string
      field :revision_id,   :string
      def populate(article)
        super
        article.url         = url
        article.revision_id = revision_id
      end
    end
    class PageId        < DirectProperty
      field :val,  :integer
      field :url,           :string
      field :lang,          :string
      field :revision_id,   :string
      def populate(article)
        super
        article.url         ||= url  if url.present?
        article.revision_id ||= revision_id if revision_id.present?
      end
    end

    class GeoCoordinates < Base
      field :longitude, :float
      field :latitude,  :float
      field :quadkey,   :string
      def populate(article)
        article.longitude = longitude; article.latitude = latitude; article.quadkey = quadkey
      end
    end

    class Relation < Base
      field :rel,       :string
      field :into, :string
    end

    class Redirects < Relation
      def populate(article) ; article.redirect_ofs  |= [into] ; end
    end
    class Disambiguation < Relation
      def populate(article) ; article.disamb_ofs    |= [into] ; end
    end
    class PageLink < Relation
      def populate(article) ; article.links_into    |= [into] ; end
    end
    class Category < Relation
      def populate(article) ; article.categories    |= [into] ; end
    end

    class CategoryReln < Relation
      def populate(article) ; article.relations     |= [ ["cat-#{rel}", into] ] ; end
    end
    class InstanceOf < Base
      field :scheme, :string
      field :obj_class, :string
      def populate(article) ; article.relations     |= [ ["inst-#{scheme}", obj_class] ] ; end
    end

    class ExternalLink < Relation
      def populate(article) ; article.weblinks_into |= [ ['web', into ] ] ; end
    end
    class Homepage < Relation
      def populate(article) ; article.weblinks_into |= [ ['homepage', into] ] ; end
    end
    class Sameas < Relation
      field :stuff, Array
      def initialize(wikipedia_id, rel, into, *stuff)
        super(wikipedia_id, rel, into)
        receive_stuff(stuff)
      end
      def populate(article) ; article.relations     |= [ [rel, into, *stuff] ] ; end
    end

    class Wordnet < Base
      field :wn_reln,   :string
      field :wn_class,  :string
      field :wn_pos,    :string
      field :wn_idx,    :integer
      def populate(article) ; article.relations     |= [ [ 'wordnet', wn_reln, wn_class, wn_pos, wn_idx ] ] ; end
    end

    # class Subject < Base
    #   def populate(article) ; end
    # end

  end

  class UnifyDbpedia < Wukong::Streamer::AccumulatingReducer
    include Wu::Munging::Utils
    #
    def start!(key, *)
      super
      @article = Wu::Wikipedia::DbpediaArticle.new(wikipedia_id: key)
    end

    def accumulate(wikipedia_id, kind, *info)
      return if wikipedia_id =~ /\Abad_match-/
      return if %w[ subject ].include?(kind)
      return if (kind == 'property') && (info.first == 'prefLabel')
      item = Dbpedia::Element.make(wikipedia_id, kind, *info)
      item.populate(@article)
    rescue StandardError => err
      warn err.inspect
    end

    def finalize
      @article.namespace ||= 0
      hsh = @article.to_wire.compact_blank
      # return unless hsh.keys.size > 8

      # yield [hsh[:page_id], hsh[:namespace], hsh[:wikipedia_id], hsh[:title]]
      yield [hsh[:page_id], hsh[:namespace], hsh[:wikipedia_id], safe_json_encode(hsh, pretty: false)]
    end
  end

end

Wukong::Script.new(Wukong::Streamer::LineStreamer, Dbpedia::UnifyDbpedia,
  reduce_tasks: 15,
  partition_fields: 1, sort_fields: 1 ).run
