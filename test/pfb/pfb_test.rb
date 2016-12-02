require 'test_helper'

class PfbTest < ActionDispatch::IntegrationTest
  DEBUG_MODE = true
  def log(*params)
    return unless DEBUG_MODE
    Rails.logger.info params.join("\n")
  end

  test "post to Pufubao valid" do
    return
    url = "http://brcb.pufubao.net/gateway"
    notify_url = 'http://cb.pooulcloud.cn/notify/test_reqeust'
    callback_url = "http://cb.pooulcloud.cn/notify/test_reqeust_cb"
    order_id = 'ORD-' + Time.now.to_i.to_s + '-001'
    mch_id = "C147937578318610572"
    key = "e1a8d02b839a46adaa9b4de5a2eb6762"
    js = {
      service_type: 'WECHAT_WEBPAY',
      mch_id: mch_id,
      nonce_str: 'abcd',
      body: 'test1',
      out_trade_no: order_id,
      total_fee: '1',
      spbill_create_ip: '127.0.0.1',
      notify_url: 'http://cb.pooulcloud.cn/notify/pufubao_test',
      trade_type: 'JSAPI'
    }

    mab = js.keys.sort.map{|k| "#{k}=#{js[k.to_sym]}"}.join('&')
    sign = Biz::PubEncrypt.md5(mab + key).upcase
    #js[:input_charset] = 'UTF-8'
    js[:sign] = sign

    pd = post_data(url, js)
    assert pd
    assert pd.is_a?(Net::HTTPRedirection)

    log "redirect: ", pd['location']
  end
  test "a pay" do
    #return
    url = "http://brcb.pufubao.net/gateway"
    key = "e1a8d02b839a46adaa9b4de5a2eb6762"
    order_id = 'ORD-' + Time.now.to_i.to_s + '-001'
    mch_id = "C147937578318610572"
=begin
{ , :service_type=>"WECHAT_WEBPAY", :mch_id=>"C147815927610610144", :nonce_str=>"0d619a91a8dd967e41f9dbe187e3766f", :notify_url=>"http://cb.pooulcloud.cn/notify", :trade_type=>"JSAPI", :out_trade_no=>"PL010000000010", :sign=>"BB229C37E52FEE3624B00496D222ADAD"}

=end
    js = {
      service_type: 'WECHAT_WEBPAY',
      mch_id: "C147937578318610572",
      nonce_str: 'abcd',
      body: 'tt1',
      out_trade_no: order_id,
      total_fee: 2,
      spbill_create_ip: '::1',
      time_start: "20161126150603",
      notify_url: 'http://cb.pooulcloud.cn/notify/pufubao_test',
      trade_type: 'JSAPI'
    }

    mab = js.keys.sort.map{|k| "#{k}=#{js[k.to_sym].to_s}"}.join('&')
    sign = Biz::PubEncrypt.md5(mab.force_encoding('utf-8') + key).upcase
    #js[:input_charset] = 'UTF-8'
    #assert_equal "B86958B6BD0DA006196B7FC518835C7B", sign
    js[:sign] = sign
    puts js
    pd = post_data(url, js)
    assert pd
    puts "-----> resp.body:"
    puts pd.body
    puts pd.inspect
  end


  def post_data(url, data)
    uri = URI(url)
    resp = Net::HTTP.post_form(uri, data)

    log "request:", uri.inspect
    log "resp type: ",  resp.inspect
    log "resp body:", resp.body
    resp
  end

end
