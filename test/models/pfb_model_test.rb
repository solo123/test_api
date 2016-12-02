require 'test_helper'

class PfbModelTest < ActionDispatch::IntegrationTest
  test "pfb sign" do
    key = "e1a8d02b839a46adaa9b4de5a2eb6762"

    js = {:body=>"tttt", :total_fee=>1, :spbill_create_ip=>"113.118.79.179", :time_start=>"20161125173905", :service_type=>"WECHAT_WEBPAY", :mch_id=>"C147815927610610144", :nonce_str=>"ac8b7a0bb59062a9f6c203481e661dd4", :notify_url=>"http://cb.pooulcloud.cn/notify", :trade_type=>"JSAPI", :out_trade_no=>"PL01 40", :sign=>"B86958B6BD0DA006196B7FC518835C7B"}

    mab = js.keys.sort.map{|k| "#{k}=#{js[k.to_sym]}"}.join('&')
    sign = Biz::PubEncrypt.md5(mab + key).upcase
    assert "C74559CDE3EF7D0E256DD09B7448FDDB", sign
  end
end
