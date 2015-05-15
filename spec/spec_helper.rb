# coding: utf-8
ENV["RACK_ENV"] = "test"

require 'bundler/setup'
Bundler.require(:test)

require File.expand_path(File.dirname(__FILE__) + "/../furotingu")

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.treat_symbols_as_metadata_keys_with_true_values = true
end

require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
end
