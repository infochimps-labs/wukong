
module Wu
  module Data
    module Wikipedia

      class Article
        include Gorillib::Model
        field :title,        String
        field :namespace,    Integer
        field :id,           Integer
        field :restrictions, String
        field :revision_id,  String
        field :timestamp,    String
        field :sha1,         String
        field :redirect,     String
        field :xml_text,     String

    end
  end
end
