require 'test_helper'
#require 'httparty'

class MerchantInTest < ActionDispatch::IntegrationTest
  DEBUG_MODE = true

  def log(*params)
    return unless DEBUG_MODE
    Rails.logger.info params.join("\n")
  end

  test "商户入驻" do
    return
    url = "http://103.25.21.35:11111/gateway/merchantIn/merchantIn"
    order_id = 'ORD-' + Time.now.to_i.to_s + '-001'
    mch_id = "800010000020029" # 合众主商户代码(必填)
    submerchant_code = "001" # 子商户代码(必填)
    submerchant_name = "test merchant" # 子商户全称(必填)
    submerchant_shortname = "t m" # 子商户简称(必填)
    submerchant_address = "深圳市南山区" # 子商户地址(必填)
    submerchant_servicephone = '299999999' # 子商户客服电话(必填)
    submerchant_category = '1001' # 子商户经营类目(必填)

    builder = Nokogiri::XML::Builder.new(:encoding => 'GBK') do |xml|
      xml.AIPG {
        xml.INFO {
          xml.TRX_CODE '100012'
          xml.VERSION '01'
          xml.REQ_SN order_id
          xml.SIGNED_MSG '[sign]'
        }
        xml.BODY {
          xml.TRANS_DETAIL {
            xml.IN_CHANNEL '1'
            xml.QRCODE_CHANNEL '1'
            xml.MERCHANT_ID mch_id
            xml.SUBMERCHANT_CODE submerchant_code
            xml.SUBMERCHANT_NAME submerchant_name
            xml.SUBMERCHANT_SHORTNAME submerchant_shortname
            xml.SUBMERCHANT_ADDRESS submerchant_address
            xml.SUBMERCHANT_SERVICEPHONE submerchant_servicephone
            xml.SUBMERCHANT_CATEGORY submerchant_category
          }
        }
      }
    end
    txt = post_xml(builder, url)
    txt_no = txt.gsub(/<SIGNED_MSG>(.|\n)*<\/SIGNED_MSG>/, '<SIGNED_MSG></SIGNED_MSG>')
    rr = txt.match( /<SIGNED_MSG>((.|\n)*)<\/SIGNED_MSG>/ )
    return_key = rr[1]
    txt_no_utf = txt_no.encode('utf-8', 'gbk')
    puts "-----> 商家入住信息提交结果：", txt_no_utf
    assert verify(txt_no_utf, return_key)
  end

  test "商户入驻信息修改" do
    url = "http://103.25.21.35:11111/gateway/merchantIn/merchantInModify"
    req_sn = 'merchantInModify-' + Time.now.to_i.to_s + '-100012'
    mch_id = "800010000020029" # 合众主商户代码(必填)
    submerchant_code = "001" # 子商户代码(必填)
    submerchant_name = "test merchant" # 子商户全称(必填)
    submerchant_address = "深圳市南山区" # 子商户地址(必填)
    submerchant_servicephone = '299999999' # 子商户客服电话(必填)

    builder = Nokogiri::XML::Builder.new(:encoding => 'GBK') do |xml|
      xml.AIPG {
        xml.INFO {
          xml.TRX_CODE '100013'
          xml.VERSION '01'
          xml.REQ_SN req_sn
          xml.SIGNED_MSG '[sign]'
        }
        xml.BODY {
          xml.TRANS_DETAIL {
            xml.MERCHANT_ID mch_id
            xml.SUBMERCHANT_CODE submerchant_code
            xml.IN_CHANNEL '1'
            xml.SUBMERCHANT_SHORTNAME submerchant_name
            xml.SUBMERCHANT_ADDRESS submerchant_address
            xml.SUBMERCHANT_SERVICEPHONE submerchant_servicephone
          }
        }
      }
    end
    txt = post_xml(builder, url)
    txt_no = txt.gsub(/<SIGNED_MSG>(.|\n)*<\/SIGNED_MSG>/, '<SIGNED_MSG></SIGNED_MSG>')
    rr = txt.match /<SIGNED_MSG>((.|\n)*)<\/SIGNED_MSG>/
    return_key = rr[1]
    txt_no_utf = txt_no.encode('utf-8', 'gbk')
    puts "-----> 商家入住信息修改结果：", txt_no_utf
    assert verify(txt_no_utf, return_key)
  end

  def post_xml(builder, url)
    xml_str = builder.to_xml.gsub('[sign]', '')
    xml_utf = xml_str.encode('utf-8', 'gbk')
    puts xml_utf
    sn = sign1(xml_utf)
    xml_sn = xml_str.gsub('<SIGNED_MSG></SIGNED_MSG>', "<SIGNED_MSG>#{sn}</SIGNED_MSG>")
    gzip = ActiveSupport::Gzip.compress(xml_sn)
    b64 = Base64.encode64(gzip)

    resp = HTTParty.post(url, body: b64, headers: {"Content-Type": "text/plain; charset=ISO-8859-1"})

    txt_gzip = Base64.decode64(resp.body)
    txt = ActiveSupport::Gzip.decompress(txt_gzip)
    txt.force_encoding('gbk')
    return txt
  end

  def sign(data)
    k = OpenSSL::PKCS12.new(File.read('test/hz/800010000020029.pfx'), 'password')
    sign = OpenSSL::PKCS7::sign(k.certificate, k.key, data, [], OpenSSL::PKCS7::BINARY|OpenSSL::PKCS7::DETACHED)
    v_sn = Base64.encode64(sign.to_der)
  end
  def sign1(data)
    sign = ''
    begin
      socket = TCPSocket.open('127.0.0.1', 9001)
      socket.write("HzSign\0")
      socket.write(data)
      socket.write("\0")
      sign = socket.read
    rescue => e
      puts "Error:", e.message
    end
    sign
  end
  def verify(data, p7_key)
    pkcs7 = OpenSSL::PKCS7.new(Base64.decode64(p7_key))
    pkcs7.verify(pkcs7.certificates, OpenSSL::X509::Store.new, data, OpenSSL::PKCS7::NOVERIFY)
  end

end
