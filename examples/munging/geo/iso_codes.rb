require 'active_support/lazy_load_hooks'
require 'active_support/i18n'
require 'active_support/inflector/transliterate'

module Wukong

  module Data
    
    # These classes use data from the
    # [isocodes](http://pkg-isocodes.alioth.debian.org/) debian project. That
    # package provides lists of various ISO standards (e.g. country, language,
    # language scripts, and currency names) in one place, rather than repeated in
    # many programs throughout the system.
    #
    class IsoCode
      include Gorillib::Model
      include Gorillib::Model::LoadFromTsv
      include Gorillib::Model::Indexable

      class_attribute :handle,      instance_writer: false
      def self.load(filename=nil)
        filename ||= [:geo_data, 'iso_codes', "iso_3166.tsv"]
        @values = load_tsv(filename, num_fields: 4..6)
      end
    end

    #
    # ISO 3166 Country code
    #
    # Lists the 2-letter country code and "short" country name. The official ISO
    # 3166 maintenance agency is ISO. The gettext domain is
    # "iso_3166". [origin](http://www.iso.org/iso/country_codes)
    #
    class CountryCode < IsoCode
      include ActiveSupport::Inflector
      
      self.handle = :iso_3166
      index_on :alpha_2_code, :alpha_3_code, :country_numid, :name, :common_name, :official_name
      field :alpha_2_code,    String, identifier: true
      field :alpha_3_code,    String, identifier: true
      field :country_numid,   Integer, identifier: true
      field :name,            String
      field :official_name,   String, blankish: ["", nil]
      field :common_name,     String, blankish: ["", nil]

      def names
        [common_name, name, official_name].compact_blank
      end
      def self.for_any_name(val)
        for_name(val){ for_common_name(val){ for_official_name(val) } }
      end

      def to_place
        attrs = {
          name:            transliterate(names.first),
          official_name:   names.last,
          country_id:      alpha_2_code.downcase,
          alternate_names: names.join('|'),
          country_al3id:   alpha_3_code.downcase,
          country_numid:   country_numid,
        }
        Geo::Country.receive(attrs.compact_blank)
      end
    end

    class CountryCode < IsoCode
      self.handle = :iso_3166_3
      field :alpha_3_code,    String, identifier: true
      field :alpha_4_code,    String, identifier: true
      field :country_numid,   Integer, identifier: true
      field :country_names,   String
      field :comment,         String
      field :date_withdrawn,  String
    end

    #
    # ISO 3166-2 Country Subdivision (Admin 1: state, region, etc) Code
    #
    # The ISO 3166 standard includes a "Country Subdivision Code", giving a code
    # for the names of the principal administrative subdivisions of the
    # countries coded in ISO 3166. The official ISO 3166-2 maintenance agency is
    # ISO. The gettext domain is "iso_3166_2".
    # <http://www.iso.org/iso/country_codes/background_on_iso_3166/iso_3166-2.htm>
    #
    class RegionCode < IsoCode
      self.handle = :iso_3166_2
      field :region_code,     String, identifier: true
      field :country_code,    String
      field :parent_region,   String
      field :region_kind,     String
      field :name,            String
      alias_method :state_code, :region_code
    end

    #
    # ISO 639 Language Code
    #
    # This lists the 2-letter and 3-letter language codes and language
    # names. The official ISO 639 maintenance agency is the Library of
    # Congress. The gettext domain is "iso_639".
    # [origin](http://www.loc.gov/standards/iso639-2/)
    #
    class BasicLanguageCode < IsoCode
      self.handle = :iso_639
      field :iso_639_1_code,  String, identifier: true
      field :iso_639_2B_code, String, identifier: true
      field :iso_639_2T_code, String, identifier: true
      field :name,            String, identifier: true
    end

    # ISO 639-3
    #
    # This is a further development of ISO 639-2, see above. All codes of ISO
    # 639-2 are included in ISO 639-3. ISO 639-3 attempts to provide as complete
    # an enumeration of languages as possible, including living, extinct,
    # ancient, and constructed languages, whether major or minor, written or
    # unwritten. The gettext domain is "iso_639_3". The official ISO 639-3
    # maintenance agency is SIL International.
    # [origin](http://www.sil.org/iso639-3/)
    #
    class LanguageCode < BasicLanguageCode
      self.handle = :iso_639_3
      field :language_id,     String, identifier: true
      field :part1_code,      String
      field :part2_code,      String
      field :scope,           String
      field :status,          String
      field :language_kind,   String
      field :name,            String
      field :inverted_name,   String
      field :reference_name,  String
    end

    #
    # ISO 15924 Language Scripts (alphabet) names
    #
    # This lists the language scripts names. The official ISO 15924 maintenance
    # agency is the Unicode Consortium. The gettext domain is "iso_15924".
    # [origin](http://unicode.org/iso15924/)
    #
    class LanguageScriptCode < IsoCode
      self.handle = :iso_15924
      field :alpha_4_code,    String, identifier: true
      field :script_numid,    Integer, identifier: true
      field :name,            String
    end

    #
    # ISO 4217 Currency Code
    #
    # This lists the currency codes and names. The official ISO 4217 maintenance
    # agency is the British Standards Institution. The gettext domain is
    # "iso_4217".
    # [origin](http://www.bsi-global.com/en/Standards-and-Publications/Industry-Sectors/Services/BSI-Currency-Code-Service/)
    #
    class CurrencyCode < IsoCode
      self.handle = :iso_4217
      field :currency_code,   String, identifier: true
      field :currency_numid,  Integer, identifier: true
      field :name,            String
    end

    #
    # Historic Currency Code
    #
    class HistoricCurrencyCode < CurrencyCode
      self.handle = :historic_iso_4217
      field :date_withdrawn,  String
    end

  end
end
