#!/usr/bin/env ruby
require 'rubygems'
require 'wukong/script'

class Logline < Struct.new(
  :ip, :date, :time, :http_method, :protocol, :path, :response_code, :duration, :referer, :ua, :tz)

  def page_type
    case
    when path =~ /\.(css|js)$/                  then :asset
    when path =~ /\.(png|gif|ico)$/             then :image
    when path =~ /\.(pl|s?html?|asp|jsp|cgi)$/  then :page
    else                                             :other
    end
  end

  def is_page?
    page_type == :page
  end
end

class PageFilter < Wukong::Streamer::StructStreamer
  def process visit, *args
    yield visit.ua if visit.
  end
end
Wukong.run(PageFilter)
