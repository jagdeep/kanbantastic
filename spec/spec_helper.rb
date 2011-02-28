require 'rspec/autorun'
require "rspec"
require 'fakeweb'
require 'vcr'
require 'kanbantastic'

FakeWeb.allow_net_connect = false

VCR.config do |c|
  c.cassette_library_dir     = 'spec/cassettes'
  c.stub_with                :fakeweb
  c.default_cassette_options = { :record => :none }
end

RSpec.configure do |config|
  config.extend VCR::RSpec::Macros
  config.mock_with :mocha
end


API_KEY = 'secret'
PROJECT_ID = 2817
WORKSPACE = 'envision'