# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'furotingu/version'

Gem::Specification.new do |spec|
  spec.name          = "furotingu"
  spec.version       = Furotingu::VERSION
  spec.authors       = ["Walter McGinnis"]
  spec.email         = ["walter@lytbulb.com"]
  spec.summary       = %q{Authorizes access to files kept in amazon S3 for Firebase}
  spec.description   = %q{Returns presigned_urls when url_for_upload & url_for_download are requested. Deletes S3 object for delete_object.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "sinatra", "~> 1.4"
  spec.add_dependency "sinatra-contrib", "~> 1.4"
  spec.add_dependency "puma", "~> 2.11"
  spec.add_dependency "dotenv", "~> 2.0"
  spec.add_dependency "aws-sdk", "~> 2.0"
  spec.add_dependency "firebase_token_generator", "~> 2.0"
  spec.add_dependency "httparty", "~> 0.13"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry", "~> 0.10"
  spec.add_development_dependency "shotgun", "~> 0.9.1"

  spec.add_development_dependency "rspec", "~> 3.2"
  spec.add_development_dependency "vcr", "~> 2.9"
  spec.add_development_dependency "webmock", "~> 1.21"
end
