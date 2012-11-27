#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# Taken from Yoichiro Yohasebe's [`wp2txt` project](https://github.com/yohasebe/wp2txt)
# with liberal modifications for our purposes.
#
# This software is distributed under the MIT License. Please see the `./wp2txt-LICENSE.txt` file.

require 'strscan'
require_relative 'wp2txt_utils'

module Wp2txt

  # possible element type, which could be later chosen to print or not to print
  # :mw_heading
  # :mw_htable
  # :mw_quote
  # :mw_unordered
  # :mw_ordered
  # :mw_definition
  # :mw_pre
  # :mw_paragraph
  # :mw_comment
  # :mw_math
  # :mw_source
  # :mw_inputbox
  # :mw_template
  # :mw_link
  # :mw_summary
  # :mw_blank
  # :mw_redirect

  # an article contains elements, each of which is [TYPE, string]
  class Article

    include Wp2txt
    attr_accessor :elements, :title

    # class varialbes to save resource for generating regexps
    # those with a trailing number 1 represent opening tag/markup
    # those with a trailing number 2 represent closing tag/markup
    # those without a trailing number contain both opening/closing tags/markups

    @@in_template_regex = Regexp.new('^\s*\{\{[^\}]+\}\}\s*$')
    @@in_link_regex = Regexp.new('^\s*\[.*\]\s*$')

    @@in_inputbox_regex  = Regexp.new('<inputbox>.*?<\/inputbox>')
    @@in_inputbox_regex1  = Regexp.new('<inputbox>')
    @@in_inputbox_regex2  = Regexp.new('<\/inputbox>')

    @@in_source_regex  = Regexp.new('<source.*?>.*?<\/source>')
    @@in_source_regex1  = Regexp.new('<source.*?>')
    @@in_source_regex2  = Regexp.new('<\/source>')

    @@in_math_regex  = Regexp.new('<math.*?>.*?<\/math>')
    @@in_math_regex1  = Regexp.new('<math.*?>')
    @@in_math_regex2  = Regexp.new('<\/math>')

    @@in_heading_regex  = Regexp.new('^=+.*?=+$')

    @@in_html_table_regex = Regexp.new('<table.*?><\/table>')
    @@in_html_table_regex1 = Regexp.new('<table\b')
    @@in_html_table_regex2 = Regexp.new('<\/\s*table>')

    @@in_table_regex1 = Regexp.new('^\s*\{\|')
    @@in_table_regex2 = Regexp.new('^\|\}.*?$')

    @@in_unordered_regex  = Regexp.new('^\*')
    @@in_ordered_regex    = Regexp.new('^\#')
    @@in_pre_regex = Regexp.new('^ ')
    @@in_definition_regex  = Regexp.new('^[\;\:]')

    @@blank_line_regex = Regexp.new('^\s*$')

    @@redirect_regex = Regexp.new('#(?:REDIRECT|転送)\s+\[\[(.+)\]\]', Regexp::IGNORECASE)

    def initialize(text, title = "", strip_tmarker = false)
      @title = title.strip
      @strip_tmarker = strip_tmarker
      parse text
    end

    def create_element(tp, text)
      [tp, text]
    end

    def parse(source)
      self.class.remove_comments(source)
      @elements = []
      mode = nil
      open_stack  = []
      close_stack = []
      source.each_line do |line|

        case mode
        when :mw_table
          if @@in_table_regex2 =~ line
            mode = nil
          end
          @elements.last.last << line
          next
        when :mw_inputbox
          if @@in_inputbox_regex2 =~ line
            mode = nil
          end
          @elements.last.last << line
          next
        when :mw_source
          if @@in_source_regex2 =~ line
            mode = nil
          end
          @elements.last.last << line
          next
        when :mw_math
          if @@in_math_regex2 =~ line
            mode = nil
          end
          @elements.last.last << line
          next
        when :mw_htable
          if @@in_html_table_regex2 =~ line
            mode = nil
          end
          @elements.last.last << line
          next
        end

        case line
        when @@blank_line_regex
          @elements << create_element(:mw_blank, "\n")
        when @@redirect_regex
          @elements << create_element(:mw_redirect, line)
        when @@in_template_regex
          @elements << create_element(:mw_template, line)
        when @@in_heading_regex
          @elements << create_element(:mw_heading, "\n" + line + "\n")
        when @@in_inputbox_regex
          @elements << create_element(:mw_inputbox, line)
        when @@in_inputbox_regex1
          mode = :mw_inputbox
          @elements << create_element(:mw_inputbox, line)
        when @@in_source_regex
        @elements << create_element(:mw_source, line)
        when @@in_source_regex1
          mode = :mw_source
          @elements << create_element(:mw_source, line)
        when @@in_math_regex
          @elements << create_element(:mw_math, line)
        when @@in_math_regex1
          mode = :mw_math
          @elements << create_element(:mw_math, line)
        when @@in_html_table_regex
          @elements << create_element(:mw_htable, line)
        when @@in_html_table_regex1
          mode = :mw_htable
          @elements << create_element(:mw_htable, line)
        when @@in_table_regex1
          mode = :mw_table
          @elements << create_element(:mw_table, line)
        when @@in_unordered_regex
          line = line.sub(/\A[\*\#\;\:\ ]+/, "") if @strip_tmarker
          @elements << create_element(:mw_unordered, line)
        when @@in_ordered_regex
          line = line.sub(/\A[\*\#\;\:\ ]+/, "") if @strip_tmarker
          @elements << create_element(:mw_ordered, line)
        when @@in_pre_regex
          line = line.sub(/\A\^\ /, "") if @strip_tmarker
          @elements << create_element(:mw_pre, line)
        when @@in_definition_regex
          line = line.sub(/\A[\;\:\ ]+/, "") if @strip_tmarker
          @elements << create_element(:mw_definition, line)
        when @@in_link_regex
          @elements << create_element(:mw_link, line)
        else
          @elements << create_element(:mw_paragraph, line)
        end
      end
      @elements
    end

    def self.remove_comments(text)
      # remove all comment texts
      # and insert as many number of new line chars included in
      # each comment instead
      text.gsub!(/\<\!\-\-(.*?)\-\-\>/m) do |content|
        num_of_newlines = content.count("\n")
        (num_of_newlines == 0) ? "" : ("\n" * num_of_newlines)
      end
    end

    EXCLUDE_SECTIONS = {
        mw_heading:    false,
        mw_paragraph:  false,
        mw_table:      true,
        mw_pre:        false,
        mw_quote:      false,
        mw_unordered:  false,
        mw_ordered:    false,
        mw_definition: false,
        mw_redirect:   false,
        mw_template:   true,
        mw_title:      false,
      }

    def polish
      contents = []
      elements.each do |el_type, element|
        contents << "+#{el_type.to_s.upcase}+\t" if $DEBUG_MODE
        next if EXCLUDE_SECTIONS[el_type]
        #
        case el_type
        when :mw_heading            then contents << format_wiki(element)
        when :mw_paragraph          then contents << format_wiki(element)
        when :mw_table, :mw_htable  then contents << format_wiki(element)
        when :mw_pre                then contents << element
        when :mw_quote              then contents << format_wiki(element)
        when :mw_unordered          then contents << format_wiki(element)
        when :mw_ordered            then contents << format_wiki(element)
        when :mw_definition         then contents << format_wiki(element)
        when :mw_redirect           then contents << format_wiki(element) << "\n\n"
        else
          warn "Unknown section #{el_type}, content '#{element.to_s[0..200]}'"
          contents << format_wiki(element)
        end
      end
      text = contents.join

      # Extract text from <b>..</b> and so forth; remove contents of <ref>...</ref> completely
      text = clean_html(text)
      # translate some recognizable special characters
      text = special_chr(text)
      # re-hang the no-wiki segments
      unescape_nowiki(text)
      # strip out templates. Several parts per million of these will fail for
      # bad structure; I assume that means some parts per thousand will be
      # mis-estimated. C'est la UGC.
      text = remove_templates(text) if exclusions[:mw_template]

      return '' if /\A\s*\z/m =~ text
      #
      result = exclusions[:mw_title] ? "" : "# #{format_wiki(title)}\n\n"
      result << text
      result.gsub!(/\n\n\n+/m){"\n\n"}
      result << "\n"

      result
    end
  end
end
