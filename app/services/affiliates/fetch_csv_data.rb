# frozen_string_literal: true

module Affiliates
  # Service responsible for processing S3 event data, downloading the CSV,
  # and importing affiliate records via the orchestrator.
  class FetchCsvData
    # @param data [String] JSON string from the S3 event
    def initialize(data)
      @data = data
    end

    # Main entrypoint for fetching and processing CSV data.
    # Orchestrates the import and updates the associated ImportAudit.
    #
    # @return [void]
    def call
      result = Affiliates::Import::Orchestrator.new(affiliates_data, audit: audit).call
      update_import_audit(result)
    end

    private

    attr_reader :data

    # @return [ImportAudit, nil] the audit record associated with the file path
    def audit
      @audit ||= ImportAudit.find_by(path: key)
    end

    # Updates the audit record with result statistics.
    #
    # @param result [Affiliates::Import::Result]
    # @return [void]
    def update_import_audit(result)
      return unless audit

      audit.update!(
        status: result.success? ? "processed" : "failed",
        total_successful_rows: result.created + result.updated,
        total_failed_rows: result.errors.size,
        processed_at: Time.current
      )
    end

    # Fetches and returns the CSV file from S3 as a StringIO.
    #
    # @return [StringIO] CSV content
    def affiliates_data
      response = storage_client.get_object(bucket: bucket, key: key)
      StringIO.new(response.body.read)
    end

    # Extracts the S3 object key from the event data.
    #
    # @return [String] the S3 object key
    def key
      @key ||= record.dig('s3', 'object', 'key')
    end

    # Returns the first record from the parsed S3 event payload.
    #
    # @return [Hash] parsed record
    def record
      @record ||= message['Records'].first
    end

    # Parses the raw JSON string into a Hash.
    #
    # @return [Hash] parsed event data
    def message
      @message ||= JSON.parse(data)
    rescue JSON::ParserError => error
      Rails.logger.error(message: 'Failed to parse S3 event data', error: error.message)
      {}
    end

    # @return [Aws::S3::Client]
    def storage_client
      @storage_client ||= Aws::S3::Client.new(region: region)
    end

    # @return [String] AWS region from ENV
    def region
      @region ||= ENV.fetch('AWS_REGION')
    end

    # @return [String] AWS bucket name from ENV
    def bucket
      @bucket ||= ENV.fetch('AWS_BUCKET')
    end
  end
end
