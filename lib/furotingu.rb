require "bundler/setup"
Bundler.require(:default)
require "furotingu/version"
require "sinatra"
require "puma"
require "dotenv"
require "firebase_token_generator"
require "httparty"
require "sinatra/json"
require "aws-sdk"
require "net/http"

env_file = ENV["RACK_ENV"] ? ".env.#{ENV["RACK_ENV"]}" : ".env.development"

Dotenv.load('.env', env_file)

module Furotingu
  class App < Sinatra::Base
    class ParameterMissingError < StandardError
      def initialize(key)
        @key = key
      end

      def to_s
        %Q{Request did not provide "#{@key}"}
      end
    end

    class Unauthorized < StandardError
      def to_s
        %Q{You do not have appropriate access for this operation}
      end
    end

    class InsecureConnection < StandardError
      def to_s
        %Q{This service is only available over https}
      end
    end

    error ParameterMissingError do
      halt_with_json_error 400
    end

    error Unauthorized do
      halt_with_json_error 401
    end

    error InsecureConnection do
      halt_with_json_error 401
    end

    before do
      if settings.environment == :production && !request.secure?
        raise InsecureConnection
      end
    end

    before do
      content_type :json
      headers "Access-Control-Allow-Origin" => "*",
              "Access-Control-Allow-Methods" => ["OPTIONS", "POST"]
    end

    post "/url_for_upload" do
      @data = JSON.parse(request.body.read) rescue {}

      validate_data
      authenticate
      authorize

      json presigned_upload
    end

    post "/url_for_download" do
      @data = JSON.parse(request.body.read) rescue {}

      validate_data(skips: ["content_type"])
      authenticate
      authorize

      json :presigned_url => presigned_download_url
    end

    post "/delete_object" do
      @data = JSON.parse(request.body.read) rescue {}

      validate_data(skips: ["content_type"])
      authenticate
      authorize

      delete_object
      json ""
    end

    helpers do
      def json_error(ex, code, errors = {})
        halt(code,
             { "Content-Type" => "application/json",
               "Access-Control-Allow-Origin" => "*",
               "Access-Control-Allow-Methods" => ["OPTIONS", "POST"] },
             JSON.dump({ message: ex.message }.merge(errors)))
      end

      def halt_with_json_error(code, errors = {})
        json_error env.fetch("sinatra.error"), code, errors
      end

      def validate_data(options = {})
        skips = options.fetch(:skips, [])
        expected = %w(fire target_path filename content_type)
        to_check = expected - skips

        raise ParameterMissingError, "target_path" unless @data.keys.any?

        to_check.each do |parameter|
          raise ParameterMissingError, parameter unless @data[parameter]
        end
      end

      def authenticate
        payload = { uid: @data["fire"] }
        generator = Firebase::FirebaseTokenGenerator.new(ENV.fetch("FIREBASE_SECRET"))
        @token = generator.create_token(payload)
      end

      def firebase_target_url
        path = target_path
        path = path.chop if path[-1] == "/"
        "#{ENV.fetch("FIREBASE_URL")}#{path}.json?shallow=true&auth=#{@token}"
      end

      def authorize
        response = HTTParty.get(firebase_target_url)
        raise Unauthorized unless response.code == 200
      end

      def presigned_upload
        @presigned_upload ||=
          begin
            post = object.presigned_post(:content_type => @data["content_type"],
                                         :content_disposition => "attachment;",
                                         :allow_any => ["name"],
                                         :success_action_status => "201")
            { :presigned_url => post.url, :aws_fields => post.fields }
          end
      end

      def presigned_download_url
        @presigned_download_url ||=
          object.presigned_url(:get,
                               :expires_in => ENV.fetch("AWS_DOWNLOAD_URL_EXPIRATION").to_i)
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
              Aws::Credentials.new(ENV.fetch("AWS_ACCESS_KEY_ID"),
                                   ENV.fetch("AWS_SECRET_ACCESS_KEY"))

            Aws::S3::Resource.new(credentials: credentials)
          end
      end

      def target_path
        @target_path ||= @data["target_path"][0] == "/" ? @data["target_path"][1..-1] : @data["target_path"]
      end

      def object_key
        @object_key ||= "#{target_path}#{@data["filename"]}"
      end

      def object
        @object ||= s3_resource.bucket(ENV.fetch("AWS_S3_BUCKET")).object(object_key)
      end
    end
  end
end
