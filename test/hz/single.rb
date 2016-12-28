require 'test_helper'

class CreditExtensionTest < ActionDispatch::IntegrationTest
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

  test "单笔代付" do
    url = "http://103.25.21.35:11111/gateway/single/singlePay"
    req_sn = 'singlePay' + Time.now.to_i.to_s + '100030'
    mch_id = "800010000020029" # 合众主商户代码(必填)
    builder = Nokogiri::XML::Builder.new(:encoding => 'GBK') do |xml|
      xml.AIPG {
        xml.INFO {
          xml.TRX_CODE '100030'
          xml.VERSION '01'
          xml.REQ_SN req_sn
          xml.SIGNED_MSG '[sign]'
        }
        xml.BODY {
          xml.TRANS_DETAIL {
            xml.BUSINESS_CODE '04900'
            xml.MERCHANT_ID mch_id
            xml.SEND_TIME  Time.now.strftime("%H%M%S")
            xml.SEND_DT Time.now.strftime("%Y%m%d")
            xml.ACCOUNT_TYPE '00' # 账号类型: 00银行卡，01存折，02-对公账户，03-合众易宝账户
            xml.ACCOUNT_NO '12341254124' # 账号
            xml.ACCOUNT_NAME 'xx' # 账号名: 银行卡、存折或者对公账户的所有人姓名。
            xml.AMOUNT '0.01' # 单位元，小数精确到分
          }
        }
      }
    end
    txt = post_xml(builder, url)
    txt_no = txt.gsub(/<SIGNED_MSG>(.|\n)*<\/SIGNED_MSG>/, '<SIGNED_MSG></SIGNED_MSG>')
    rr = txt.match( /<SIGNED_MSG>((.|\n)*)<\/SIGNED_MSG>/ )
    return_key = rr[1]
    txt_no_utf = txt_no.encode('utf-8', 'gbk')
    puts "-----> 单笔代付结果：", txt_no_utf
    assert verify(txt_no_utf, return_key)
  end

  test "单笔代付查询" do
    return
    url = "http://103.25.21.35:11111/gateway/single/singlePayQuery"
    req_sn = 'singlePayQuery' + Time.now.to_i.to_s + '200030'
    mch_id = "800010000020029" # 合众主商户代码(必填)
    query_sn = '123123'
    query_date = Time.now.strftime("%Y%m%d")
    builder = Nokogiri::XML::Builder.new(:encoding => 'GBK') do |xml|
      xml.AIPG {
        xml.INFO {
          xml.TRX_CODE '200030'
          xml.VERSION '01'
          xml.DATA_TYPE '0'
          xml.REQ_SN req_sn  # 请求流水号
          xml.SIGNED_MSG '[sign]'
        }
        xml.BODY {
          xml.TRANS_DETAIL {
            xml.MERCHANT_ID mch_id
            xml.QUERY_SN query_sn # 原交易流水号
            xml.QUERY_DATE query_date # 原交易日期
          }
        }
      }
    end
    txt = post_xml(builder, url)
    txt_no = txt.gsub(/<SIGNED_MSG>(.|\n)*<\/SIGNED_MSG>/, '<SIGNED_MSG></SIGNED_MSG>')
    rr = txt.match( /<SIGNED_MSG>((.|\n)*)<\/SIGNED_MSG>/ )
    return_key = rr[1]
    txt_no_utf = txt_no.encode('utf-8', 'gbk')
    puts "-----> 单笔代付查询结果：", txt_no_utf
    assert verify(txt_no_utf, return_key)
  end

  test "商户余额查询" do
    return
    url = "http://103.25.21.35:11111/gateway/qrbalance/querybBalance"
    req_sn = 'querybBalance' + Time.now.to_i.to_s + '200031'
    mch_id = "800010000020029" # 合众主商户代码(必填)
    builder = Nokogiri::XML::Builder.new(:encoding => 'GBK') do |xml|
      xml.AIPG {
        xml.INFO {
          xml.TRX_CODE '200031'
          xml.VERSION '01'
          xml.DATA_TYPE '0'
          xml.REQ_SN req_sn
          xml.SIGNED_MSG '[sign]'
        }
        xml.BODY {
          xml.TRANS_DETAIL {
            xml.MERCHANT_ID mch_id
          }
        }
      }
    end
    txt = post_xml(builder, url)
    txt_no = txt.gsub(/<SIGNED_MSG>(.|\n)*<\/SIGNED_MSG>/, '<SIGNED_MSG></SIGNED_MSG>')
    rr = txt.match( /<SIGNED_MSG>((.|\n)*)<\/SIGNED_MSG>/ )
    return_key = rr[1]
    txt_no_utf = txt_no.encode('utf-8', 'gbk')
    puts "-----> 商户余额查询结果：", txt_no_utf
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
