require 'test_helper'

class PublicPayTest < ActionDispatch::IntegrationTest
  DEBUG_MODE = true

  def log(*params)
    return unless DEBUG_MODE
    Rails.logger.info params.join("\n")
  end

  test "公众号支付" do
    url = "https://www.ulpay.com/gateway/publicNo/publicNoPay"
    notify_url = 'http://pay.pooulcloud.cn/notify/test_notify'
    callback_url = "http://pay.pooulcloud.cn/callback/test_callback"
    order_id = Time.now.to_i.to_s
    mch_id = "800010000020029"

    params = {
        'mercId': mch_id, # 商户编号
        'mercOrdNo': order_id, # 商户订单编号
        'merOrdDate': Time.now.strftime("%Y%m%d"), # 商户订单日期
        'subject': '公众号测试订单', # 订单标题
        'payChannel': '1', # 支付渠道
        'txAmt': '1', # 金额
        'notifyUrl': notify_url #通知商户后台URL
    }
    @sign_str = ''
    ['mercId','mercOrdNo','merOrdDate','txAmt','payChannel','notifyUrl'].each do |str_key|
      puts "#{str_key} = #{params[str_key.to_sym]}"
      @sign_str += "#{params[str_key.to_sym]}"
    end
    puts "=======签名文明：#{@sign_str}"
    sn = sign1(@sign_str)
    puts "=======签名后数据：#{sn}"
    params['merchantSign'] = sn
    puts params

    resp = HTTParty.post(url, body: params)
    puts resp

    return
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
