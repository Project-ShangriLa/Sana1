require 'aws-sdk'
require 'dotenv/load'


# https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Bucket.html

def s3_upload(bucket_name, upload_file_path, dst_filename)
  s3 = Aws::S3::Resource.new(
      region:  ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
  )

  obj = s3.bucket(bucket_name).object(dst_filename)
  obj.upload_file(upload_file_path)
end
