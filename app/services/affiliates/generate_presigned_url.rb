# frozen_string_literal: true

# Service responsible for generating a presigned S3 upload URL
# and creating a corresponding ImportAudit record.
#
# @return [Hash] Contains the presigned upload URL and object key
module Affiliates
  class GeneratePresignedUrl
    # @param filename [String] The name of the file being uploaded
    # @param content_type [String, nil] The MIME type of the file
    def initialize(filename:, content_type:)
      @filename = filename
      @content_type = content_type.presence || "application/octet-stream"
    end

    # Generates a presigned S3 URL and creates an ImportAudit record.
    #
    # @return [Hash] The direct_upload data and the generated S3 object key
    def call
      create_import_audit
      {
        direct_upload: {
          url: generate_presigned_url,
          headers: { "Content-Type" => content_type }
        },
        key: object_key
      }
    end

    private

    attr_reader :filename, :content_type

    # Creates an ImportAudit record for tracking the CSV import.
    #
    # @return [ImportAudit] the newly created record
    def create_import_audit
      ImportAudit.create!(
        path: object_key,
        filename: filename,
        status: "pending",
        import_type: 'affiliate'
      )
    end

    # Generates the actual presigned S3 URL.
    #
    # @return [String] The URL for uploading the file to S3
    def generate_presigned_url
      s3_object.presigned_url(
        :put,
        expires_in: 10.minutes.to_i,
        content_type: content_type
      )
    end

    # Returns an instance of the S3 object for the generated key.
    #
    # @return [Aws::S3::Object] The S3 object representing the upload destination
    def s3_object
      Aws::S3::Resource.new(region: aws_region)
                       .bucket(aws_bucket)
                       .object(object_key)
    end

    # Generates a unique key for the uploaded file.
    #
    # @return [String] The S3 object key
    def object_key
      @object_key ||= "csv_uploads/#{SecureRandom.uuid}/#{filename}"
    end

    # Reads the AWS region from environment variables.
    #
    # @return [String] AWS region
    def aws_region
      ENV.fetch("AWS_REGION")
    end

    # Reads the AWS bucket name from environment variables.
    #
    # @return [String] AWS bucket name
    def aws_bucket
      ENV.fetch("AWS_BUCKET")
    end
  end
end
