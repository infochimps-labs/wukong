# require 'spec_helper'
# require 'wukong/encoding'
#
# describe "Wukong encoding" do
#
#   it 'en/decodes to xml by default' do
#     Wukong.encode_str("&"           ).should == '&amp;'
#     Wukong.decode_str("&amp;"       ).should == '&'
#   end
#   it 'en/decodes to xml with :xml' do
#     Wukong.encode_str("&", :xml     ).should == '&amp;'
#     Wukong.decode_str("&amp;", :xml ).should == '&'
#   end
#   it 'url en/decodes with :url' do
#     Wukong.encode_str("&", :url     ).should == '%26'
#     Wukong.decode_str("%26", :url   ).should == '&'
#   end
#   { "'" => "&apos;", "\t" => "&#9;", "\n" => "&#10;", nil => '',}.each do |raw, enc|
#     it 'encodes #{raw} to #{enc}' do
#       Wukong.encode_str(raw, :xml   ).should == enc
#     end
#     it 'decodes #{enc} to #{raw}' do
#       Wukong.decode_str(enc, :xml   ).should == raw.to_s
#     end
#   end
#   ["normal_string with %punctuation should `not be molested", ""].each do |str|
#     it 'doesn\'t change #{str}' do
#       Wukong.encode_str(str, :xml   ).should == str
#     end
#   end
#
# end
