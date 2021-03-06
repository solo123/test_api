require 'test_helper'
#require 'httparty'

class QueryQuickPayTest < ActionDispatch::IntegrationTest
  DEBUG_MODE = true

  def log(*params)
    return unless DEBUG_MODE
    Rails.logger.info params.join("\n")
  end

  test "支付订单查询" do
    url = "http://103.25.21.35:11111/gateway/qrcode/qrcodePay"
    notify_url = 'http://pay.pooulcloud.cn/notify/test_notify'
    order_id = 'ORD-' + Time.now.to_i.to_s + '-001'
    mch_id = "800010000020029"

    builder = Nokogiri::XML::Builder.new(:encoding => 'GBK') do |xml|
      xml.AIPG {
        xml.INFO {
          xml.TRX_CODE '100010'
          xml.VERSION '01'
          xml.REQ_SN order_id
          xml.SIGNED_MSG '[sign]'
        }
        xml.BODY {
          xml.TRANS_DETAIL {
            xml.QRCODE_CHANNEL '1'
            xml.MERCHANT_ID mch_id
            xml.MER_ORD_DT Time.now.strftime("%Y%m%d")
            xml.TX_AMT '0.01'
            xml.SUBJECT 'test order'
            xml.NOTIFY_URL notify_url
          }
        }
      }
    end
    txt = post_xml(builder, url)
    txt_no = txt.gsub(/<SIGNED_MSG>(.|\n)*<\/SIGNED_MSG>/, '<SIGNED_MSG></SIGNED_MSG>')
    rr = txt.match( /<SIGNED_MSG>((.|\n)*)<\/SIGNED_MSG>/ )
    return_key = rr[1]
    txt_no_utf = txt_no.encode('utf-8', 'gbk')
    puts "-----> 扫码支付结果：", txt_no_utf
    assert verify(txt_no_utf, return_key)
    ord_no = Nokogiri::XML::Document.parse(txt_no_utf).xpath("//ORD_NO").first.content

    #  订单查询
    query_url = 'http://103.25.21.35:11111/gateway/query/queryQuickPay'
    query_builder = Nokogiri::XML::Builder.new(:encoding => 'GBK') do |xml|
      xml.AIPG {
        xml.INFO {
          xml.TRX_CODE '100010'
          xml.VERSION '01'
          xml.REQ_SN ord_no
          xml.SIGNED_MSG '[sign]'
          xml.MERCHANT_ID mch_id
        }
        xml.BODY {
          xml.QUERY_TRANS {
            xml.MERC_ORD_NO order_id # 商户订单编号
            xml.MERCHANT_ID mch_id
            xml.QRCODE_CHANNEL '1'
            xml.MERC_ORD_DT Time.now.strftime("%Y%m%d")
          }
        }
      }
    end
    query_txt = post_xml(query_builder, query_url)
    query_txt_no = query_txt.gsub(/<SIGNED_MSG>(.|\n)*<\/SIGNED_MSG>/, '<SIGNED_MSG></SIGNED_MSG>')
    query_rr = query_txt.match /<SIGNED_MSG>((.|\n)*)<\/SIGNED_MSG>/
    query_return_key = query_rr[1]
    query_txt_no_utf = query_txt_no.encode('utf-8', 'gbk')
    puts "-----> 查询结果：", query_txt_no_utf 

  end

  test "sign test simple" do
    msg = "abc123\nABC123"
    assert verify(msg, sign1(msg))
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
