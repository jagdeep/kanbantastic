require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'net/https'

describe "Kanbanery time" do

  it "should not be set ahead" do
    FakeWeb.allow_net_connect = "https://kanbanery.com/api/v1/test.json"
    http = Net::HTTP.new('kanbanery.com', 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    path = '/api/v1/test.json'
    resp = http.start {|h| h.request(Net::HTTP::Get.new(path))}

    Time.parse(resp.header['date']).utc.should_not > Time.now.utc
  end
end