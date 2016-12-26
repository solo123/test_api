require 'test_helper'

class TempTest < ActionDispatch::IntegrationTest
  test "xml gen" do
    ss = []
    builder = Nokogiri::XML::Builder.new(:encoding => 'GBK') do |xml|
      xml.ROOT {
        xml.a
        ss << 'a'
        eval "add_node(xml, ss)"
        xml.b
        ss << 'b'
      }
    end
    puts builder.to_xml
    puts ss.join(', ')
  end
  def add_node(xml, ss)
    xml.cc
    xml.dd
    ss << 'cc'
    ss << 'dd'
  end
end
