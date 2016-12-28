require 'test_helper'

class PublicPayTest < ActionDispatch::IntegrationTest
  DEBUG_MODE = true

  def log(*params)
    return unless DEBUG_MODE
    Rails.logger.info params.join("\n")
  end
  def post_data(url, data)
    uri = URI(url)
    resp = Net::HTTP.post_form(uri, data)

    log "request:", uri.inspect
    log "resp type: ",  resp.inspect
    log "resp body:", resp.body
    resp
  end

  test "公众号支付" do
    url = "https://www.ulpay.com/gateway/publicNo/publicNoPay"
    notify_url = 'http://pay.pooulcloud.cn/notify/test_notify'
    callback_url = "http://pay.pooulcloud.cn/callback/test_callback"
    order_id = 'ORD-' + Time.now.to_i.to_s + '-001'
    mch_id = "800010000020029"
    key = "e1a8d02b839a46adaa9b4de5a2eb6762"

    builder = Nokogiri::XML::Builder.new(:encoding => 'GBK') do |xml|
      xml.AIPG {
        xml.mercId mch_id # 商户编号
        xml.mercOrdNo order_id # 商户订单编号
        xml.merOrdDate Time.now.strftime("%Y%m%d") # 商户订单日期
        xml.subject '公众号测试订单' # 订单标题
        xml.payChannel '1' # 支付渠道
        xml.txAmt '1' # 金额
        xml.notifyUrl notify_url #通知商户后台URL
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
            xml.MER_ORD_DT '20161224'
            xml.TX_AMT '0.01'
            xml.SUBJECT 'test order'
            xml.NOTIFY_URL notify_url
          }
        }
      }
    end
    xml_str = builder.to_xml.gsub('[sign]', '')
    xml_utf = xml_str
    sn = sign1(xml_utf)
    xml_sn = xml_str.gsub('<SIGNED_MSG></SIGNED_MSG>', "<SIGNED_MSG>#{sn}</SIGNED_MSG>")
    gzip = ActiveSupport::Gzip.compress(xml_sn)
    b64 = Base64.encode64(gzip)

    resp = HTTParty.post(url, body: b64, headers: {"Content-Type": "text/plain; charset=ISO-8859-1"})
    puts resp

    txt_gzip = Base64.decode64(resp.body)
    puts txt_gzip
    txt = ActiveSupport::Gzip.decompress(txt_gzip)
    txt.force_encoding('gbk')
    txt_no = txt.gsub(/<SIGNED_MSG>(.|\n)*<\/SIGNED_MSG>/, '<SIGNED_MSG></SIGNED_MSG>')
    rr = txt.match /<SIGNED_MSG>((.|\n)*)<\/SIGNED_MSG>/
    return_key = rr[1]
    txt_no_utf = txt_no.encode('utf-8', 'gbk')
    puts "-----> 公众号支付结果：", txt_no_utf
    assert verify(txt_no_utf, return_key)
  end

  test "sign test simple" do
    msg = "abc123\nABC123"
    assert verify(msg, sign1(msg))
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