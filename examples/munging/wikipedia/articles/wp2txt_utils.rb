#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# Taken from Yoichiro Yohasebe's [`wp2txt` project](https://github.com/yohasebe/wp2txt)
# with liberal modifications for our purposes.
#
# This software is distributed under the MIT License. Please see the `./wp2txt-LICENSE.txt` file.

require 'strscan'
require 'find'
require 'sanitize'

module Wp2txt

  def format_wiki(original_text, has_retried = false)
    begin
      text = original_text + ""

      text = chrref_to_utf(text)
      text = escape_nowiki(text)

      text = process_interwiki_links(text)
      text = process_external_links(text)

      text = remove_directive(text)
      text = remove_emphasis(text)

      text = mndash(text)

      text = remove_hr(text)

      return text

      text = special_chr(text)

      unescape_nowiki(text)
    rescue # detect invalid byte sequence in UTF-8
      if has_retried
        puts "invalid byte sequence detected"
        puts "******************************"
        File.open("error_log.txt", "w") do |f|
          f.write original_text
        end
        exit
      else
        fixed_text = original_text.encode("UTF-16", :invalid => :replace, :replace => '').encode("UTF-8")
        return format_wiki(fixed_text, true)
      end
    end
  end

  #################### parser for nested structure ####################

  def process_nested_structure(scanner, left, right, &block)
    buffer = ""
    while str = scanner.scan_until(/(#{Regexp.escape(left)}|#{Regexp.escape(right)})/m)
      # begin
      case scanner[1]
      when left
        buffer << str
        has_left = true
      when right
        if has_left
          buffer = buffer[0...-(left.size)]
          contents = block.call(str[0...-(left.size)])
          buffer << contents
          break
        else
          buffer << str
        end
      end
    end
    buffer << scanner.rest

    if buffer == scanner.string
      return scanner.string
    else
      scanner.string = buffer
      return process_nested_structure(scanner, left, right, &block) || ""
    end
  end

  def remove_templates(str, only_not_inline = true)
    scanner = StringScanner.new(str)
    result = process_nested_structure(scanner, "{{", "}}") do |contents|
      # if contents.index("\n")
      #   "\n"
      # else
      #   "[tpl]#{contents}[/tpl]"
      # end
      ''
    end
  rescue SystemStackError => err
    Wukong.bad_record("Poorly nested templates", err, str)
    return str.gsub!(/{{.*}}/m, "**BAD TEMPLATE**")
  end


  #################### methods used from format_wiki ####################

  def escape_nowiki(str)
    if @nowikis
      @nowikis.clear
    else
      @nowikis = {}
    end
    str.gsub(/<nowiki>(.*?)<\/nowiki>/m) do
      nowiki = $1
      nowiki_id = nowiki.object_id
      @nowikis[nowiki_id] = nowiki
      "<nowiki nowikiid=\"#{nowiki_id}\">"
    end
  end

  def unescape_nowiki(str)
    str.gsub(/<nowiki nowikiid=\"(\d+)\">/) do
      obj_id = $1.to_i
      @nowikis[obj_id]
    end
  end

  def process_interwiki_links(str)
    scanner = StringScanner.new(str)
    result = process_nested_structure(scanner, "[[", "]]") do |contents|
      str_new = ""
      parts = contents.split("|")
      case parts.size
      when 1
        parts.first || ""
      else
        parts.shift
        parts.join("|")
      end
    end
    result
  rescue SystemStackError => err
    Wukong.bad_record("Poorly nested internal links", err, str)
    return str.gsub!(/\[\[.*\]\]/m, "**BAD INTERWIKI LINKS**")
  end

  def process_external_links(str)
    scanner = StringScanner.new(str)
    result = process_nested_structure(scanner, "[", "]") do |contents|
      parts = contents.split(" ", 2)
      case parts.size
      when 1
        parts.first || ""
      else
        parts.last || ""
      end
    end
    result
  rescue SystemStackError => err
    Wukong.bad_record("Poorly nested external links", err, str)
    return str.gsub!(/\[.*\]/m, "**BAD EXTERNAL LINKS**")
  end

  def special_chr(str)
    unless @sp_hash
      html = ['&nbsp;', '&lt;', '&gt;', '&amp;', '&quot;']\
      .zip([' ', '<', '>', '&', '"'])

      umraut_accent = ['&Agrave;', '&Aacute;', '&Acirc;', '&Atilde;', '&Auml;',
      '&Aring;', '&AElig;', '&Ccedil;', '&Egrave;', '&Eacute;', '&Ecirc;',
      '&Euml;', '&Igrave;', '&Iacute;', '&Icirc;', '&Iuml;', '&Ntilde;',
      '&Ograve;', '&Oacute;', '&Ocirc;', '&Otilde;', '&Ouml;', '&Oslash;',
      '&Ugrave;', '&Uacute;', '&Ucirc;', '&Uuml;', '&szlig;', '&agrave;',
      '&aacute;', '&acirc;', '&atilde;', '&auml;', '&aring;', '&aelig;',
      '&ccedil;', '&egrave;', '&eacute;', '&ecirc;', '&euml;', '&igrave;',
      '&iacute;', '&icirc;', '&iuml;', '&ntilde;', '&ograve;', '&oacute;',
      '&ocirc;', '&oelig;', '&otilde;', '&ouml;', '&oslash;', '&ugrave;',
      '&uacute;', '&ucirc;', '&uuml;', '&yuml;']\
      .zip(['À', 'Á', 'Â', 'Ã', 'Ä', 'Å', 'Æ', 'Ç', 'È', 'É', 'Ê', 'Ë', 'Ì', 'Í',
      'Î', 'Ï', 'Ñ', 'Ò', 'Ó', 'Ô', 'Õ', 'Ö', 'Ø', 'Ù', 'Ú', 'Û', 'Ü', 'ß', 'à',
      'á', 'â', 'ã', 'ä', 'å', 'æ', 'ç', 'è', 'é', 'ê', 'ë', 'ì', 'í', 'î', 'ï',
      'ñ', 'ò', 'ó', 'ô','œ', 'õ', 'ö', 'ø', 'ù', 'ú', 'û', 'ü', 'ÿ'])

      punctuation = ['&iquest;', '&iexcl;', '&laquo;', '&raquo;', '&sect;',
      '&para;', '&dagger;', '&Dagger;', '&bull;', '&ndash;', '&mdash;']\
      .zip(['¿', '¡', '«', '»', '§', '¶', '†', '‡', '•', '–', '—'])

      commercial = ['&trade;', '&copy;', '&reg;', '&cent;', '&euro;', '&yen;',
      '&pound;', '&curren;'].zip(['™', '©', '®', '¢', '€', '¥', '£', '¤'])

      greek_chr = ['&alpha;', '&beta;', '&gamma;', '&delta;', '&epsilon;',
      '&zeta;', '&eta;', '&theta;', '&iota;', '&kappa;', '&lambda;', '&mu;',
      '&nu;', '&xi;', '&omicron;', '&pi;', '&rho;', '&sigma;', '&sigmaf;',
      '&tau;', '&upsilon;', '&phi;', '&chi;', '&psi;', '&omega;', '&Gamma;',
      '&Delta;', '&Theta;', '&Lambda;', '&Xi;', '&Pi;', '&Sigma;', '&Phi;',
      '&Psi;', '&Omega;']\
      .zip(['α', 'β', 'γ', 'δ', 'ε', 'ζ', 'η', 'θ', 'ι', 'κ', 'λ',
      'μ', 'ν', 'ξ', 'ο', 'π', 'ρ', 'σ', 'ς', 'τ', 'υ', 'φ', 'χ',
      'ψ', 'ω', 'Γ', 'Δ', 'Θ', 'Λ', 'Ξ', 'Π', 'Σ', 'Φ', 'Ψ', 'Ω'])

      math_chr1 = ['&int;', '&sum;', '&prod;', '&radic;', '&minus;', '&plusmn;',
      '&infin;', '&asymp;', '&prop;', '&equiv;', '&ne;', '&le;', '&ge;',
      '&times;', '&middot;', '&divide;', '&part;', '&prime;', '&Prime;',
      '&nabla;', '&permil;', '&deg;', '&there4;', '&oslash;', '&isin;', '&cap;',
      '&cup;', '&sub;', '&sup;', '&sube;', '&supe;', '&not;', '&and;', '&or;',
      '&exist;', '&forall;', '&rArr;', '&hArr;', '&rarr;', '&harr;', '&uarr;']\
      .zip(['∫', '∑', '∏', '√', '−', '±', '∞', '≈', '∝', '≡', '≠', '≤',
      '≥', '×', '·', '÷', '∂', '′', '″', '∇', '‰', '°', '∴', 'ø', '∈',
      '∩', '∪', '⊂', '⊃', '⊆', '⊇', '¬', '∧', '∨', '∃', '∀', '⇒',
      '⇔', '→', '↔', '↑'])

      math_chr2 = ['&alefsym;', '&notin;'].zip(['ℵ', '∉'])

      others = ['&uml;', '&ordf;',
      '&macr;', '&acute;', '&micro;', '&cedil;', '&ordm;', '&lsquo;', '&rsquo;',
      '&ldquo;', '&sbquo;', '&rdquo;', '&bdquo;', '&spades;', '&clubs;', '&loz;',
      '&hearts;', '&larr;', '&diams;', '&lsaquo;', '&rsaquo;', '&darr;']\
      .zip(['¨', 'ª', '¯', '´', 'µ', '¸', 'º', '‘', '’', '“', '‚', '”',
      '„', '♠', '♣', '◊', '♥', '←', '♦', '‹', '›', '↓'] )

      spc_array = html + umraut_accent + punctuation + commercial + greek_chr +
                  math_chr1 + math_chr2 + others
      @sp_hash  = Hash[*spc_array.flatten]
      @sp_regex = Regexp.new("(" + @sp_hash.keys.join("|") + ")")
    end
    #str.gsub!("&amp;"){'&'}
    str.gsub!(@sp_regex) do
      @sp_hash[$1]
    end
    return str
  end

  def remove_tag(str, tagset = ['<', '>'])
    if tagset == ['<', '>']
      return remove_html_tag(str)
    end
    tagsets = Regexp.quote(tagset.uniq.join(""))
    regex = /#{Regexp.escape(tagset[0])}[^#{tagsets}]*#{Regexp.escape(tagset[1])}/
    newstr = str.gsub(regex, "")
    # newstr = newstr.gsub(/<\!\-\-.*?\-\->/, "")
    return newstr
  end

  def remove_html_tag(str)
    str = ::Sanitize.clean(str)
  end

  def clean_html(text)
    text.gsub!(%r{<(\w+)\s[^>]*?(/?)>}, '<\1\2>' )
    text = ::Sanitize.clean(text, remove_contents: ['ref'])
  end

  def remove_emphasis(str)
    str.gsub(/(''+)(.+?)\1/) do
      $2
    end
  end

  def chrref_to_utf(num_str)
    begin
      utf_str = num_str.gsub(/&#(x?)([0-9a-fA-F]+);/) do
        if $1 == 'x'
          ch = $2.to_i(16)
        else
          ch = $2.to_i
        end
        hi = ch>>8
        lo = ch&0xff
        u = "\377\376" << lo.chr << hi.chr
        u.encode("UTF-8", "UTF-16")
      end
    rescue StandardError
      return num_str
    end
    return utf_str
  end

  def remove_directive(str)
    remove_tag(str, ['__', '__'])
  end

  def mndash(str)
    str = str.gsub(/\{(mdash|ndash|–)\}/, "–")
  end

  def remove_hr(page)
    page = page.gsub(/^\s*\-+\s*$/, "")
  end

  def make_reference(str)
    str.gsub!(%r{<br ?\/>}m,             "\n")
    str.gsub!(%r{<ref[^>]*\/>}m,         '')
    str.gsub!(%r{<ref[^>]*>.*?<\/ref>}m, '')
    str
  end

  def format_ref(page)
    page = page.gsub(/\[ref\](.*?)\[\/ref\]/m) do
      ref = $1.dup
      ref.gsub(/(?:[\r\n]+|<br ?\/>)/, " ")
    end
  end

  #################### methods currently unused ####################

  def process_template(str)
    scanner = StringScanner.new(str)
    result = process_nested_structure(scanner, "{{", "}}") do |contents|
      parts = contents.split("|")
      case parts.size
      when 0
        ""
      when 1
        parts.first || ""
      else
        if parts.last.split("=").size > 1
          parts.first || ""
        else
          parts.last || ""
        end
      end
    end
    result
  rescue SystemStackError => err
    Wukong.bad_record("Poorly nested templates", err, str)
    return str.gsub!(/\[\[.*\]\]/m, "**BAD TEMPLATES**")
  end

  def remove_table(str)
    new_str = str.gsub(/\{\|[^\{\|\}]*?\|\}/m, "")
    if str != new_str
      new_str = remove_table(new_str)
    end
    new_str = remove_table(new_str) unless str == new_str
    return new_str
  end

  def remove_clade(page)
    new_page = page.gsub(/\{\{(?:C|c)lade[^\{\}]*\}\}/m, "")
    new_page = remove_clade(new_page) unless page == new_page
    new_page
  end

  def remove_inline_template(str)
    str.gsub(/\{\{(.*?)\}\}/) do
       key = $1
       if /\A[^\|]+\z/ =~ key
         result = key
       else
         info = key.split("|")
         type_code = info.first
         case type_code
         when /\Alang*/i, /\AIPA/i, /\AIEP/i, /\ASEP/i, /\Aindent/i, /\Aaudio/i, /\Asmall/i,
              /\Admoz/i, /\Apron/i, /\Aunicode/i, /\Anote label/i, /\Anowrap/i,
              /\AArabDIN/i, /\Atrans/i, /\ANihongo/i, /\APolytonic/i
           out = info[-1]
         else
           out = "{" + info.collect{|i|i.chomp}.join("|") + "}"
         end
         result = out
       end
     end
  end

  #################### file related utilities ####################

  # collect filenames recursively
  def collect_files(str, regex = nil)
    regex ||= //
    text_array = Array.new
    Find.find(str) do |f|
      text_array << f if regex =~ f
    end
    text_array.sort
  end

  # modify a file using block/yield mechanism
  def file_mod(file_path, backup = false, &block)
    File.open(file_path, "r") do |fr|
      str = fr.read
      newstr = yield(str)
      str = newstr unless newstr == nil
      File.open("temp", "w") do |tf|
        tf.write(str)
      end
    end

    File.rename(file_path, file_path + ".bak")
    File.rename("temp", file_path)
    File.unlink(file_path + ".bak") unless backup
  end

  # modify files under a directry (recursive)
  def batch_file_mod(dir_path, &block)
    if FileTest.directory?(dir_path)
      collect_files(dir_path).each do |file|
        yield file if FileTest.file?(file)
      end
    else
      yield dir_path if FileTest.file?(dir_path)
    end
  end

  # take care of difference of separators among environments
  def correct_separator(input)
    if input.is_a?(String)
      ret_str = String.new
      if RUBY_PLATFORM.index("win32")
        ret_str = input.gsub("/", "\\")
      else
        ret_str = input.gsub("\\", "/")
      end
      return ret_str
    elsif input.is_a?(Array)
      ret_array = Array.new
      input.each do |item|
        ret_array << correct_separator(item)
      end
      return ret_array
    end
  end

  def rename(files)
    # num of digits necessary to name the last file generated
    maxwidth = 0

    files.each do |f|
      width = f.slice(/\-(\d+)\z/, 1).to_s.length.to_i
      maxwidth = width if maxwidth < width
    end

    files.each do |f|
      newname= f.sub(/\-(\d+)\z/) do
        "-" + sprintf("%0#{maxwidth}d", $1.to_i)
      end
      File.rename(f, newname + ".txt")
    end
  end

  # convert int of seconds to string in the format 00:00:00
  def sec_to_str(int)
    unless int
      str = "--:--:--"
      return str
    end
    h = int / 3600
    m = (int - h * 3600) / 60
    s = int % 60
    str = sprintf("%02d:%02d:%02d", h, m, s)
    return str
  end

  def decimal_format(i)
    str = i.to_s.reverse
    return str.scan(/.?.?./).join(',').reverse
  end

end
