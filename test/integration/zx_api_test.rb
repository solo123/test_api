require 'test_helper'
require "openssl"

class ZxApiTest < ActionDispatch::IntegrationTest
  DEBUG_MODE = true

  def log(*params)
    return unless DEBUG_MODE
    Rails.logger.info params.join("\n")
  end

  test 'post to zx server' do
    url = 'http://202.108.57.43:30280/'
    xml = File.read("#{Rails.root}/test/zx/zx_xml1.xml")

    uri = URI(url)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    req = Net::HTTP::Post.new(uri, initheader = {"Content-Type": "text/xml"})
    req.body = xml
    https.verify_mode = OpenSSL::SSL::VERIFY_NONE

    resp = https.start{|http| http.request(req)}
    puts "Resp: #{resp.inspect}"
  end
=begin
  test "rsa" do
    pri = OpenSSL::PKey::RSA.new(File.read("#{AppConfig.get('pooul', 'keys_path')}/pooul_rsa_private.pem"))
    sign = pri.sign("sha1", "abc中文".force_encoding("utf-8"))

    pub = OpenSSL::PKey::RSA.new(File.read("#{AppConfig.get('pooul', 'keys_path')}/test_p.pem"))
    result = pub.verify("sha1", sign, "abc中文".force_encoding("utf-8"))
    assert result, "verify #{result ? 'successful!' : 'failed!'}"
  end
  test "verify alipay sign" do
    resp = "{\"code\":\"40002\",\"msg\":\"Invalid Arguments\",\"sub_code\":\"isv.invalid-signature\",\"sub_msg\":\"\xCE\xDE\xD0\xA7\xC7\xA9\xC3\xFB\"}"
    sign = "pKAZjddvi+mJDIJnopTjVuwG3yoNc8JKW6HvjZ9v5GQ551NAhuIIJjL1cvAm6Llxxbjm9bYRNWRR0LJsXLaxYKzpymJNOZ0WcZtqcHmTaBzdII/G5boGLQaSl347pywft04Vb/0oeKBuEekqzPXQIma+iBXbK9GP0i5qghxTGHg="

    ali_rsa_public_key = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDDI6d306Q8fIfCOaTXyiUeJHkrIvYISRcc73s3vF1ZT7XN8RNPwJxo8pWaJMmvyTn9N4HQ632qJBVHf8sxHi/fEsraprwCtzvzQETrNRwVxLO5jVmRGi60j8Ue1efIlzPXV9je9mkjzOmdssymZkh2QhUrCmZYI/FCEa3/cNMW0QIDAQAB"

    assert Biz::AlipayBiz.rsa_verify?(Base64.decode64(ali_rsa_public_key), resp, sign)
  end
  test "verify pooul sign" do
    str = "abcdef123456"
    sign = Biz::AlipayBiz.rsa_sign(File.read("#{AppConfig.get('pooul', 'keys_path')}/pooul_rsa_private.pem"), str)

    ck = Biz::AlipayBiz.rsa_verify?(File.read("#{AppConfig.get('pooul', 'keys_path')}/test_p.pem"), str, sign)
    assert ck

    pub_key = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDKs8tcdYpfIdLEQoN7X3lwIxLo wIhQUl3Dt2MIDIzr7m89T8sQOk8UZi35FNOIX4fKTVhz4dVSzjogJqrbtK8jCFN9 aYhNTQsNnPR1/C19fmggxgoAwOlGYlWdv5i4dVuoHMPoAaaVNW7xQcdti/nEZ8hx vXFipPDroBji7q3I7QIDAQAB"

    ck = Biz::AlipayBiz.rsa_verify?(Base64.decode64(pub_key), str, sign)
    assert ck
  end
  test "private key in block" do
    priv_key = %{MIICXQIBAAKBgQDKs8tcdYpfIdLEQoN7X3lwIxLowIhQUl3Dt2MIDIzr7m89T8sQ
    Ok8UZi35FNOIX4fKTVhz4dVSzjogJqrbtK8jCFN9aYhNTQsNnPR1/C19fmggxgoA
    wOlGYlWdv5i4dVuoHMPoAaaVNW7xQcdti/nEZ8hxvXFipPDroBji7q3I7QIDAQAB
    AoGAJLNtDK6TgSoEmVhZqgrdV/phwBasF67yHy+jFKABG+6t4XIDGEsWamEdzc2B
    h12UnoJmk4S+NSH10EBwCxup4eEEwTnG2N/1O4lGmN+8sX+kzl4DxkcBz2SIuTFX
    ZpSPvpkv1Fua1uzuHxfkHMIQTpz4zEC0zOM6PsmNhn+pZdkCQQD7/+PvP1ZZP4a4
    pns/rztCVbqRZ6TZNevOZiN3GsbE+ZOpB861K76P1QS2AGkLVrrtbPDUA/vjj+eg
    Kb2eMyVjAkEAzeuQMHTVJlHQ4Wko5eHGkFWUyculU7MLDDsfdEZe2wG/V9oCs34b
    Nv01S0mdM4Htcm5KNdITWUfF/+1rMHcRbwJAVBjmiV46w9gGbrLoaK1i+lU/yOys
    v+xVwHCnn0TpVqzvkTZQzndFxhxR0Sc75xPPmBKGIEsgEaZhpzqm1Be/fwJBAKaE
    CsFkeMjX+FWPOCdM/8jPq9XS/ApHCnQFi1X3YdUwAI8GGJEVNOSutV4AVULFmkGi
    thf3nPXheFeQodE7N7kCQQCyMWH2tD7du+WVUwUjw7cwKnqrXHeXhIHYyR+qLyIv
    67qe0FC3zeKhG2fK2R1nF/2/ezcTBg4WoarBmNB81iS+}
    str = "abcdef123456"
    sign = Biz::AlipayBiz.rsa_sign(Base64.decode64(priv_key), str)

    ck = Biz::AlipayBiz.rsa_verify?(File.read("#{AppConfig.get('pooul', 'keys_path')}/test_p.pem"), str, sign)
    assert ck

  end
  test "pooul sign" do
    str = 'app_auth_token=201611BB381c6d470b204e85bfb4994a25aa6X22&app_id=2016101502183655&biz_content={"out_trade_no":"TST-001-001","total_amount":"1.00","subject":"POOUL product:001"}&charset=utf-8&method=alipay.trade.precreate&notify_url=http://112.74.184.236:8008/notify/test_alipay&sign_type=RSA&timestamp=2016-11-10 15:02:14&version=1.0'

    sign = "cw/qRozlWyT089gsWkcKA7FNT6X+bRQREMHooDi7IHrCijXn3oYDw6qN3VtqiNvFEPbf6jcT2YRD/uV0dV3TIgmTuvFvN1mm4vmrqQyE1WJ6OKn8SykqBS1YUZ5cN1tKuRl/I037043ayEVn/XoUsK/zZMThNlHBvJJAHprZHK0="

    pub_key = 'MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDKs8tcdYpfIdLEQoN7X3lwIxLo wIhQUl3Dt2MIDIzr7m89T8sQOk8UZi35FNOIX4fKTVhz4dVSzjogJqrbtK8jCFN9 aYhNTQsNnPR1/C19fmggxgoAwOlGYlWdv5i4dVuoHMPoAaaVNW7xQcdti/nEZ8hx vXFipPDroBji7q3I7QIDAQAB'

    ck = Biz::AlipayBiz.rsa_verify?(Base64.decode64(pub_key), str, sign)
    assert ck
  end
  test "test prepay sandbox" do
    #url = 'https://openapi.alipay.com/gateway.do'
    url = 'https://openapi.alipaydev.com/gateway.do'
    #app_id = '2016101502183655'
    app_id = '2016072900117068'
    n = rand(1000).to_s
    js_biz = {
      out_trade_no: 'TST-' + n,
      total_amount: '1.00',
      subject: 'POOUL product:' + n
    }
    js_request = {
      app_id: app_id,
      method: 'alipay.trade.precreate',
      sign_type: 'RSA',
      charset: 'UTF-8',
      timestamp: Time.now.to_s[0..18],
      version: '1.0',
      notify_url: 'http://112.74.184.236:8008/notify/test_alipay',
      #app_auth_token: '201611BB381c6d470b204e85bfb4994a25aa6X22',
      biz_content: js_biz.to_json
    }

    log "request params: ", js_request
    mab = Biz::AlipayBiz.get_mab(js_request)
    log "mab: ", mab

    sign = Biz::AlipayBiz.rsa_sign(File.read("#{AppConfig.get('pooul', 'keys_path')}/pooul_rsa_private.pem"), mab)
    log "sign: ", sign
    js_request[:sign] = sign

    pd = post_data(url, js_request)
    assert pd

    js_ret = Biz::PublicTools.parse_json(pd)
    assert js_ret
    log "js_ret:", js_ret.inspect

    assert_equal "10000", js_ret[:alipay_trade_precreate_response]['code']

    #post_data(url, js_request)
  end


  test "test prepay" do
    return
    url = 'https://openapi.alipay.com/gateway.do'
    app_id = '2016101502183655'
    n = rand(1000).to_s
    js_biz = {
      out_trade_no: 'TST-' + n,
      total_amount: '1.00',
      subject: 'POOUL product:' + n
    }
    js_request = {
      app_id: app_id,
      method: 'alipay.trade.precreate',
      sign_type: 'RSA',
      charset: 'UTF-8',
      timestamp: Time.now.to_s[0..18],
      version: '1.0',
      notify_url: 'http://112.74.184.236:8008/notify/test_alipay',
      app_auth_token: '201611BB381c6d470b204e85bfb4994a25aa6X22',
      biz_content: js_biz.to_json
    }

    log "request params: ", js_request
    mab = Biz::AlipayBiz.get_mab(js_request)
    log "mab: ", mab

    sign = Biz::AlipayBiz.rsa_sign(File.read("#{AppConfig.get('pooul', 'keys_path')}/pooul_rsa_private.pem"), mab)
    log "sign: ", sign
    js_request[:sign] = sign

    pd = post_data(url, js_request)
    assert pd

    js_ret = Biz::PublicTools.parse_json(pd)
    assert js_ret
    log "js_ret:", js_ret.inspect

    assert_equal "10000", js_ret[:alipay_trade_precreate_response]['code']

    #post_data(url, js_request)
  end
  test "test prepay params log" do
    url = 'https://openapi.alipay.com/gateway.do'
    app_id = '2016101502183655'
    n = rand(1000).to_s
    js_biz = {
      out_trade_no: 'TST-' + n,
      total_amount: '1.00',
      subject: 'POOUL product:' + n,
      sub_merchant: {
        merchant_id: '16392481404'
      }
    }
    js_request = {
      app_id: app_id,
      method: 'alipay.trade.precreate',
      sign_type: 'RSA',
      charset: 'UTF-8',
      timestamp: Time.now.to_s[0..18],
      version: '1.0',
      notify_url: 'http://112.74.184.236:8008/notify/test_alipay',
      app_auth_token: '201611BB381c6d470b204e85bfb4994a25aa6X22',
      biz_content: js_biz.to_json
    }

    log "request params: ", js_request
    mab = Biz::AlipayBiz.get_mab(js_request)
    log "mab: ", mab

    sign = Biz::AlipayBiz.rsa_sign(File.read("#{AppConfig.get('pooul', 'keys_path')}/pooul_rsa_private.pem"), mab)
    log "sign: ", sign
    js_request[:sign] = sign

    pd = post_data(url, js_request)
    assert pd

    js_ret = Biz::PublicTools.parse_json(pd)
    assert js_ret
    log "js_ret:", js_ret.inspect

    assert_equal "10000", js_ret[:alipay_trade_precreate_response]['code']

    #post_data(url, js_request)
  end
=end

  def post_xml(url, data)
    uri = URI(url)

    request = Net::HTTP::Post.new(uri.path)
    request.body = data
    request['Content-Type'] = 'text/xml;charset=gbk'
    response = Net::HTTP.start(uri.host, uri.port) {|http|
      http.request(request)
    }
    response
  end

end
