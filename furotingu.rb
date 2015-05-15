# coding: utf-8
require "bundler/setup"
Bundler.require(:default)
require "json"
require "aws-sdk"
Dotenv.load

# implementation notes:
# use firebase rest api
# looks like we need the token from ember, how do we get it from ember?
# consume json body w/ auth object

# paths: upload, download, delete action
# expects:
# + firebase auth object (uuid, token, provider)
# + key (path to file)
# does:
# + authorizes action w/ key path (owning path mostly, e.g. task)
# + configures aws credentials
# + for upload, checks bucket and key for existing resource at that key
# + adjusts key (increment or timestamp?) if there is a conflict
# + requests presigned_url
# returns:
# + presigned_url for put or get or deletes object
# + maybe adjusted key
# + forbidden if auth doesn't have permission

class Furotingu < Sinatra::Base
  class ParameterMissingError < StandardError
    def initialize(key)
      @key = key
    end

    def to_s
      %Q{Request did not provide "#{@key}"}
    end
  end

  error ParameterMissingError do
    halt_with_json_error 400
  end

  before do
    content_type :json
    headers 'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => ['OPTIONS', 'POST']
  end

  post "/url_for_upload" do
    @data = JSON.parse(request.body.read) rescue {}
    validate_data
    adjust_filename_if_needed
    @body = { presigned_url: presigned_upload_url,
              adjusted_filename: @data["adjusted_filename"] }
    json @body
  end

  post "/url_for_download" do
    @data = JSON.parse(request.body.read) rescue {}
    validate_data(skips: ["content_type"])
    json :presigned_url => presigned_download_url
  end

  post "/delete_object" do
    @data = JSON.parse(request.body.read) rescue {}
    validate_data(skips: ["content_type"])
    delete_object
    json ""
  end

  helpers do
    def json_error(ex, code, errors = {})
      halt(code,
           { "Content-Type" => "application/json" },
           JSON.dump({ message: ex.message }.merge(errors)))
    end

    def halt_with_json_error(code, errors = {})
      json_error env.fetch("sinatra.error"), code, errors
    end

    def validate_data(options = {})
      skips = options.fetch(:skips, [])
      expected = %w(target_path filename content_type)
      to_check = expected - skips

      raise ParameterMissingError, "target_path" unless @data.keys.any?

      to_check.each do |parameter|
        raise ParameterMissingError, parameter unless @data[parameter]
      end
    end

    def adjust_filename_if_needed
      @data["adjusted_filename"] = object.exists? ? adjusted_filename : nil
    end

    def presigned_upload_url
      @presigned_upload_url ||=
        object.presigned_url(:put,
                             :content_type => @data["content_type"],
                             :expires_in => ENV["AWS_UPLOAD_URL_EXPIRATION"].to_i)
    end

    def presigned_download_url
      @presigned_download_url ||=
        object.presigned_url(:get,
                             :expires_in => ENV["AWS_DOWNLOAD_URL_EXPIRATION"].to_i)
    end

    def delete_object
      object.delete
    end

    def s3_resource
      @s3_resource ||=
        if @s3_resource
          @s3_resource
        else
          credentials =
            Aws::Credentials.new(ENV["AWS_ACCESS_KEY_ID"],
                                 ENV["AWS_SECRET_ACCESS_KEY"])

          Aws::S3::Resource.new(credentials: credentials)
        end
    end

    def target_path
      @target_path ||= @data["target_path"][0] == "/" ? @data["target_path"][1..-1] : @data["target_path"]
    end

    def object_key
      @object_key ||= "#{target_path}#{@data["filename"]}"
    end

    def get_object
      s3_resource.bucket(ENV["AWS_S3_BUCKET"]).object(object_key)
    end

    def object
      @object ||= get_object
    end

    def reset_object_key_with(new_filename)
      @object_key = "#{target_path}#{new_filename}"
    end

    # todo - implement
    # use reset_object_key_with, etc
    def adjusted_filename
      @data["filename"]
    end
  end
end
