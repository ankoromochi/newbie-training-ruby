require 'rspec'
require 'rack/test'
require 'rspec-html-matchers'
require 'nokogiri'

RSpec.configure do |config|
  config.include Rack::Test::Methods
end
