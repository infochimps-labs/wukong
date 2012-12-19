
module Wu
  module Wikipedia

    class Article
      include Gorillib::Model
      field :page_id,         Integer
      field :namespace,       Integer
      field :wikipedia_id,    String
      field :revision_id,     Integer
      field :timestamp,       String
      #
      field :title,           String
      field :redirect,        String
      field :text,            String
    end

    class DbpediaArticle < Article
      field :longitude,      Float
      field :latitude,       Float
      field :quadkey,        String
      #
      field :url,            String
      field :description,    String
      field :abstract,       String
      #
      field :extended_props, Array, default: ->{ Array.new }
      #
      field :links_into,     Array, default: ->{ Array.new }
      field :disamb_ofs,     Array, default: ->{ Array.new }
      field :redirect_ofs,   Array, default: ->{ Array.new }
      field :weblinks_into,  Array, default: ->{ Array.new }
      field :categories,     Array, default: ->{ Array.new }
      field :relations,      Array, default: ->{ Array.new }
    end

  end
end
