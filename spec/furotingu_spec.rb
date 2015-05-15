# coding: utf-8
require "spec_helper"
require "json"

describe Furotingu do

  def app
    @app ||= Furotingu
  end

  describe "#url_for_upload" do
    describe "POST '/url_for_upload'" do
      context "when there is bad input" do
        it "should return json object with error" do
          post "/url_for_upload"
          expect(last_response.status).to eq(400)
          expect(JSON.parse(last_response.body)).to eq(errors)
        end

        def errors
          { "message" => 'Request did not provide "target_path"' }
        end
      end

      context "when there is valid input", :vcr do
        it "should return json object with presigned_url for upload" do
          post "/url_for_upload", JSON.dump(valid_body)
          expect(last_response.status).to eq(200)
          expect(JSON.parse(last_response.body)["presigned_url"])
            .to include(presigned_upload_url_stub)
        end

        def valid_body
          { firebase_authentication: {},
            firebase_authorization_path: "",
            target_path: "/tasks/1/",
            content_type: "image/gif",
            filename: "bipbapboop.gif" }
        end

        def presigned_upload_url_stub
          "/tasks/1/bipbapboop.gif?X-Amz-Algorithm=AWS4-HMAC-SHA256"
        end
      end
    end
  end

  describe "#url_for_download" do
    describe "POST '/url_for_download'" do
      context "when there is bad input" do
        it "should return json object with error" do
          post "/url_for_download"
          expect(last_response.status).to eq(400)
          expect(JSON.parse(last_response.body)).to eq(errors)
        end

        def errors
          { "message" => 'Request did not provide "target_path"' }
        end
      end

      context "when there is valid input", :vcr do
        it "should return json object with presigned_url for download" do
          post "/url_for_download", JSON.dump(valid_body)
          expect(last_response.status).to eq(200)
          expect(JSON.parse(last_response.body)["presigned_url"])
            .to include(presigned_download_url_stub)
        end

        def valid_body
          { firebase_authentication: {},
            firebase_authorization_path: "",
            target_path: "/tasks/1/",
            filename: "bipbapboop.gif" }
        end

        def presigned_download_url_stub
          "/tasks/1/bipbapboop.gif?X-Amz-Algorithm=AWS4-HMAC-SHA256"
        end
      end
    end
  end

  describe "#delete_object" do
    describe "POST '/delete_object'" do
      context "when there is bad input" do
        it "should return json object with error" do
          post "/delete_object"
          expect(last_response.status).to eq(400)
          expect(JSON.parse(last_response.body)).to eq(errors)
        end

        def errors
          { "message" => 'Request did not provide "target_path"' }
        end
      end

      context "when there is valid input", :vcr do
        it "should return 200 status" do
          post "/delete_object", JSON.dump(valid_body)
          expect(last_response.status).to eq(200)
        end

        def valid_body
          { firebase_authentication: {},
            firebase_authorization_path: "",
            target_path: "/tasks/1/",
            filename: "bipbapboop.gif" }
        end
      end
    end
  end
end