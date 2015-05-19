# coding: utf-8
ENV["RACK_ENV"] = "test"

require 'bundler/setup'
Bundler.require(:test)

require File.expand_path(File.dirname(__FILE__) + "/../furotingu")

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.default_cassette_options = {
    match_requests_on: [:method, VCR.request_matchers.uri_without_param(:auth)]
  }
end
