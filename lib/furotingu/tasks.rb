task :configure_cors do
  require 'dotenv'
  Dotenv.load
  require 'aws-sdk'
  config = {
          cors_rules: [
            {
              allowed_headers: ["*"],
              allowed_methods: ["GET", "PUT"],
              allowed_origins: ["*"],
              max_age_seconds: 3000
            }
          ]
        }
  credentials = Aws::Credentials.new(ENV.fetch('AWS_ACCESS_KEY_ID'), ENV.fetch('AWS_SECRET_ACCESS_KEY'))
  s3_bucket = Aws::S3::Bucket.new(ENV.fetch('AWS_S3_BUCKET'), credentials: credentials)
  bc = s3_bucket.cors
  bc.put(cors_configuration: config)
  puts "---> cors configured"
end
